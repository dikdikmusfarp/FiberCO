WITH
period AS (
    SELECT MAX(CAST(snapshot_date AS DATE)) AS snapshot_month
    FROM subscription_snapshot
),
region_performance AS (
    SELECT
        homepass.region,
        COUNT(DISTINCT subs.contract_account) AS active_ca,
        COUNT(DISTINCT media.contract_account) AS media_ca,
        SUM(CASE
            WHEN media.contract_account IS NOT NULL
            THEN media.package_price + media.ao_rrp_price
            ELSE 0
        END) AS media_revenue
    FROM period
    JOIN subscription_snapshot AS subs
        ON CAST(subs.snapshot_date AS DATE) = period.snapshot_month
       AND subs.active_flag = 1
    LEFT JOIN homepass
        ON homepass.homeid = subs.homeid
    LEFT JOIN media_package AS media
        ON media.contract_account = subs.contract_account
    GROUP BY 1
),
region_attach AS (
    SELECT
        *,
        ROUND(100.0 * media_ca / NULLIF(active_ca, 0), 2) AS attach_rate_pct
    FROM region_performance
),
region_opportunity AS (
    SELECT
        *,
        MAX(attach_rate_pct) OVER () AS benchmark_attach_rate_pct
    FROM region_attach
)
SELECT
    region,
    active_ca,
    media_ca,
    active_ca - media_ca AS non_media_ca,
    attach_rate_pct,
    media_revenue,
    benchmark_attach_rate_pct,
    CEIL(active_ca * benchmark_attach_rate_pct / 100.0) - media_ca AS potential_media_ca,
    RANK() OVER (
        ORDER BY CEIL(active_ca * benchmark_attach_rate_pct / 100.0) - media_ca DESC
    ) AS opportunity_rank
FROM region_opportunity
ORDER BY opportunity_rank, region;
