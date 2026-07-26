WITH
period AS (
    SELECT DISTINCT CAST(snapshot_date AS DATE) AS snapshot_month
    FROM subscription_snapshot
),
monthly_homepass AS (
    SELECT
        period.snapshot_month,
        homepass.homeid,
        homepass.region,
        homepass.technology,
        CASE
            WHEN homepass.exclusive_flag = 'Y' THEN 'Exclusive'
            ELSE 'Non-exclusive'
        END AS exclusivity,
        subs.contract_account
    FROM period
    CROSS JOIN homepass
    LEFT JOIN subscription_snapshot AS subs
        ON subs.homeid = homepass.homeid
       AND CAST(subs.snapshot_date AS DATE) = period.snapshot_month
       AND subs.active_flag = 1
),
penetration AS (
    SELECT 
    	snapshot_month, 
    	'Region' AS dimension, 
    	region AS segment,
       	COUNT(DISTINCT homeid) AS total_homepass,
       	COUNT(DISTINCT contract_account) AS active_ca
    FROM monthly_homepass GROUP BY 1, 2, 3
    UNION ALL
    SELECT 
    	snapshot_month, 
    	'Technology' AS dimension, 
    	technology AS segment,
        COUNT(DISTINCT homeid) AS total_homepass, 
        COUNT(DISTINCT contract_account) AS active_ca
    FROM monthly_homepass GROUP BY 1, 2, 3
    UNION ALL
    SELECT 
    	snapshot_month, 
    	'Exclusivity' AS dimension, 
    	exclusivity AS segment,
        COUNT(DISTINCT homeid) AS total_homepass, 
        COUNT(DISTINCT contract_account) AS active_ca
    FROM monthly_homepass GROUP BY 1, 2, 3
)
SELECT
    snapshot_month,
    dimension,
    segment,
    total_homepass,
    active_ca,
    ROUND(100.0 * active_ca / NULLIF(total_homepass, 0), 2) AS penetration_pct
FROM penetration
ORDER BY snapshot_month, dimension, segment;
