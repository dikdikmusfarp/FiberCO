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
        COUNT(DISTINCT subs.contract_account) AS active_ca
    FROM period
    CROSS JOIN homepass
    LEFT JOIN subscription_snapshot AS subs
        ON subs.homeid = homepass.homeid
       AND CAST(subs.snapshot_date AS DATE) = period.snapshot_month
       AND subs.active_flag = 1
    GROUP BY 1, 2, 3, 4
),
fibernode_utilization AS (
    SELECT
        snapshot_month,
        fibernode,
        region,
        COUNT(homeid) AS total_homepass,
        SUM(active_ca) AS active_ca,
        ROUND(
            100.0 * SUM(active_ca) / NULLIF(COUNT(homeid), 0), 2
        ) AS penetration_pct
    FROM monthly_homepass GROUP BY 1, 2, 3
),
utilization_rank AS (
    SELECT
        *,
        NTILE(4) OVER (
            PARTITION BY snapshot_month
            ORDER BY penetration_pct
        ) AS utilization_quartile
    FROM fibernode_utilization
),
utilization_summary AS (
    SELECT
        fibernode,
        region,
        MAX(total_homepass) AS total_homepass,
        COUNT(*) AS periods_observed,
        ROUND(AVG(penetration_pct), 2) AS avg_penetration_pct,
        ROUND(MIN(penetration_pct), 2) AS min_penetration_pct,
        ROUND(MAX(penetration_pct), 2) AS max_penetration_pct,
        ROUND(MAX(CASE
            WHEN snapshot_month = (SELECT MAX(snapshot_month) FROM period)
            THEN penetration_pct
        END), 2) AS latest_penetration_pct,
        MAX(CASE
            WHEN snapshot_month = (SELECT MAX(snapshot_month) FROM period)
            THEN active_ca
        END) AS latest_active_ca,
        MAX(CASE
            WHEN snapshot_month = (SELECT MAX(snapshot_month) FROM period)
            THEN utilization_quartile
        END) AS latest_quartile,
        SUM(CASE
            WHEN utilization_quartile = 1 THEN 1
            ELSE 0
        END) AS periods_bottom_quartile,
        ROUND(
            MAX(CASE
                WHEN snapshot_month = (SELECT MAX(snapshot_month) FROM period)
                THEN penetration_pct
            END) - MAX(CASE
                WHEN snapshot_month = (SELECT MIN(snapshot_month) FROM period)
                THEN penetration_pct
            END), 2
        ) AS penetration_change_pp
    FROM utilization_rank GROUP BY 1, 2
),
benchmark AS (
    SELECT
        *,
        NTILE(4) OVER (
            ORDER BY avg_penetration_pct
        ) AS avg_utilization_quartile
    FROM utilization_summary
)
SELECT
    fibernode,
    region,
    total_homepass,
    latest_active_ca,
    latest_penetration_pct,
    avg_penetration_pct,
    min_penetration_pct,
    max_penetration_pct,
    penetration_change_pp,
    periods_bottom_quartile,
    periods_observed,
    CASE
        WHEN latest_quartile = 1 THEN 'Y'
        ELSE 'N'
    END AS current_underperformer,
    CASE
        WHEN avg_utilization_quartile = 1
          OR periods_bottom_quartile >= 6
        THEN 'Y'
        ELSE 'N'
    END AS persistent_underperformer
FROM benchmark
ORDER BY avg_penetration_pct, fibernode;
