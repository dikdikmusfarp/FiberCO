WITH
period AS (
    SELECT MAX(CAST(snapshot_date AS DATE)) AS snapshot_month
    FROM subscription_snapshot
),
region_attach AS (
    SELECT
        homepass.region,
        COUNT(DISTINCT subs.contract_account) AS active_ca,
        COUNT(DISTINCT media.contract_account) AS media_ca,
        ROUND(
            100.0 * COUNT(DISTINCT media.contract_account)
            / NULLIF(COUNT(DISTINCT subs.contract_account), 0), 2
        ) AS attach_rate_pct
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
benchmark AS (
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
    benchmark_attach_rate_pct,
    CEIL(active_ca * benchmark_attach_rate_pct / 100.0)
        - media_ca AS potential_media_ca
FROM benchmark
ORDER BY potential_media_ca DESC, region;
