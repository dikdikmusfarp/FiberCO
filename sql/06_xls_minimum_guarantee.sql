WITH
xls_performance AS (
    SELECT
        CAST(subs.snapshot_date AS DATE) AS snapshot_month,
        subs.servco_id,
        servco.servco_name,
        CAST(REPLACE(servco.minimum_guarantee, ',', '.') AS DECIMAL(10, 2)) AS minimum_guarantee,
        MAX(servco.lease_fee_per_active) AS lease_fee_per_active,
        COUNT(DISTINCT subs.homeid) AS serviceable_homepass,
        COUNT(DISTINCT CASE
            WHEN subs.active_flag = 1 THEN subs.contract_account
        END) AS active_ca
    FROM subscription_snapshot AS subs
    LEFT JOIN servco
        ON servco.servco_id = subs.servco_id
    WHERE subs.servco_id = 101
    GROUP BY 1, 2, 3, 4
)
SELECT
    snapshot_month,
    servco_id,
    servco_name,
    serviceable_homepass,
    active_ca,
    ROUND(100.0 * active_ca / NULLIF(serviceable_homepass, 0), 2) AS actual_penetration_pct,
    ROUND(100.0 * minimum_guarantee, 2) AS minimum_guarantee_pct,
    CEIL(serviceable_homepass * minimum_guarantee) AS minimum_active_ca,
    active_ca - CEIL(serviceable_homepass * minimum_guarantee) AS active_ca_gap,
    ROUND(
        100.0 * active_ca / NULLIF(serviceable_homepass, 0)
        - 100.0 * minimum_guarantee, 2
    ) AS penetration_gap_pp,
    active_ca * lease_fee_per_active AS lease_revenue,
    CASE
        WHEN active_ca >= CEIL(serviceable_homepass * minimum_guarantee)
        THEN 'Meeting guarantee'
        ELSE 'Below guarantee'
    END AS guarantee_status
FROM xls_performance
ORDER BY snapshot_month;
