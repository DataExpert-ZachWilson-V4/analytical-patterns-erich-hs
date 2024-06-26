-- Which player scored the most points playing for a single team?
-- Answering using GROUPING SETS as requested in the assignment

-- Deduplicating the `nba_game_details` table because there are duplicates in the source table!
WITH nba_game_details_deduped AS (
  SELECT
    game_id,
    team_id,
    team_abbreviation,
    player_id,
    player_name,
    pts,
    ROW_NUMBER() OVER (PARTITION BY game_id, team_id, player_id ORDER BY pts DESC) AS row_num
  FROM bootcamp.nba_game_details
),
-- Combining with `nba_games` to retrieve the season 
combined AS (
  SELECT
    gd.game_id,
    gd.team_abbreviation,
    gd.player_name,
    gd.pts,
    g.season
  FROM nba_game_details_deduped gd
    JOIN bootcamp.nba_games g ON gd.game_id = g.game_id AND gd.team_id = g.home_team_id
  WHERE
    gd.row_num = 1
),
olap_cube AS (
  SELECT
    COALESCE(CAST(team_abbreviation AS VARCHAR), '(overall)') AS team,
    COALESCE(CAST(player_name AS VARCHAR), '(overall)') AS player,
    COALESCE(CAST(season AS VARCHAR), '(overall)') AS season,
    SUM(pts) AS sum_pts
  FROM combined
  GROUP BY GROUPING SETS (
    (player_name, team_abbreviation),
    (player_name, season),
    (team_abbreviation)
  )
)
SELECT
  *
FROM
  olap_cube
WHERE
  player <> '(overall)'
  AND team <> '(overall)'
ORDER BY
  sum_pts DESC
LIMIT 1