WITH
period AS (
    SELECT DISTINCT CAST(snapshot_date AS DATE) AS snapshot_month
    FROM subscription_snapshot
),
subscription_by_home AS (
    SELECT
        CAST(subs.snapshot_date AS DATE) AS snapshot_month,
        subs.homeid,
        COUNT(DISTINCT CASE
            WHEN subs.active_flag = 1 THEN subs.contract_account
        END) AS active_ca,
        MAX(CASE
            WHEN subs.active_flag = 1 THEN 1
            ELSE 0
        END) AS active_homepass,
        SUM(CASE
            WHEN subs.active_flag = 1 THEN servco.lease_fee_per_active
            ELSE 0
        END) AS lease_revenue
    FROM subscription_snapshot AS subs
    LEFT JOIN servco
        ON servco.servco_id = subs.servco_id
    GROUP BY 1, 2
),
monthly_performance AS (
    SELECT
        period.snapshot_month,
        COUNT(homepass.homeid) AS total_homepass,
        SUM(COALESCE(subscription_by_home.active_homepass, 0)) AS active_homepass,
        SUM(COALESCE(subscription_by_home.active_ca, 0)) AS active_ca,
        SUM(COALESCE(subscription_by_home.lease_revenue, 0)) AS lease_revenue
    FROM period
    CROSS JOIN homepass
    LEFT JOIN subscription_by_home
        ON subscription_by_home.snapshot_month = period.snapshot_month
       AND subscription_by_home.homeid = homepass.homeid
    WHERE homepass.exclusive_flag = 'Y'
    GROUP BY 1
)
SELECT
    snapshot_month,
    CASE
        WHEN snapshot_month = DATE '2025-06-30' THEN 'End of exclusive window'
        WHEN snapshot_month = DATE '2025-12-31' THEN 'Latest post exclusive'
    END AS comparison_period,
    total_homepass,
    active_homepass,
    active_ca,
    ROUND(100.0 * active_homepass / NULLIF(total_homepass, 0), 2) AS homepass_penetration_pct,
    lease_revenue,
    ROUND(lease_revenue / NULLIF(total_homepass, 0), 0) AS revenue_per_homepass
FROM monthly_performance
WHERE snapshot_month IN (DATE '2025-06-30', DATE '2025-12-31')
ORDER BY snapshot_month;
