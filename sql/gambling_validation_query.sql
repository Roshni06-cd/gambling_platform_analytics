
SELECT 'players' AS table_name, COUNT(*) AS row_count
FROM `online-gambling-analytics.gambling_analytics.players`

UNION ALL

SELECT 'bets', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.bets`

UNION ALL

SELECT 'transactions', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.transactions`

UNION ALL

SELECT 'sessions', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.sessions`

UNION ALL

SELECT 'bonuses', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.bonuses`

UNION ALL

SELECT 'events', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.events`

UNION ALL

SELECT 'campaigns', COUNT(*)
FROM `online-gambling-analytics.gambling_analytics.campaigns`

ORDER BY table_name;
