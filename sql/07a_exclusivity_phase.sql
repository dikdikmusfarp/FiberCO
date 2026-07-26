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
monthly_homepass AS (
    SELECT
        period.snapshot_month,
        homepass.homeid,
        homepass.exclusive_start_date,
        homepass.exclusive_end_date,
        COALESCE(subscription_by_home.active_ca, 0) AS active_ca,
        COALESCE(subscription_by_home.active_homepass, 0) AS active_homepass,
        COALESCE(subscription_by_home.lease_revenue, 0) AS lease_revenue
    FROM period
    CROSS JOIN homepass
    LEFT JOIN subscription_by_home
        ON subscription_by_home.snapshot_month = period.snapshot_month
       AND subscription_by_home.homeid = homepass.homeid
    WHERE homepass.exclusive_flag = 'Y'
),
performance AS (
    SELECT
        snapshot_month,
        CASE
            WHEN snapshot_month BETWEEN exclusive_start_date AND exclusive_end_date
            THEN 'Exclusive window'
            ELSE 'Post exclusive'
        END AS exclusivity_phase,
        COUNT(homeid) AS total_homepass,
        SUM(active_homepass) AS active_homepass,
        SUM(active_ca) AS active_ca,
        SUM(lease_revenue) AS lease_revenue
    FROM monthly_homepass GROUP BY 1, 2
)
SELECT
    snapshot_month,
    exclusivity_phase,
    total_homepass,
    active_homepass,
    active_ca,
    active_ca - active_homepass AS additional_ca_on_active_home,
    ROUND(
        100.0 * active_homepass / NULLIF(total_homepass, 0), 2
    ) AS homepass_penetration_pct,
    ROUND(
        100.0 * active_ca / NULLIF(total_homepass, 0), 2
    ) AS ca_penetration_pct,
    lease_revenue,
    ROUND(
        lease_revenue / NULLIF(total_homepass, 0), 0
    ) AS revenue_per_homepass,
    ROUND(
        lease_revenue / NULLIF(active_ca, 0), 0
    ) AS revenue_per_active_ca
FROM performance
ORDER BY snapshot_month;
