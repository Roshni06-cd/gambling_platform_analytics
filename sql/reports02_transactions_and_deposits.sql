--DEPOSITS AND WITHDRAWALS
--How much money was deposited and withdrawn each month, and how many transactions were approved or declined?

SELECT
  DATE_TRUNC(DATE(transaction_time), MONTH) AS month,

  COUNTIF(transaction_type = 'Deposit') AS deposit_transactions,
  ROUND(SUM(
    IF(
      transaction_type = 'Deposit'
      AND status = 'Approved',
      amount, 0
    )
  ), 2) AS approved_deposit_amount,

  COUNTIF(transaction_type = 'Withdrawal') AS withdrawal_transactions,
  ROUND(SUM(
    IF(
      transaction_type = 'Withdrawal'
      AND status = 'Approved',
      amount, 0
    )
  ), 2) AS approved_withdrawal_amount,

  COUNTIF(status = 'Declined') AS declined_transactions,
  COUNTIF(status = 'Pending') AS pending_transactions

FROM `online-gambling-analytics.gambling_analytics.transactions_standardized`
GROUP BY month
ORDER BY month;