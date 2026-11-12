/*
FDA AEMS – Drug Safety Analytics
04 | Data quality, reconciliation and validation
MySQL 8
Run after the relevant preparation and analysis scripts.
*/

USE fda_safety_analytics;

-- 1. Raw staging row counts and distinct identifiers
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT primaryid) AS distinct_primaryids,
    COUNT(DISTINCT caseid) AS distinct_caseids
FROM stg_demo;

-- 2. Find repeated primary IDs for investigation
SELECT primaryid, COUNT(*) AS duplicate_count
FROM stg_demo
GROUP BY primaryid
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 20;

-- 3. Inspect repeated primary IDs (not all repeated IDs are necessarily exact duplicates)
SELECT
    d.primaryid,
    d.caseid,
    d.caseversion,
    d.fda_dt,
    d.init_fda_dt
FROM stg_demo d
JOIN (
    SELECT primaryid
    FROM stg_demo
    GROUP BY primaryid
    HAVING COUNT(*) > 1
) dup ON dup.primaryid = d.primaryid
ORDER BY d.primaryid, d.caseversion
LIMIT 1000;

-- 4. Compare row count with exact-row distinct count
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT_WS('|',
        primaryid, caseid, caseversion, i_f_code, event_dt,
        mfr_dt, init_fda_dt, fda_dt, rept_cod, auth_num,
        mfr_num, mfr_sndr, lit_ref, age, age_cod, age_grp,
        sex, e_sub, wt, wt_cod, rept_dt, to_mfr,
        occp_cod, reporter_country, occr_country
    )) AS unique_rows
FROM stg_demo;

-- 5. Compare clean table row counts
SELECT 'demo' AS table_name, COUNT(*) AS row_count FROM demo
UNION ALL SELECT 'drug', COUNT(*) FROM drug
UNION ALL SELECT 'indication', COUNT(*) FROM indication
UNION ALL SELECT 'outcome', COUNT(*) FROM outcome
UNION ALL SELECT 'reaction', COUNT(*) FROM reaction
UNION ALL SELECT 'reporter_source', COUNT(*) FROM reporter_source
UNION ALL SELECT 'therapy', COUNT(*) FROM therapy;

-- 6. Latest case-version reconciliation
SELECT
    COUNT(*) AS latest_version_rows,
    COUNT(DISTINCT caseid) AS distinct_latest_caseids
FROM vw_latest_case_version;

-- 7. Serious outcome summary validation
SELECT COUNT(*) AS invalid_rows
FROM drug_serious_summary
WHERE total_cases < 1
   OR serious_cases > total_cases
   OR serious_outcome_pct <>
      ROUND(100.0 * serious_cases / NULLIF(total_cases, 0), 2);

-- 8. PRR contingency-table arithmetic validation.
-- The total universe below is the latest-case count verified for this dataset.
SELECT COUNT(*) AS invalid_prr_rows
FROM prr_results
WHERE a + b <> drug_cases
   OR a + c <> reaction_cases
   OR a + b + c + d <> 1469305;

-- 9. Check serious-case totals
SELECT COUNT(*) AS serious_latest_cases
FROM serious_case;

-- 10. Check required views exist
SHOW FULL TABLES
WHERE Table_type = 'VIEW';

-- 11. Check indexes on PRR working tables
SHOW INDEX FROM prr_drug_case;
SHOW INDEX FROM prr_reaction_case;
