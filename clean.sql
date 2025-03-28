START TRANSACTION;
START TRANSACTION;
-- Define all game modes you want to process
WITH all_modes AS (
  SELECT h.id AS raw_source_id, 'quickPlay' AS mode, jsonb_array_elements(h.raw_json -> 'quickPlay') AS hero
  FROM heroes h
  UNION ALL
  SELECT h.id, 'competitiveSummary', jsonb_array_elements(h.raw_json -> 'competitiveSummary') FROM heroes h
  UNION ALL
  SELECT h.id, 'competitiveGold', jsonb_array_elements(h.raw_json -> 'competitiveGold') FROM heroes h
  UNION ALL
  SELECT h.id, 'competitiveSilver', jsonb_array_elements(h.raw_json -> 'competitiveSilver') FROM heroes h
  UNION ALL
  SELECT h.id, 'competitiveBronze', jsonb_array_elements(h.raw_json -> 'competitiveBronze') FROM heroes h
  UNION ALL
  SELECT h.id, 'competitivePlatinum', jsonb_array_elements(h.raw_json -> 'competitivePlatinum') FROM heroes h
  UNION ALL
  SELECT h.id, 'competitiveDiamond', jsonb_array_elements(h.raw_json -> 'competitiveDiamond') FROM heroes h
  UNION ALL
  SELECT h.id, 'competitiveGrandmaster', jsonb_array_elements(h.raw_json -> 'competitiveGrandmaster') FROM heroes h
  UNION ALL
  SELECT h.id, 'competitiveCelestialAndAbove', jsonb_array_elements(h.raw_json -> 'competitiveCelestialAndAbove') FROM heroes h
)

-- Insert if not already present
INSERT INTO clean_heroes (
  name, role, pick_rate, win_rate, game_mode, platform, raw_source_id
)
SELECT
  hero.value ->> 'name' AS name,
  hero.value ->> 'role' AS role,
  REPLACE(hero.value ->> 'pickRate', '%', '')::NUMERIC AS pick_rate,
  REPLACE(hero.value ->> 'winRate', '%', '')::NUMERIC AS win_rate,
  mode AS game_mode,
  'pc' AS platform,
  raw_source_id
FROM all_modes
WHERE NOT EXISTS (
  SELECT 1 FROM clean_heroes c
  WHERE c.name = hero.value ->> 'name'
    AND c.role = hero.value ->> 'role'
    AND c.pick_rate = REPLACE(hero.value ->> 'pickRate', '%', '')::NUMERIC
    AND c.win_rate = REPLACE(hero.value ->> 'winRate', '%', '')::NUMERIC
    AND c.game_mode = mode
    AND c.platform = 'pc'
);

COMMIT;
