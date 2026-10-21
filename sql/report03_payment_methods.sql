--PAYMENT_METHODS
--Are some payment methods associated with more declined transactions than others?
SELECT
  payment_method,
  transaction_type,
  COUNT(*) AS total_transactions,
  COUNTIF(status = 'Approved') AS approved_transactions,
  COUNTIF(status = 'Declined') AS declined_transactions,
  COUNTIF(status = 'Pending') AS pending_transactions,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(status = 'Approved'),
      COUNT(*)
    ) * 100,
    2
  ) AS approval_rate_pct,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(status = 'Declined'),
      COUNT(*)
    ) * 100,
    2
  ) AS decline_rate_pct
FROM `online-gambling-analytics.gambling_analytics.transactions_standardized`
GROUP BY
  payment_method,
  transaction_type
ORDER BY
  decline_rate_pct DESC;
