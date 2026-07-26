WITH
period AS (
    SELECT MAX(CAST(snapshot_date AS DATE)) AS snapshot_month
    FROM subscription_snapshot
),
product_profitability AS (
    SELECT
        media.add_on_product,
        COUNT(DISTINCT media.contract_account) AS media_ca,
        SUM(media.ao_rrp_price) AS add_on_revenue,
        SUM(media.ao_wholesale_price) AS add_on_cost
    FROM period
    JOIN subscription_snapshot AS subs
        ON CAST(subs.snapshot_date AS DATE) = period.snapshot_month
       AND subs.active_flag = 1
    JOIN media_package AS media
        ON media.contract_account = subs.contract_account
    GROUP BY 1
)
SELECT
    add_on_product,
    media_ca,
    add_on_revenue,
    add_on_cost,
    add_on_revenue - add_on_cost AS add_on_margin,
    ROUND(
        100.0 * (add_on_revenue - add_on_cost)
        / NULLIF(add_on_revenue, 0), 2
    ) AS add_on_margin_pct,
    RANK() OVER (
        ORDER BY add_on_revenue - add_on_cost DESC
    ) AS profitability_rank
FROM product_profitability
ORDER BY profitability_rank, add_on_product;
