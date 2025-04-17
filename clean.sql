START TRANSACTION;

-- Normalize quotes into clean_currency_rates
INSERT INTO clean_currency_rates (
  currency_code, exchange_rate, source_currency, quote_timestamp, raw_source_id
)
SELECT
  -- Trim "USD" from "USDAED" to get "AED"
  SUBSTRING(pair.key FROM 4) AS currency_code,
  pair.value::NUMERIC AS exchange_rate,
  raw_data.raw_json ->> 'source' AS source_currency,
  raw_data.timestamp,
  raw_data.id AS raw_source_id
FROM raw_currency_data AS raw_data
-- Explode the "quotes" JSON object into key-value pairs
JOIN LATERAL jsonb_each_text(raw_data.raw_json::jsonb -> 'quotes') AS pair(key, value) ON TRUE
WHERE NOT EXISTS (
  SELECT 1 FROM clean_currency_rates c
  WHERE c.currency_code = SUBSTRING(pair.key FROM 4)
    AND c.exchange_rate = pair.value::NUMERIC
    AND c.source_currency = raw_data.raw_json ->> 'source'
    AND c.quote_timestamp = raw_data.timestamp
    AND c.raw_source_id = raw_data.id
);

COMMIT;
