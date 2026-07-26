WITH
period AS (
    SELECT MAX(CAST(snapshot_date AS DATE)) AS snapshot_month
    FROM subscription_snapshot
),
active_customer AS (
    SELECT
        subs.contract_account,
        servco.lease_fee_per_active AS lease_revenue,
        CASE
            WHEN media.contract_account IS NOT NULL THEN 'With media'
            ELSE 'Without media'
        END AS customer_type,
        COALESCE(media.package_price, 0)
        + COALESCE(media.ao_rrp_price, 0) AS media_revenue
    FROM period
    JOIN subscription_snapshot AS subs
        ON CAST(subs.snapshot_date AS DATE) = period.snapshot_month
       AND subs.active_flag = 1
    LEFT JOIN servco
        ON servco.servco_id = subs.servco_id
    LEFT JOIN media_package AS media
        ON media.contract_account = subs.contract_account
),
arpu AS (
    SELECT
        customer_type,
        COUNT(DISTINCT contract_account) AS active_ca,
        SUM(lease_revenue) AS lease_revenue,
        SUM(media_revenue) AS media_revenue
    FROM active_customer GROUP BY 1
)
SELECT
    customer_type,
    active_ca,
    lease_revenue,
    media_revenue,
    lease_revenue + media_revenue AS total_revenue,
    ROUND(lease_revenue / NULLIF(active_ca, 0), 0) AS lease_arpu,
    ROUND(media_revenue / NULLIF(active_ca, 0), 0) AS media_arpu,
    ROUND(
        (lease_revenue + media_revenue) / NULLIF(active_ca, 0), 0
    ) AS combined_arpu,
    ROUND(
        100.0 * media_revenue / NULLIF(lease_revenue, 0), 2
    ) AS arpu_uplift_pct
FROM arpu
ORDER BY customer_type;
