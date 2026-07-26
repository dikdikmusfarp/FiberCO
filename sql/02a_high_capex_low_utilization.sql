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
        homepass.fibernode,
        homepass.capex_cost,
        COUNT(DISTINCT subs.contract_account) AS active_ca
    FROM period
    CROSS JOIN homepass
    LEFT JOIN subscription_snapshot AS subs
        ON subs.homeid = homepass.homeid
       AND CAST(subs.snapshot_date AS DATE) = period.snapshot_month
       AND subs.active_flag = 1
    GROUP BY 1, 2, 3, 4, 5
),
area_utilization AS (
    SELECT
        snapshot_month,
        'Region' AS area_level,
        region AS area_name,
        region,
        COUNT(homeid) AS total_homepass,
        SUM(capex_cost) AS total_capex,
        SUM(active_ca) AS active_ca
    FROM monthly_homepass GROUP BY 1, 2, 3, 4
    UNION ALL
    SELECT
        snapshot_month,
        'Fibernode' AS area_level,
        fibernode AS area_name,
        region,
        COUNT(homeid) AS total_homepass,
        SUM(capex_cost) AS total_capex,
        SUM(active_ca) AS active_ca
    FROM monthly_homepass GROUP BY 1, 2, 3, 4
),
utilization_summary AS (
    SELECT
        area_level,
        area_name,
        region,
        MAX(total_homepass) AS total_homepass,
        MAX(total_capex) AS total_capex,
        MAX(CASE
            WHEN snapshot_month = (SELECT MAX(snapshot_month) FROM period)
            THEN active_ca
        END) AS latest_active_ca,
        ROUND(AVG(100.0 * active_ca / NULLIF(total_homepass, 0)), 2) AS avg_penetration_pct,
        ROUND(MAX(CASE
            WHEN snapshot_month = (SELECT MAX(snapshot_month) FROM period)
            THEN 100.0 * active_ca / NULLIF(total_homepass, 0)
        END), 2) AS latest_penetration_pct
    FROM area_utilization GROUP BY 1, 2, 3
),
benchmark AS (
    SELECT
        *,
        MEDIAN(total_capex) OVER (PARTITION BY area_level) AS median_capex,
        MEDIAN(avg_penetration_pct) OVER (
            PARTITION BY area_level
        ) AS median_avg_penetration
    FROM utilization_summary
)
SELECT
    area_level,
    area_name,
    region,
    total_homepass,
    latest_active_ca,
    latest_penetration_pct,
    avg_penetration_pct,
    total_capex,
    ROUND(total_capex / NULLIF(latest_active_ca, 0), 0) AS capex_per_latest_active_ca,
    median_capex,
    median_avg_penetration,
    CASE
        WHEN total_capex >= median_capex
         AND avg_penetration_pct < median_avg_penetration
        THEN 'Y'
        ELSE 'N'
    END AS high_capex_low_utilization
FROM benchmark
ORDER BY area_level, avg_penetration_pct, area_name;
