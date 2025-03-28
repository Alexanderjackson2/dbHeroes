START TRANSACTION;
-- Insert new rows from the quickPlay array
INSERT INTO clean_heroes (
  name, role, pick_rate, win_rate, game_mode, platform, raw_source_id
)
SELECT
  hero.value ->> 'name' AS name,
  hero.value ->> 'role' AS role,
  REPLACE(hero.value ->> 'pickRate', '%', '')::NUMERIC AS pick_rate,
  REPLACE(hero.value ->> 'winRate', '%', '')::NUMERIC AS win_rate,
  'quickPlay' AS game_mode,
  'pc' AS platform,
  h.id AS raw_source_id
FROM heroes h,
  jsonb_array_elements(h.raw_json -> 'quickPlay') AS hero(value)
WHERE NOT EXISTS (
  SELECT 1 FROM clean_heroes c
  WHERE c.name = hero.value ->> 'name'
    AND c.role = hero.value ->> 'role'
    AND c.pick_rate = REPLACE(hero.value ->> 'pickRate', '%', '')::NUMERIC
    AND c.win_rate = REPLACE(hero.value ->> 'winRate', '%', '')::NUMERIC
    AND c.game_mode = 'quickPlay'
    AND c.platform = 'pc'
);

COMMIT;
