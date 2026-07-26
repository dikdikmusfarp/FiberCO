-- ============================================================
-- DATA EXPLORATION & VALIDATION
-- Linknet Technical Assessment
-- ============================================================

-- 1. TABLE OVERVIEW
-- ============================================================
SELECT 
    'homepass' as table_name,
    COUNT(*) as row_count,
    COUNT(DISTINCT homeid) as unique_ids
FROM homepass
UNION ALL
SELECT 
    'subscription_snapshot',
    COUNT(*),
    COUNT(DISTINCT contract_account)
FROM subscription_snapshot
UNION ALL
SELECT 
    'media_package',
    COUNT(*),
    COUNT(DISTINCT contract_account)
FROM media_package
UNION ALL
SELECT 
    'servco',
    COUNT(*),
    COUNT(DISTINCT servco_id)
FROM servco
UNION ALL
SELECT 
    'region_master',
    COUNT(*),
    COUNT(DISTINCT region)
FROM region_master;

-- 2. HOMEPASS OVERVIEW
-- ============================================================
SELECT 
    technology,
    exclusive_flag,
    COUNT(*) as homepass_count,
    SUM(capex_cost) as total_capex,
    AVG(capex_cost) as avg_capex_per_hp
FROM homepass
GROUP BY technology, exclusive_flag
ORDER BY technology, exclusive_flag;

-- 3. SUBSCRIPTION DATE RANGE
-- ============================================================
SELECT 
    MIN(snapshot_date) as first_snapshot,
    MAX(snapshot_date) as last_snapshot,
    COUNT(DISTINCT snapshot_date) as total_snapshots
FROM subscription_snapshot;

-- 4. SERVCO OVERVIEW
-- ============================================================
SELECT 
    servco_id,
    servco_name,
    minimum_guarantee,
    lease_fee_per_active
FROM servco
ORDER BY servco_id;

-- 5. MEDIA PACKAGE OVERVIEW
-- ============================================================
SELECT 
    catv_package,
    COUNT(DISTINCT contract_account) as customers,
    COUNT(DISTINCT add_on_product) as unique_addons
FROM media_package
GROUP BY catv_package
ORDER BY customers DESC;

-- 6. REGION OVERVIEW
-- ============================================================
SELECT 
    island,
    urban_rural,
    COUNT(DISTINCT region) as regions,
    COUNT(DISTINCT fibernode) as fibernodes
FROM region_master
GROUP BY island, urban_rural
ORDER BY island, urban_rural;

-- 7. ACTIVE SUBSCRIBERS BY MONTH
-- ============================================================
SELECT 
    DATE_TRUNC('month', snapshot_date) as month,
    COUNT(DISTINCT CASE WHEN active_flag = 1 THEN contract_account END) as active_ca,
    COUNT(DISTINCT contract_account) as total_ca
FROM subscription_snapshot
GROUP BY month
ORDER BY month;

-- 8. CHECK FOR NULL VALUES IN KEY COLUMNS
-- ============================================================
SELECT 
    'homepass' as table_name,
    COUNT(*) - COUNT(homeid) as null_homeid,
    COUNT(*) - COUNT(technology) as null_technology,
    COUNT(*) - COUNT(exclusive_flag) as null_exclusive_flag
FROM homepass
UNION ALL
SELECT 
    'subscription_snapshot',
    COUNT(*) - COUNT(contract_account),
    COUNT(*) - COUNT(servco_id),
    COUNT(*) - COUNT(active_flag)
FROM subscription_snapshot;
