WITH
period AS (
    SELECT MAX(CAST(snapshot_date AS DATE)) AS snapshot_month
    FROM subscription_snapshot
)
SELECT
    media.add_on_product,
    COUNT(DISTINCT media.contract_account) AS media_ca,
    SUM(media.ao_rrp_price) AS add_on_revenue,
    SUM(media.ao_wholesale_price) AS add_on_cost,
    SUM(
        media.ao_rrp_price - media.ao_wholesale_price
    ) AS add_on_margin,
    ROUND(
        100.0 * SUM(media.ao_rrp_price - media.ao_wholesale_price)
        / NULLIF(SUM(media.ao_rrp_price), 0), 2
    ) AS add_on_margin_pct
FROM period
JOIN subscription_snapshot AS subs
    ON CAST(subs.snapshot_date AS DATE) = period.snapshot_month
   AND subs.active_flag = 1
JOIN media_package AS media
    ON media.contract_account = subs.contract_account
GROUP BY 1
ORDER BY add_on_margin DESC, media.add_on_product;
