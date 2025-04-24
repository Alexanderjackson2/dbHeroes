START TRANSACTION;

-- Step 1: Ensure currencies are inserted (no nulls, no duplicates)
INSERT INTO api.currencies (code)
SELECT DISTINCT code
FROM (
  SELECT raw_data.raw_json ->> 'source' AS code
  FROM exchange_rates raw_data
  WHERE raw_data.raw_json ->> 'source' IS NOT NULL

  UNION

  SELECT SUBSTRING(pair.key FROM 4) AS code
  FROM exchange_rates raw_data
  JOIN LATERAL jsonb_each_text(raw_data.raw_json::jsonb -> 'quotes') AS pair ON TRUE
  WHERE SUBSTRING(pair.key FROM 4) IS NOT NULL
) AS currency_codes
WHERE code IS NOT NULL
ON CONFLICT (code) DO NOTHING;

-- Step 2: Ensure exchange pairs exist
INSERT INTO api.exchange_pairs (source_currency, target_currency)
SELECT DISTINCT
  raw_data.raw_json ->> 'source' AS source_currency,
  SUBSTRING(pair.key FROM 4) AS target_currency
FROM exchange_rates raw_data
JOIN LATERAL jsonb_each_text(raw_data.raw_json::jsonb -> 'quotes') AS pair ON TRUE
WHERE raw_data.raw_json ->> 'source' IS NOT NULL
  AND SUBSTRING(pair.key FROM 4) IS NOT NULL
ON CONFLICT (source_currency, target_currency) DO NOTHING;

-- Step 3: Insert cleaned exchange rate records (no duplicates)
INSERT INTO api.clean_currency_rates_3nf (
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
WHERE raw_data.raw_json ->> 'source' IS NOT NULL
  AND SUBSTRING(pair.key FROM 4) IS NOT NULL
  AND pair.value IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM api.clean_currency_rates_3nf c
    WHERE c.exchange_pair_id = ep.id
      AND c.quote_timestamp = raw_data.last_updated
      AND c.exchange_rate = pair.value::NUMERIC
      AND c.raw_source_id = raw_data.id
);
COMMIT;
