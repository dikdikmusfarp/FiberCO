WITH
period AS (
    SELECT MAX(CAST(snapshot_date AS DATE)) AS snapshot_month
    FROM subscription_snapshot
),
infrastructure AS (
    SELECT
        technology,
        COUNT(DISTINCT homeid) AS total_homepass,
        SUM(capex_cost) AS total_capex
    FROM homepass GROUP BY 1
),
technology_performance AS (
    SELECT
        homepass.technology,
        COUNT(DISTINCT subs.contract_account) AS active_ca,
        SUM(servco.lease_fee_per_active) AS lease_revenue
    FROM period
    JOIN subscription_snapshot AS subs
        ON CAST(subs.snapshot_date AS DATE) = period.snapshot_month
       AND subs.active_flag = 1
    LEFT JOIN homepass
        ON homepass.homeid = subs.homeid
    LEFT JOIN servco
        ON servco.servco_id = subs.servco_id
    GROUP BY 1
)
SELECT
    infrastructure.technology,
    infrastructure.total_homepass,
    technology_performance.active_ca,
    ROUND(
        100.0 * technology_performance.active_ca
        / NULLIF(infrastructure.total_homepass, 0), 2
    ) AS penetration_pct,
    technology_performance.lease_revenue,
    ROUND(
        technology_performance.lease_revenue
        / NULLIF(infrastructure.total_homepass, 0), 0
    ) AS revenue_per_homepass,
    infrastructure.total_capex,
    ROUND(
        infrastructure.total_capex
        / NULLIF(technology_performance.active_ca, 0), 0
    ) AS capex_per_active_ca
FROM infrastructure
LEFT JOIN technology_performance
    ON technology_performance.technology = infrastructure.technology
ORDER BY infrastructure.technology;
