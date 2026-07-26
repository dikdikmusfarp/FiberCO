WITH
period AS (
    SELECT MAX(CAST(snapshot_date AS DATE)) AS snapshot_month
    FROM subscription_snapshot
),
active_customer AS (
    SELECT
        period.snapshot_month,
        subs.contract_account,
        subs.servco_id,
        servco.servco_name,
        homepass.region,
        CASE
            WHEN media.contract_account IS NOT NULL THEN 1
            ELSE 0
        END AS media_flag
    FROM period
    JOIN subscription_snapshot AS subs
        ON CAST(subs.snapshot_date AS DATE) = period.snapshot_month
       AND subs.active_flag = 1
    LEFT JOIN homepass
        ON homepass.homeid = subs.homeid
    LEFT JOIN servco
        ON servco.servco_id = subs.servco_id
    LEFT JOIN media_package AS media
        ON media.contract_account = subs.contract_account
),
media_attach AS (
    SELECT
        snapshot_month,
        'Servco' AS dimension,
        servco_name AS segment,
        COUNT(DISTINCT contract_account) AS active_ca,
        COUNT(DISTINCT CASE
            WHEN media_flag = 1 THEN contract_account
        END) AS media_ca
    FROM active_customer GROUP BY 1, 2, 3
    UNION ALL
    SELECT
        snapshot_month,
        'Region' AS dimension,
        region AS segment,
        COUNT(DISTINCT contract_account) AS active_ca,
        COUNT(DISTINCT CASE
            WHEN media_flag = 1 THEN contract_account
        END) AS media_ca
    FROM active_customer GROUP BY 1, 2, 3
)
SELECT
    snapshot_month,
    dimension,
    segment,
    active_ca,
    media_ca,
    active_ca - media_ca AS non_media_ca,
    ROUND(100.0 * media_ca / NULLIF(active_ca, 0), 2) AS media_attach_rate_pct
FROM media_attach
ORDER BY dimension, media_attach_rate_pct DESC, segment;
