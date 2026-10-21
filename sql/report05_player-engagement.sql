--PLAYER ENGAGEMENT
--How many players are active?
--Which countries have the most registered players?
--Which acquisition channels bring in players?
--Which players place bets frequently?


SELECT
  p.country,
  p.acquisition_channel,
  p.device_preference,
  p.account_status,
  COUNT(DISTINCT p.player_id) AS registered_players,
  COUNT(DISTINCT b.player_id) AS players_who_bet
FROM `online-gambling-analytics.gambling_analytics.players` p
LEFT JOIN `online-gambling-analytics.gambling_analytics.bets_clean` b
  ON p.player_id = b.player_id
GROUP BY
  p.country,
  p.acquisition_channel,
  p.device_preference,
  p.account_status
ORDER BY registered_players DESC;


--compare acquisition channels

WITH player_activity AS (
  SELECT
    p.player_id,
    p.acquisition_channel,
    p.account_status,
    COUNT(b.bet_id) AS total_bets
  FROM `online-gambling-analytics.gambling_analytics.players` p
  LEFT JOIN `online-gambling-analytics.gambling_analytics.bets_clean` b
    ON p.player_id = b.player_id
  GROUP BY
    p.player_id,
    p.acquisition_channel,
    p.account_status
)

SELECT
  acquisition_channel,
  COUNT(*) AS registered_players,
  COUNTIF(total_bets > 0) AS players_who_bet,
  COUNTIF(total_bets = 0) AS players_who_never_bet,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(total_bets > 0),
      COUNT(*)
    ) * 100,
    2
  ) AS betting_conversion_pct,
  ROUND(AVG(total_bets), 2) AS avg_bets_per_registered_player
FROM player_activity
GROUP BY acquisition_channel
ORDER BY registered_players DESC;


--how frequently players bet?

WITH player_betting AS (
  SELECT
    p.player_id,
    p.country,
    p.acquisition_channel,
    p.account_status,
    COUNT(b.bet_id) AS total_bets,
    ROUND(SUM(b.stake_amount), 2) AS total_stakes,
    ROUND(SUM(b.payout_amount), 2) AS total_payouts
  FROM `online-gambling-analytics.gambling_analytics.players` p
  LEFT JOIN `online-gambling-analytics.gambling_analytics.bets_clean` b
    ON p.player_id = b.player_id
  GROUP BY
    p.player_id,
    p.country,
    p.acquisition_channel,
    p.account_status
)

SELECT
  CASE
    WHEN total_bets = 0 THEN '0 - No bets'
    WHEN total_bets BETWEEN 1 AND 5 THEN '1-5 bets'
    WHEN total_bets BETWEEN 6 AND 20 THEN '6-20 bets'
    WHEN total_bets BETWEEN 21 AND 50 THEN '21-50 bets'
    ELSE '51+ bets'
  END AS betting_frequency_group,
  COUNT(*) AS player_count,
  ROUND(AVG(total_bets), 2) AS avg_bets_per_player,
  ROUND(AVG(total_stakes), 2) AS avg_stakes_per_player,
  ROUND(AVG(total_payouts), 2) AS avg_payouts_per_player
FROM player_betting
GROUP BY betting_frequency_group
ORDER BY
  CASE betting_frequency_group
    WHEN '0 - No bets' THEN 1
    WHEN '1-5 bets' THEN 2
    WHEN '6-20 bets' THEN 3
    WHEN '21-50 bets' THEN 4
    ELSE 5
  END;




--engagement by account status

WITH player_activity AS (
  SELECT
    p.player_id,
    p.account_status,
    COUNT(b.bet_id) AS total_bets,
    COUNTIF(b.result IN ('Won', 'Lost')) AS settled_bets,
    COUNTIF(b.result = 'Void') AS voided_bets,
    COUNTIF(b.stake_amount IS NULL) AS bets_missing_stake
  FROM `online-gambling-analytics.gambling_analytics.players` p
  LEFT JOIN `online-gambling-analytics.gambling_analytics.bets_clean` b
    ON p.player_id = b.player_id
  GROUP BY
    p.player_id,
    p.account_status
)

SELECT
  account_status,
  COUNT(*) AS registered_players,
  COUNTIF(total_bets > 0) AS players_who_bet,
  ROUND(AVG(total_bets), 2) AS avg_bets_per_player,
  ROUND(AVG(settled_bets), 2) AS avg_settled_bets_per_player,
  SUM(voided_bets) AS total_voided_bets,
  SUM(bets_missing_stake) AS total_bets_missing_stake
