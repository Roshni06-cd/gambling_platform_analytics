--getting all 7 schemas in one query--
SELECT
  table_name,
  ordinal_position,
  column_name,
  data_type,
  is_nullable
FROM
  `online-gambling-analytics.gambling_analytics.INFORMATION_SCHEMA.COLUMNS`
ORDER BY
  table_name,
  ordinal_position;




  --data quality checks(missing values)--
  SELECT
  'bets' AS table_name,
  COUNT(*) AS total_rows,
  COUNTIF(stake_amount IS NULL) AS missing_stakes,
  COUNTIF(stake_amount < 0) AS negative_stakes,
  COUNTIF(payout_amount IS NULL) AS missing_payouts,
  COUNTIF(payout_amount < 0) AS negative_payouts,
  COUNTIF(decimal_odds <= 1) AS odds_at_or_below_one
FROM `online-gambling-analytics.gambling_analytics.bets`

UNION ALL

SELECT
  'transactions',
  COUNT(*),
  COUNTIF(amount IS NULL),
  COUNTIF(amount < 0),
  COUNTIF(amount = 0),
  COUNTIF(amount = 0),
  COUNTIF(amount < 0)
FROM `online-gambling-analytics.gambling_analytics.transactions`;




SELECT
  column_name,
  data_type
FROM
  `online-gambling-analytics.gambling_analytics.INFORMATION_SCHEMA.COLUMNS`
WHERE
  table_name = 'transactions'
ORDER BY
  ordinal_position;



  SELECT
  COUNT(*) AS total_rows,
  COUNTIF(payment_method IS NULL) AS missing_payment_method,
  COUNTIF(TRIM(payment_method) = '') AS blank_payment_method,
  COUNTIF(payment_method IS NOT NULL
          AND TRIM(payment_method) != '') AS populated_payment_method
FROM `online-gambling-analytics.gambling_analytics.transactions`;




-- Check for duplicate IDs in each table
SELECT 'players' AS table_name,
       COUNT(*) - COUNT(DISTINCT player_id) AS duplicate_ids
FROM `online-gambling-analytics.gambling_analytics.players`

UNION ALL

SELECT 'bets',
       COUNT(*) - COUNT(DISTINCT bet_id)
FROM `online-gambling-analytics.gambling_analytics.bets`

UNION ALL

SELECT 'transactions',
       COUNT(*) - COUNT(DISTINCT transaction_id)
FROM `online-gambling-analytics.gambling_analytics.transactions`

UNION ALL

SELECT 'sessions',
       COUNT(*) - COUNT(DISTINCT session_id)
FROM `online-gambling-analytics.gambling_analytics.sessions`

UNION ALL

SELECT 'bonuses',
       COUNT(*) - COUNT(DISTINCT bonus_id)
FROM `online-gambling-analytics.gambling_analytics.bonuses`

UNION ALL

SELECT 'events',
       COUNT(*) - COUNT(DISTINCT event_id)
FROM `online-gambling-analytics.gambling_analytics.events`

UNION ALL

SELECT 'campaigns',
       COUNT(*) - COUNT(DISTINCT campaign_id)
FROM `online-gambling-analytics.gambling_analytics.campaigns`

ORDER BY table_name;


-- Check duplicate and missing IDs
SELECT
  'bets' AS table_name,
  COUNTIF(bet_id IS NULL) AS missing_ids,
  COUNT(*) - COUNT(DISTINCT bet_id)
    - COUNTIF(bet_id IS NULL) AS repeated_id_rows
FROM `online-gambling-analytics.gambling_analytics.bets`

UNION ALL

SELECT
  'transactions',
  COUNTIF(transaction_id IS NULL),
  COUNT(*) - COUNT(DISTINCT transaction_id)
    - COUNTIF(transaction_id IS NULL)
FROM `online-gambling-analytics.gambling_analytics.transactions`;



--checking if the repeated IDs have identical record 
SELECT *
FROM `online-gambling-analytics.gambling_analytics.bets`
WHERE bet_id IN (
  SELECT bet_id
  FROM `online-gambling-analytics.gambling_analytics.bets`
  GROUP BY bet_id
  HAVING COUNT(*) > 1
)
ORDER BY bet_id, bet_time;


