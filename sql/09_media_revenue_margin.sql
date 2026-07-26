WITH
period AS (
    SELECT MAX(CAST(snapshot_date AS DATE)) AS snapshot_month
    FROM subscription_snapshot
),
active_customer AS (
    SELECT
        period.snapshot_month,
        subs.contract_account,
        servco.servco_name,
        servco.lease_fee_per_active,
        media.catv_package,
        media.add_on_product,
        COALESCE(media.package_price, 0) AS package_revenue,
        COALESCE(media.ao_rrp_price, 0) AS add_on_revenue,
        COALESCE(media.ao_wholesale_price, 0) AS add_on_cost
    FROM period
    JOIN subscription_snapshot AS subs
        ON CAST(subs.snapshot_date AS DATE) = period.snapshot_month
       AND subs.active_flag = 1
    LEFT JOIN servco
        ON servco.servco_id = subs.servco_id
    LEFT JOIN media_package AS media
        ON media.contract_account = subs.contract_account
),
servco_contribution AS (
    SELECT
        snapshot_month,
        'Servco Revenue Contribution' AS analysis_type,
        servco_name AS segment,
        COUNT(DISTINCT contract_account) AS active_ca,
        COUNT(DISTINCT CASE
            WHEN add_on_product IS NOT NULL THEN contract_account
        END) AS media_ca,
        SUM(lease_fee_per_active) AS lease_revenue,
        SUM(package_revenue) AS package_revenue,
        SUM(add_on_revenue) AS add_on_revenue,
        SUM(add_on_cost) AS add_on_cost
    FROM active_customer GROUP BY 1, 2, 3
),
product_margin AS (
    SELECT
        snapshot_month,
        'Add On Product Margin' AS analysis_type,
        add_on_product AS segment,
        NULL AS active_ca,
        COUNT(DISTINCT contract_account) AS media_ca,
        NULL AS lease_revenue,
        NULL AS package_revenue,
        SUM(add_on_revenue) AS add_on_revenue,
        SUM(add_on_cost) AS add_on_cost
    FROM active_customer
    WHERE add_on_product IS NOT NULL
    GROUP BY 1, 2, 3
),
media_analysis AS (
    SELECT * FROM servco_contribution
    UNION ALL
    SELECT * FROM product_margin
)
SELECT
    snapshot_month,
    analysis_type,
    segment,
    active_ca,
    media_ca,
    lease_revenue,
    package_revenue,
    add_on_revenue,
    COALESCE(package_revenue, 0) + add_on_revenue AS media_revenue,
    add_on_cost,
    add_on_revenue - add_on_cost AS add_on_margin,
    ROUND(
        100.0 * (add_on_revenue - add_on_cost)
        / NULLIF(add_on_revenue, 0), 2
    ) AS add_on_margin_pct,
    ROUND(
        100.0 * lease_revenue
        / NULLIF(lease_revenue + package_revenue + add_on_revenue, 0), 2
    ) AS lease_revenue_contribution_pct,
    ROUND(
        100.0 * (package_revenue + add_on_revenue)
        / NULLIF(lease_revenue + package_revenue + add_on_revenue, 0), 2
    ) AS media_revenue_contribution_pct
FROM media_analysis
ORDER BY analysis_type, add_on_margin DESC, segment;
