WITH
period AS (
    SELECT DISTINCT CAST(snapshot_date AS DATE) AS snapshot_month
    FROM subscription_snapshot
),
monthly_homepass AS (
    SELECT
        period.snapshot_month,
        homepass.homeid,
        homepass.technology,
        CASE
            WHEN homepass.exclusive_flag = 'Y' THEN 'Exclusive area'
            ELSE 'Open access area'
        END AS access_type,
        COUNT(DISTINCT subs.contract_account) AS active_ca,
        SUM(CASE
            WHEN subs.active_flag = 1 THEN servco.lease_fee_per_active
            ELSE 0
        END) AS lease_revenue
    FROM period
    CROSS JOIN homepass
    LEFT JOIN subscription_snapshot AS subs
        ON subs.homeid = homepass.homeid
       AND CAST(subs.snapshot_date AS DATE) = period.snapshot_month
       AND subs.active_flag = 1
    LEFT JOIN servco
        ON servco.servco_id = subs.servco_id
    GROUP BY 1, 2, 3, 4
),
monetization AS (
    SELECT
        snapshot_month,
        'Access Type' AS dimension,
        access_type AS segment,
        COUNT(homeid) AS total_homepass,
        SUM(active_ca) AS active_ca,
        SUM(lease_revenue) AS lease_revenue
    FROM monthly_homepass GROUP BY 1, 2, 3
    UNION ALL
    SELECT
        snapshot_month,
        'Technology' AS dimension,
        technology AS segment,
        COUNT(homeid) AS total_homepass,
        SUM(active_ca) AS active_ca,
        SUM(lease_revenue) AS lease_revenue
    FROM monthly_homepass GROUP BY 1, 2, 3
)
SELECT
    snapshot_month,
    dimension,
    segment,
    total_homepass,
    active_ca,
    lease_revenue,
    ROUND(100.0 * active_ca / NULLIF(total_homepass, 0), 2) AS penetration_pct,
    ROUND(lease_revenue / NULLIF(total_homepass, 0), 0) AS revenue_per_homepass,
    ROUND(lease_revenue / NULLIF(active_ca, 0), 0) AS revenue_per_active_ca,
    ROUND(
        100.0 * (lease_revenue - LAG(lease_revenue) OVER (
            PARTITION BY dimension, segment ORDER BY snapshot_month
        )) / NULLIF(LAG(lease_revenue) OVER (
            PARTITION BY dimension, segment ORDER BY snapshot_month
        ), 0), 2
    ) AS revenue_growth_pct
FROM monetization
ORDER BY snapshot_month, dimension, segment;