SELECT *
FROM `online-gambling-analytics.gambling_analytics.transactions`
WHERE transaction_id IN (
  SELECT transaction_id
  FROM `online-gambling-analytics.gambling_analytics.transactions`
  GROUP BY transaction_id
  HAVING COUNT(*) > 1
)
ORDER BY transaction_id, transaction_time;


--verifying the full extent of duplication
WITH duplicate_groups AS (
  SELECT bet_id AS record_id, COUNT(*) AS row_count
  FROM `online-gambling-analytics.gambling_analytics.bets`
  GROUP BY bet_id
  HAVING COUNT(*) > 1
)
SELECT
  COUNT(*) AS repeated_id_groups,
  SUM(row_count) AS rows_in_repeated_groups,
  SUM(row_count - 1) AS excess_rows,
  COUNTIF(row_count > 2) AS groups_with_more_than_two_rows
FROM duplicate_groups;



WITH duplicate_groups AS (
  SELECT transaction_id AS record_id, COUNT(*) AS row_count
  FROM `online-gambling-analytics.gambling_analytics.transactions`
  GROUP BY transaction_id
  HAVING COUNT(*) > 1
)
SELECT
  COUNT(*) AS repeated_id_groups,
  SUM(row_count) AS rows_in_repeated_groups,
  SUM(row_count - 1) AS excess_rows,
  COUNTIF(row_count > 2) AS groups_with_more_than_two_rows
FROM duplicate_groups;


--verifying exact duplicate records
WITH repeated AS (
  SELECT *
  FROM `online-gambling-analytics.gambling_analytics.bets`
  QUALIFY COUNT(*) OVER (PARTITION BY bet_id) > 1
),
distinct_records AS (
  SELECT DISTINCT *
  FROM repeated
)
SELECT
  (SELECT COUNT(*) FROM repeated) AS repeated_rows,
  (SELECT COUNT(*) FROM distinct_records) AS distinct_full_rows;



WITH repeated AS (
  SELECT *
  FROM `online-gambling-analytics.gambling_analytics.transactions`
  QUALIFY COUNT(*) OVER (PARTITION BY transaction_id) > 1
),
distinct_records AS (
  SELECT DISTINCT *
  FROM repeated
)
SELECT
  (SELECT COUNT(*) FROM repeated) AS repeated_rows,
  (SELECT COUNT(*) FROM distinct_records) AS distinct_full_rows;



--cleaning bets table
CREATE OR REPLACE TABLE
  `online-gambling-analytics.gambling_analytics.bets_clean` AS
SELECT DISTINCT *
FROM `online-gambling-analytics.gambling_analytics.bets`;



--cleaning transactions table
CREATE OR REPLACE TABLE
  `online-gambling-analytics.gambling_analytics.transactions_clean` AS
SELECT DISTINCT *
FROM `online-gambling-analytics.gambling_analytics.transactions`;


--validating the cleaned tables
SELECT
  'bets_raw' AS table_name, COUNT(*) AS row_count
FROM `online-gambling-analytics.gambling_analytics.bets`

UNION ALL

SELECT 'bets_clean', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.bets_clean`

UNION ALL

SELECT 'transactions_raw', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.transactions`

UNION ALL