FROM player_activity
GROUP BY account_status
ORDER BY registered_players DESC;


--measure player recency

WITH player_last_bet AS (
  SELECT
    p.player_id,
    p.account_status,
    MAX(DATE(b.bet_time)) AS last_bet_date
  FROM `online-gambling-analytics.gambling_analytics.players` p
  LEFT JOIN `online-gambling-analytics.gambling_analytics.bets_clean` b
    ON p.player_id = b.player_id
  GROUP BY
    p.player_id,
    p.account_status
),

player_recency AS (
  SELECT
    player_id,
    account_status,
    last_bet_date,
    DATE_DIFF(
      (SELECT MAX(DATE(bet_time))
       FROM `online-gambling-analytics.gambling_analytics.bets_clean`),
      last_bet_date,
      DAY
    ) AS days_since_last_bet
  FROM player_last_bet
)

SELECT
  CASE
    WHEN last_bet_date IS NULL THEN 'Never bet'
    WHEN days_since_last_bet <= 7 THEN 'Last 7 days'
    WHEN days_since_last_bet <= 30 THEN '8-30 days'
    WHEN days_since_last_bet <= 90 THEN '31-90 days'
    ELSE 'Over 90 days'
  END AS betting_recency_group,
  COUNT(*) AS player_count
FROM player_recency
GROUP BY betting_recency_group
ORDER BY
  CASE betting_recency_group
    WHEN 'Last 7 days' THEN 1
    WHEN '8-30 days' THEN 2
    WHEN '31-90 days' THEN 3
    WHEN 'Over 90 days' THEN 4
    ELSE 5
  END;


--compare recency with account status
--Do players marked Inactive or Closed actually have older last-bet dates than Active players?

WITH player_last_bet AS (
  SELECT
    p.player_id,
    p.account_status,
    MAX(DATE(b.bet_time)) AS last_bet_date
  FROM `online-gambling-analytics.gambling_analytics.players` p
  LEFT JOIN `online-gambling-analytics.gambling_analytics.bets_clean` b
    ON p.player_id = b.player_id
  GROUP BY p.player_id, p.account_status
),

dataset_end AS (
  SELECT MAX(DATE(bet_time)) AS max_bet_date
  FROM `online-gambling-analytics.gambling_analytics.bets_clean`
)

SELECT
  p.account_status,
  COUNT(*) AS registered_players,
  COUNTIF(
    DATE_DIFF(d.max_bet_date, p.last_bet_date, DAY) <= 30
  ) AS last_bet_within_30_days,
  COUNTIF(
    DATE_DIFF(d.max_bet_date, p.last_bet_date, DAY) > 30
  ) AS last_bet_over_30_days,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        DATE_DIFF(d.max_bet_date, p.last_bet_date, DAY) <= 30
      ),
      COUNT(*)
    ) * 100,
    2
  ) AS pct_last_bet_within_30_days
FROM player_last_bet p
CROSS JOIN dataset_end d
GROUP BY p.account_status
ORDER BY registered_players DESC;



--analyze sessions and engagement

SELECT
  game_category,
  device,
  COUNT(*) AS total_sessions,
  COUNT(DISTINCT player_id) AS unique_players,
  ROUND(AVG(session_duration_minutes), 2) AS avg_session_minutes,
  ROUND(AVG(bets_placed), 2) AS avg_bets_per_session,
  ROUND(
    SAFE_DIVIDE(
      SUM(bets_placed),
      SUM(session_duration_minutes)
    ) * 60,
    2
  ) AS bets_per_session_hour
FROM `online-gambling-analytics.gambling_analytics.sessions`
GROUP BY game_category, device
ORDER BY total_sessions DESC;

--enagagement across devices

SELECT
  device,
  COUNT(*) AS total_sessions,
  COUNT(DISTINCT player_id) AS unique_players,
  ROUND(AVG(session_duration_minutes), 2) AS avg_session_minutes,
  ROUND(AVG(bets_placed), 2) AS avg_bets_per_session,
  ROUND(
    SAFE_DIVIDE(
      SUM(bets_placed),
      SUM(session_duration_minutes)
    ) * 60,
    2
  ) AS bets_per_session_hour
FROM `online-gambling-analytics.gambling_analytics.sessions`
GROUP BY device
ORDER BY total_sessions DESC;


