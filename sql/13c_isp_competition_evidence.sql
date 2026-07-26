WITH
period AS (
    SELECT MAX(CAST(snapshot_date AS DATE)) AS snapshot_month
    FROM subscription_snapshot
),
subscription_by_home AS (
    SELECT
        subs.homeid,
        COUNT(DISTINCT subs.servco_id) AS isp_count,
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
    FROM period
    JOIN subscription_snapshot AS subs
        ON CAST(subs.snapshot_date AS DATE) = period.snapshot_month
    LEFT JOIN servco
        ON servco.servco_id = subs.servco_id
    GROUP BY 1
),
competition AS (
    SELECT
        CASE
            WHEN isp_count = 1 THEN 'Single ISP'
            WHEN isp_count > 1 THEN 'Multi ISP'
        END AS competition_type,
        COUNT(homeid) AS total_homepass,
        SUM(active_homepass) AS active_homepass,
        SUM(active_ca) AS active_ca,
        SUM(lease_revenue) AS lease_revenue
    FROM subscription_by_home GROUP BY 1
)
SELECT
    competition_type,
    total_homepass,
    active_homepass,
    active_ca,
    active_ca - active_homepass AS additional_ca_on_active_home,
    ROUND(
        100.0 * active_homepass / NULLIF(total_homepass, 0), 2
    ) AS homepass_penetration_pct,
    lease_revenue,
    ROUND(
        lease_revenue / NULLIF(total_homepass, 0), 0
    ) AS revenue_per_homepass
FROM competition
ORDER BY competition_type;