SELECT 'transactions_clean', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.transactions_clean`;


--checking missing values across all 7 tables's columns
SELECT
  'bets_clean' AS table_name,
  COUNT(*) AS total_rows,
  COUNTIF(bet_id IS NULL) AS missing_id,
  COUNTIF(player_id IS NULL) AS missing_player_id,
  COUNTIF(event_id IS NULL) AS missing_event_id,
  COUNTIF(bet_time IS NULL) AS missing_timestamp,
  COUNTIF(stake_amount IS NULL) AS missing_amount,
  COUNTIF(decimal_odds IS NULL) AS missing_odds,
  COUNTIF(result IS NULL) AS missing_result
FROM `online-gambling-analytics.gambling_analytics.bets_clean`

UNION ALL

SELECT
  'transactions_clean',
  COUNT(*),
  COUNTIF(transaction_id IS NULL),
  COUNTIF(player_id IS NULL),
  0,
  COUNTIF(transaction_time IS NULL),
  COUNTIF(amount IS NULL),
  0,
  COUNTIF(status IS NULL)
FROM `online-gambling-analytics.gambling_analytics.transactions_clean`;

-- Full missing-value check across all seven tables
-- Uses cleaned tables where duplicates have already been removed.

SELECT 'players' AS table_name, column_name, missing_count
FROM (
  SELECT
    COUNTIF(player_id IS NULL) AS player_id,
    COUNTIF(registration_date IS NULL) AS registration_date,
    COUNTIF(age_band IS NULL) AS age_band,
    COUNTIF(country IS NULL) AS country,
    COUNTIF(acquisition_channel IS NULL) AS acquisition_channel,
    COUNTIF(device_preference IS NULL) AS device_preference,
    COUNTIF(account_status IS NULL) AS account_status
  FROM `online-gambling-analytics.gambling_analytics.players`
)
UNPIVOT (missing_count FOR column_name IN (
  player_id, registration_date, age_band, country,
  acquisition_channel, device_preference, account_status
))

UNION ALL

SELECT 'bets_clean', column_name, missing_count
FROM (
  SELECT
    COUNTIF(bet_id IS NULL) AS bet_id,
    COUNTIF(player_id IS NULL) AS player_id,
    COUNTIF(event_id IS NULL) AS event_id,
    COUNTIF(bet_time IS NULL) AS bet_time,
    COUNTIF(sport IS NULL) AS sport,
    COUNTIF(bet_type IS NULL) AS bet_type,
    COUNTIF(stake_amount IS NULL) AS stake_amount,
    COUNTIF(decimal_odds IS NULL) AS decimal_odds,
    COUNTIF(result IS NULL) AS result,
    COUNTIF(payout_amount IS NULL) AS payout_amount,
    COUNTIF(bonus_used IS NULL) AS bonus_used
  FROM `online-gambling-analytics.gambling_analytics.bets_clean`
)
UNPIVOT (missing_count FOR column_name IN (
  bet_id, player_id, event_id, bet_time, sport, bet_type,
  stake_amount, decimal_odds, result, payout_amount, bonus_used
))

UNION ALL

SELECT 'events', column_name, missing_count
FROM (
  SELECT
    COUNTIF(event_id IS NULL) AS event_id,
    COUNTIF(sport IS NULL) AS sport,
    COUNTIF(league IS NULL) AS league,
    COUNTIF(event_date IS NULL) AS event_date,
    COUNTIF(home_team IS NULL) AS home_team,
    COUNTIF(away_team IS NULL) AS away_team,
    COUNTIF(event_status IS NULL) AS event_status
  FROM `online-gambling-analytics.gambling_analytics.events`
)
UNPIVOT (missing_count FOR column_name IN (
  event_id, sport, league, event_date, home_team, away_team, event_status
))

UNION ALL

SELECT 'transactions_clean', column_name, missing_count
FROM (
  SELECT
    COUNTIF(transaction_id IS NULL) AS transaction_id,
    COUNTIF(player_id IS NULL) AS player_id,
    COUNTIF(transaction_time IS NULL) AS transaction_time,
    COUNTIF(transaction_type IS NULL) AS transaction_type,
    COUNTIF(amount IS NULL) AS amount,
    COUNTIF(currency IS NULL) AS currency,
    COUNTIF(status IS NULL) AS status,
    COUNTIF(payment_method IS NULL) AS payment_method
  FROM `online-gambling-analytics.gambling_analytics.transactions_clean`
)
UNPIVOT (missing_count FOR column_name IN (
  transaction_id, player_id, transaction_time, transaction_type,
  amount, currency, status, payment_method
))

UNION ALL

SELECT 'sessions', column_name, missing_count
FROM (
  SELECT
    COUNTIF(session_id IS NULL) AS session_id,
    COUNTIF(player_id IS NULL) AS player_id,
    COUNTIF(session_start IS NULL) AS session_start,
    COUNTIF(session_duration_minutes IS NULL) AS session_duration_minutes,
    COUNTIF(device IS NULL) AS device,
    COUNTIF(game_category IS NULL) AS game_category,
    COUNTIF(bets_placed IS NULL) AS bets_placed
  FROM `online-gambling-analytics.gambling_analytics.sessions`
)
UNPIVOT (missing_count FOR column_name IN (
  session_id, player_id, session_start, session_duration_minutes,
  device, game_category, bets_placed
))

UNION ALL

SELECT 'bonuses', column_name, missing_count
FROM (
  SELECT
    COUNTIF(bonus_id IS NULL) AS bonus_id,
    COUNTIF(player_id IS NULL) AS player_id,
    COUNTIF(campaign_id IS NULL) AS campaign_id,
    COUNTIF(issued_at IS NULL) AS issued_at,
    COUNTIF(bonus_amount IS NULL) AS bonus_amount,
    COUNTIF(redeemed IS NULL) AS redeemed
  FROM `online-gambling-analytics.gambling_analytics.bonuses`
)
UNPIVOT (missing_count FOR column_name IN (
  bonus_id, player_id, campaign_id, issued_at, bonus_amount, redeemed
))

UNION ALL

SELECT 'campaigns', column_name, missing_count
FROM (
  SELECT
    COUNTIF(campaign_id IS NULL) AS campaign_id,
    COUNTIF(campaign_name IS NULL) AS campaign_name,
    COUNTIF(campaign_type IS NULL) AS campaign_type,
    COUNTIF(start_date IS NULL) AS start_date,
    COUNTIF(end_date IS NULL) AS end_date,
    COUNTIF(campaign_cost_budget IS NULL) AS campaign_cost_budget
  FROM `online-gambling-analytics.gambling_analytics.campaigns`
)
UNPIVOT (missing_count FOR column_name IN (
  campaign_id, campaign_name, campaign_type,
  start_date, end_date, campaign_cost_budget
))

ORDER BY missing_count DESC, table_name, column_name;




-- Examine the missing-stake records
SELECT
  bet_id,
  player_id,
  bet_time,
  sport,
  bet_type,
  decimal_odds,
  result,
  payout_amount,
  bonus_used
FROM `online-gambling-analytics.gambling_analytics.bets_clean`
WHERE stake_amount IS NULL
LIMIT 50;




SELECT
  sport,
  bet_type,
  result,
  bonus_used,
  COUNT(*) AS missing_stake_records
FROM `online-gambling-analytics.gambling_analytics.bets_clean`
WHERE stake_amount IS NULL
GROUP BY sport, bet_type, result, bonus_used
ORDER BY missing_stake_records DESC;


--checking the missing payment_methods
SELECT
  transaction_type,
  status,
  currency,
  COUNT(*) AS missing_method_records
FROM `online-gambling-analytics.gambling_analytics.transactions_clean`
WHERE payment_method IS NULL
GROUP BY transaction_type, status, currency
ORDER BY missing_method_records DESC;




-- Numeric and date quality checks

SELECT 'bets_clean' AS table_name,
       'Negative stake_amount' AS issue,
       COUNTIF(stake_amount < 0) AS issue_count
FROM `online-gambling-analytics.gambling_analytics.bets_clean`

UNION ALL
SELECT 'bets_clean', 'Negative payout_amount',
       COUNTIF(payout_amount < 0)
FROM `online-gambling-analytics.gambling_analytics.bets_clean`

UNION ALL
SELECT 'bets_clean', 'decimal_odds <= 1',
       COUNTIF(decimal_odds <= 1)
FROM `online-gambling-analytics.gambling_analytics.bets_clean`

UNION ALL
SELECT 'bonuses', 'Negative bonus_amount',
       COUNTIF(bonus_amount < 0)
FROM `online-gambling-analytics.gambling_analytics.bonuses`

UNION ALL
SELECT 'campaigns', 'Negative campaign budget',
       COUNTIF(campaign_cost_budget < 0)
FROM `online-gambling-analytics.gambling_analytics.campaigns`

UNION ALL
SELECT 'campaigns', 'End date before start date',
       COUNTIF(end_date < start_date)
FROM `online-gambling-analytics.gambling_analytics.campaigns`

UNION ALL
SELECT 'sessions', 'Negative session duration',
       COUNTIF(session_duration_minutes < 0)
FROM `online-gambling-analytics.gambling_analytics.sessions`

UNION ALL
SELECT 'sessions', 'Negative bets_placed',
       COUNTIF(bets_placed < 0)
FROM `online-gambling-analytics.gambling_analytics.sessions`

UNION ALL
SELECT 'transactions_clean', 'Negative transaction amount - review',
       COUNTIF(amount < 0)
FROM `online-gambling-analytics.gambling_analytics.transactions_clean`

ORDER BY table_name, issue;





-- Inspect categories and their frequencies

SELECT 'bets.result' AS field, result AS category, COUNT(*) AS row_count
FROM `online-gambling-analytics.gambling_analytics.bets_clean`
GROUP BY result

UNION ALL
SELECT 'bets.bet_type', bet_type, COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.bets_clean`
GROUP BY bet_type

