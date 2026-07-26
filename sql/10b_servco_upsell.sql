WITH
period AS (
    SELECT MAX(CAST(snapshot_date AS DATE)) AS snapshot_month
    FROM subscription_snapshot
),
servco_upsell AS (
    SELECT
        servco.servco_name,
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
    LEFT JOIN servco
        ON servco.servco_id = subs.servco_id
    LEFT JOIN media_package AS media
        ON media.contract_account = subs.contract_account
    GROUP BY 1
)
SELECT
    servco_name,
    active_ca,
    media_ca,
    active_ca - media_ca AS non_media_ca,
    ROUND(100.0 * media_ca / NULLIF(active_ca, 0), 2) AS attach_rate_pct,
    media_revenue,
    RANK() OVER (
        ORDER BY media_ca / NULLIF(active_ca, 0) DESC
    ) AS upsell_rank
FROM servco_upsell
ORDER BY upsell_rank, servco_name;
