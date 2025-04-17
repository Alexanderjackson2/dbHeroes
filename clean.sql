START TRANSACTION;

-- Step 1: Insert all distinct currencies
INSERT INTO currencies (code)
SELECT DISTINCT raw_data.raw_json ->> 'source'
FROM exchange_rates raw_data
UNION
SELECT DISTINCT SUBSTRING(pair.key FROM 4)
FROM exchange_rates raw_data,
     LATERAL jsonb_each_text(raw_data.raw_json::jsonb -> 'quotes') AS pair
WHERE pair.key LIKE 'USD%'  -- Assuming USD as base

ON CONFLICT DO NOTHING;

-- Step 2: Insert exchange pairs
INSERT INTO exchange_pairs (source_currency, target_currency)
SELECT DISTINCT
  raw_data.raw_json ->> 'source' AS source_currency,
  SUBSTRING(pair.key FROM 4) AS target_currency
FROM exchange_rates raw_data
JOIN LATERAL jsonb_each_text(raw_data.raw_json::jsonb -> 'quotes') AS pair ON TRUE
WHERE pair.key LIKE 'USD%'

ON CONFLICT DO NOTHING;

-- Step 3: Insert normalized exchange rate data
INSERT INTO clean_currency_rates (
  exchange_pair_id, quote_timestamp, exchange_rate, raw_source_id
)
SELECT
  ep.id,
  raw_data.last_updated,
  pair.value::NUMERIC,
  raw_data.id
FROM exchange_rates raw_data
JOIN LATERAL jsonb_each_text(raw_data.raw_json::jsonb -> 'quotes') AS pair ON TRUE
JOIN exchange_pairs ep
  ON ep.source_currency = raw_data.raw_json ->> 'source'
  AND ep.target_currency = SUBSTRING(pair.key FROM 4)
WHERE NOT EXISTS (
  SELECT 1 FROM clean_currency_rates c
  WHERE c.exchange_pair_id = ep.id
    AND c.quote_timestamp = raw_data.last_updated
    AND c.exchange_rate = pair.value::NUMERIC
    AND c.raw_source_id = raw_data.id
);

COMMIT;