UNION ALL
SELECT 'bets.sport', sport, COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.bets_clean`
GROUP BY sport

UNION ALL
SELECT 'transactions.transaction_type', transaction_type, COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.transactions_clean`
GROUP BY transaction_type

UNION ALL
SELECT 'transactions.status', status, COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.transactions_clean`
GROUP BY status

UNION ALL
SELECT 'players.account_status', account_status, COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.players`
GROUP BY account_status

UNION ALL
SELECT 'players.acquisition_channel', acquisition_channel, COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.players`
GROUP BY acquisition_channel

UNION ALL
SELECT 'events.event_status', event_status, COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.events`
GROUP BY event_status

ORDER BY field, category;





-- Find unmatched foreign keys

SELECT 'bets -> players' AS relationship, COUNT(*) AS unmatched_rows
FROM `online-gambling-analytics.gambling_analytics.bets_clean` b
LEFT JOIN `online-gambling-analytics.gambling_analytics.players` p
  ON b.player_id = p.player_id
WHERE p.player_id IS NULL

UNION ALL

SELECT 'bets -> events', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.bets_clean` b
LEFT JOIN `online-gambling-analytics.gambling_analytics.events` e
  ON b.event_id = e.event_id
WHERE e.event_id IS NULL

UNION ALL

SELECT 'transactions -> players', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.transactions_clean` t
LEFT JOIN `online-gambling-analytics.gambling_analytics.players` p
  ON t.player_id = p.player_id
