WITH
servco_monthly AS (
    SELECT
        CAST(subs.snapshot_date AS DATE) AS snapshot_month,
        subs.servco_id,
        servco.servco_name,
        COUNT(DISTINCT subs.homeid) AS serviceable_homepass,
        COUNT(DISTINCT CASE
            WHEN subs.active_flag = 1 THEN subs.contract_account
        END) AS active_ca,
        COUNT(DISTINCT CASE
            WHEN subs.active_flag = 1 THEN subs.contract_account
        END) * MAX(servco.lease_fee_per_active) AS lease_revenue
    FROM subscription_snapshot AS subs
    LEFT JOIN servco
        ON servco.servco_id = subs.servco_id
    GROUP BY 1, 2, 3
),
servco_performance AS (
    SELECT
        *,
        LAG(active_ca) OVER (
            PARTITION BY servco_id
            ORDER BY snapshot_month
        ) AS previous_active_ca,
        LAG(lease_revenue) OVER (
            PARTITION BY servco_id
            ORDER BY snapshot_month
        ) AS previous_lease_revenue,
        SUM(lease_revenue) OVER (
            PARTITION BY snapshot_month
        ) AS total_lease_revenue
    FROM servco_monthly
)
SELECT
    snapshot_month,
    servco_id,
    servco_name,
    serviceable_homepass,
    active_ca,
    active_ca - previous_active_ca AS active_ca_net_add,
    ROUND(
        100.0 * (active_ca - previous_active_ca)
        / NULLIF(previous_active_ca, 0), 2
    ) AS active_ca_growth_pct,
    ROUND(
        100.0 * active_ca / NULLIF(serviceable_homepass, 0), 2
    ) AS penetration_pct,
    lease_revenue,
    ROUND(
        100.0 * lease_revenue / NULLIF(total_lease_revenue, 0), 2
    ) AS lease_revenue_contribution_pct,
    ROUND(
        100.0 * (lease_revenue - previous_lease_revenue)
        / NULLIF(previous_lease_revenue, 0), 2
    ) AS lease_revenue_growth_pct
FROM servco_performance
ORDER BY snapshot_month, servco_id;
