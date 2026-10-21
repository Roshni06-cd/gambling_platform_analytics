--MONTHLY BETTING PERFORMANCE REPORT

--Calculate monthly betting KPIs

-- Monthly betting performance
-- GGR is provisional: stakes minus payouts on
-- Won/Lost bets with a known stake.
-- Void bets and missing-stake bets are excluded
-- from the GGR calculation.

SELECT
  DATE_TRUNC(DATE(bet_time), MONTH) AS month,

  COUNT(*) AS total_bets,

  COUNT(DISTINCT player_id) AS active_bettors,

  COUNTIF(stake_amount IS NULL) AS bets_missing_stake,

  COUNTIF(
    result IN ('Won', 'Lost')
    AND stake_amount IS NOT NULL
  ) AS valid_settled_bets,

  SUM(
    IF(
      result IN ('Won', 'Lost')
      AND stake_amount IS NOT NULL,
      stake_amount,
      0
    )
  ) AS total_stakes,

  SUM(
    IF(
      result IN ('Won', 'Lost')
      AND stake_amount IS NOT NULL,
      payout_amount,
      0
    )
  ) AS total_payouts,

  SUM(
    IF(
      result IN ('Won', 'Lost')
      AND stake_amount IS NOT NULL,
      stake_amount - payout_amount,
      0
    )
  ) AS gross_gaming_revenue

FROM `online-gambling-analytics.gambling_analytics.bets_clean`
GROUP BY month
ORDER BY month;