WHERE p.player_id IS NULL

UNION ALL

SELECT 'sessions -> players', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.sessions` s
LEFT JOIN `online-gambling-analytics.gambling_analytics.players` p
  ON s.player_id = p.player_id
WHERE p.player_id IS NULL

UNION ALL

SELECT 'bonuses -> players', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.bonuses` b
LEFT JOIN `online-gambling-analytics.gambling_analytics.players` p
  ON b.player_id = p.player_id
WHERE p.player_id IS NULL

UNION ALL

SELECT 'bonuses -> campaigns', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.bonuses` b
LEFT JOIN `online-gambling-analytics.gambling_analytics.campaigns` c
  ON b.campaign_id = c.campaign_id
WHERE c.campaign_id IS NULL

ORDER BY relationship;



--standardizing transactions
CREATE OR REPLACE TABLE
  `online-gambling-analytics.gambling_analytics.transactions_standardized` AS

SELECT * REPLACE (
  CASE
    WHEN UPPER(TRIM(status)) = 'APPROVED' THEN 'Approved'
    WHEN UPPER(TRIM(status)) = 'DECLINED' THEN 'Declined'
    WHEN UPPER(TRIM(status)) = 'PENDING' THEN 'Pending'
    ELSE TRIM(status)
  END AS status
)
FROM `online-gambling-analytics.gambling_analytics.transactions_clean`;



--validating the results
SELECT status, COUNT(*) AS row_count
FROM `online-gambling-analytics.gambling_analytics.transactions_standardized`
GROUP BY status
ORDER BY status;


--checking ID uniqueness across all seven tables

SELECT 'players' AS table_name,
       COUNT(*) AS total_rows,
       COUNT(DISTINCT player_id) AS unique_ids,
       COUNTIF(player_id IS NULL) AS null_ids
FROM `online-gambling-analytics.gambling_analytics.players`

UNION ALL
SELECT 'bets_clean', COUNT(*), COUNT(DISTINCT bet_id),
       COUNTIF(bet_id IS NULL)
FROM `online-gambling-analytics.gambling_analytics.bets_clean`

UNION ALL
SELECT 'events', COUNT(*), COUNT(DISTINCT event_id),
       COUNTIF(event_id IS NULL)
FROM `online-gambling-analytics.gambling_analytics.events`

UNION ALL
SELECT 'transactions_standardized', COUNT(*),
       COUNT(DISTINCT transaction_id),
       COUNTIF(transaction_id IS NULL)
FROM `online-gambling-analytics.gambling_analytics.transactions_standardized`

UNION ALL
SELECT 'sessions', COUNT(*), COUNT(DISTINCT session_id),
       COUNTIF(session_id IS NULL)
FROM `online-gambling-analytics.gambling_analytics.sessions`

UNION ALL
SELECT 'bonuses', COUNT(*), COUNT(DISTINCT bonus_id),
       COUNTIF(bonus_id IS NULL)
FROM `online-gambling-analytics.gambling_analytics.bonuses`

UNION ALL
SELECT 'campaigns', COUNT(*), COUNT(DISTINCT campaign_id),
       COUNTIF(campaign_id IS NULL)
FROM `online-gambling-analytics.gambling_analytics.campaigns`

ORDER BY table_name;






-- Profile categorical values across the cleaned dataset.
-- NULL and blank values are shown explicitly.


SELECT 'players.age_band' AS field,
       COALESCE(NULLIF(TRIM(age_band), ''), '<BLANK>') AS category,
       COUNT(*) AS row_count
FROM `online-gambling-analytics.gambling_analytics.players`
GROUP BY 2

UNION ALL
SELECT 'players.country',
       COALESCE(NULLIF(TRIM(country), ''), '<BLANK>'),
       COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.players`
