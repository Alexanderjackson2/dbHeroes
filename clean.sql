START TRANSACTION;
-- Insert new or changed data from raw_heroes
INSERT INTO clean_heroes (name, role, pick_rate, win_rate, game_mode, platform, raw_source_id)
SELECT 
  (r.raw_json ->> 'name')::TEXT AS name,
  (r.raw_json ->> 'role')::TEXT AS role,
  (r.raw_json ->> 'pickRate')::NUMERIC AS pick_rate,
  (r.raw_json ->> 'winRate')::NUMERIC AS win_rate,
  (r.raw_json ->> 'gameMode')::TEXT AS game_mode,
  'pc' AS platform,
  r.id
FROM heroes r
WHERE NOT EXISTS (
  SELECT 1
  FROM clean_heroes c
  WHERE c.name = (r.raw_json ->> 'name')::TEXT
    AND c.role = (r.raw_json ->> 'role')::TEXT
    AND c.pick_rate = (r.raw_json ->> 'pickRate')::NUMERIC
    AND c.win_rate = (r.raw_json ->> 'winRate')::NUMERIC
    AND c.game_mode = (r.raw_json ->> 'gameMode')::TEXT
    AND c.platform = 'pc'
)
AND (r.raw_json ->> 'name') IS NOT NULL
AND (r.raw_json ->> 'pickRate') ~ '^[0-9.]+$'
AND (r.raw_json ->> 'winRate') ~ '^[0-9.]+$';
COMMIT;
