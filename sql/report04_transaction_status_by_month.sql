--TRANSACTION STATUS BY MONTH

SELECT
  DATE_TRUNC(DATE(transaction_time), MONTH) AS month,
  transaction_type,
  status,
  COUNT(*) AS transaction_count,
  ROUND(SUM(amount), 2) AS total_amount
FROM `online-gambling-analytics.gambling_analytics.transactions_standardized`
GROUP BY
  month,
  transaction_type,
  status
ORDER BY
  month,
  transaction_type,
  status;


  --monthly summary of decline rates
  
SELECT
  DATE_TRUNC(DATE(transaction_time), MONTH) AS month,

  COUNTIF(
    transaction_type = 'Deposit'
  ) AS deposit_attempts,

  COUNTIF(
    transaction_type = 'Deposit'
    AND status = 'Declined'
  ) AS declined_deposits,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        transaction_type = 'Deposit'
        AND status = 'Declined'
      ),
      COUNTIF(transaction_type = 'Deposit')
    ) * 100,
    2
  ) AS deposit_decline_rate_pct,

  COUNTIF(
    transaction_type = 'Withdrawal'
  ) AS withdrawal_attempts,

  COUNTIF(
    transaction_type = 'Withdrawal'
    AND status = 'Declined'
  ) AS declined_withdrawals,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        transaction_type = 'Withdrawal'
        AND status = 'Declined'
      ),
      COUNTIF(transaction_type = 'Withdrawal')
    ) * 100,
    2
  ) AS withdrawal_decline_rate_pct

FROM `online-gambling-analytics.gambling_analytics.transactions_standardized`
GROUP BY month
ORDER BY month;



--Compare 2024 with 2025

SELECT
  EXTRACT(YEAR FROM transaction_time) AS year,

  COUNTIF(transaction_type = 'Deposit') AS deposit_attempts,
  COUNTIF(
    transaction_type = 'Deposit'
    AND status = 'Declined'
  ) AS declined_deposits,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        transaction_type = 'Deposit'
        AND status = 'Declined'
      ),
      COUNTIF(transaction_type = 'Deposit')
    ) * 100,
    2
  ) AS deposit_decline_rate_pct,

  COUNTIF(transaction_type = 'Withdrawal') AS withdrawal_attempts,
  COUNTIF(
    transaction_type = 'Withdrawal'
    AND status = 'Declined'
  ) AS declined_withdrawals,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        transaction_type = 'Withdrawal'
        AND status = 'Declined'
      ),
      COUNTIF(transaction_type = 'Withdrawal')
    ) * 100,
    2
  ) AS withdrawal_decline_rate_pct

FROM `online-gambling-analytics.gambling_analytics.transactions_standardized`
GROUP BY year
ORDER BY year;