GROUP BY 2

UNION ALL
SELECT 'players.device_preference',
       COALESCE(NULLIF(TRIM(device_preference), ''), '<BLANK>'),
       COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.players`
GROUP BY 2

UNION ALL
SELECT 'sessions.device',
       COALESCE(NULLIF(TRIM(device), ''), '<BLANK>'),
       COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.sessions`
GROUP BY 2

UNION ALL
SELECT 'sessions.game_category',
       COALESCE(NULLIF(TRIM(game_category), ''), '<BLANK>'),
       COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.sessions`
GROUP BY 2

UNION ALL
SELECT 'transactions.currency',
       COALESCE(NULLIF(TRIM(currency), ''), '<BLANK>'),
       COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.transactions_standardized`
GROUP BY 2

UNION ALL
SELECT 'transactions.payment_method',
       COALESCE(NULLIF(TRIM(payment_method), ''), '<BLANK>'),
       COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.transactions_standardized`
GROUP BY 2

UNION ALL
SELECT 'bonuses.redeemed',
       COALESCE(CAST(redeemed AS STRING), '<NULL>'),
       COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.bonuses`
GROUP BY 2

UNION ALL
SELECT 'campaigns.campaign_type',
       COALESCE(NULLIF(TRIM(campaign_type), ''), '<BLANK>'),
       COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.campaigns`
GROUP BY 2

UNION ALL
SELECT 'events.league',
       COALESCE(NULLIF(TRIM(league), ''), '<BLANK>'),
       COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.events`
GROUP BY 2

UNION ALL
SELECT 'events.sport',
       COALESCE(NULLIF(TRIM(sport), ''), '<BLANK>'),
       COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.events`
GROUP BY 2

ORDER BY field, category;
