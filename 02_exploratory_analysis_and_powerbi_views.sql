/*
FDA AEMS – Drug Safety Analytics
02 | Exploratory analysis and Power BI views
MySQL 8
Run after 01_data_cleaning.sql.
*/

USE fda_safety_analytics;

-- A. Dataset overview
SELECT
    COUNT(*) AS report_rows,
    COUNT(DISTINCT primaryid) AS distinct_report_ids,
    COUNT(DISTINCT caseid) AS distinct_case_ids
FROM demo;

SELECT
    COUNT(*) AS latest_version_rows,
    COUNT(DISTINCT caseid) AS latest_distinct_cases
FROM vw_latest_case_version;

-- B. Top 10 reported drugs
SELECT drugname, COUNT(DISTINCT primaryid) AS report_count
FROM drug
WHERE drugname IS NOT NULL AND TRIM(drugname) <> ''
GROUP BY drugname
ORDER BY report_count DESC
LIMIT 10;

-- C. Top 10 reported reactions
SELECT pt AS reaction, COUNT(DISTINCT primaryid) AS report_count
FROM reaction
WHERE pt IS NOT NULL AND TRIM(pt) <> ''
GROUP BY pt
ORDER BY report_count DESC
LIMIT 10;

-- D. Outcome-code distribution
SELECT outc_cod, COUNT(DISTINCT primaryid) AS report_count
FROM outcome
GROUP BY outc_cod
ORDER BY report_count DESC;

-- Serious outcome codes used in this project.
-- These are report-level counts across the cleaned report table.
SELECT COUNT(DISTINCT primaryid) AS serious_report_count
FROM outcome
WHERE outc_cod IN ('DE','LT','DS','CA','HO','OT','RI');

-- E. Quarterly reporting trend by FDA receipt date.
-- This counts report IDs, not unique cases.
SELECT
    CONCAT('Q', QUARTER(STR_TO_DATE(fda_dt, '%Y%m%d'))) AS quarter,
    COUNT(DISTINCT primaryid) AS report_count
FROM demo
WHERE fda_dt IS NOT NULL AND TRIM(fda_dt) <> ''
GROUP BY quarter
ORDER BY quarter;

-- Quarter-over-quarter change
WITH qtr_summary AS (
    SELECT
        QUARTER(STR_TO_DATE(fda_dt, '%Y%m%d')) AS quarter,
        COUNT(DISTINCT primaryid) AS report_count
    FROM demo
    WHERE fda_dt IS NOT NULL AND TRIM(fda_dt) <> ''
    GROUP BY QUARTER(STR_TO_DATE(fda_dt, '%Y%m%d'))
)
SELECT
    quarter,
    report_count,
    LAG(report_count) OVER (ORDER BY quarter) AS previous_quarter,
    ROUND(
        100.0 * (report_count - LAG(report_count) OVER (ORDER BY quarter))
        / NULLIF(LAG(report_count) OVER (ORDER BY quarter), 0),
        2
    ) AS qoq_change_pct
FROM qtr_summary
ORDER BY quarter;

-- F. Drug–reaction combinations among the ten most reported drugs
SELECT
    d.drugname,
    r.pt AS reaction,
    COUNT(DISTINCT d.primaryid) AS report_count
FROM drug d
JOIN reaction r ON r.primaryid = d.primaryid
WHERE d.drugname IN (
    'DUPIXENT','PREDNISONE','ACETAMINOPHEN','ASPIRIN',
    'MOUNJARO','ZEPBOUND','ATORVASTATIN','METHOTREXATE',
    'GABAPENTIN','OMEPRAZOLE'
)
GROUP BY d.drugname, r.pt
ORDER BY report_count DESC
LIMIT 10;

-- G. Demographics
SELECT
    CASE
        WHEN sex = 'M' THEN 'Male'
        WHEN sex = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS sex_group,
    COUNT(DISTINCT primaryid) AS report_count
FROM demo
GROUP BY sex_group
ORDER BY report_count DESC;

SELECT
    age_grp,
    COUNT(DISTINCT primaryid) AS report_count
FROM demo
WHERE age_grp IS NOT NULL AND TRIM(age_grp) <> ''
GROUP BY age_grp
ORDER BY report_count DESC;

-- H. Reporter countries and source codes
SELECT reporter_country, COUNT(DISTINCT primaryid) AS report_count
FROM demo
WHERE reporter_country IS NOT NULL AND TRIM(reporter_country) <> ''
GROUP BY reporter_country
ORDER BY report_count DESC
LIMIT 10;

SELECT rpsr_cod, COUNT(DISTINCT primaryid) AS report_count
FROM reporter_source
GROUP BY rpsr_cod
ORDER BY report_count DESC
LIMIT 10;

-- I. Index-free Power BI summary views
CREATE OR REPLACE VIEW vw_drug_summary AS
SELECT drugname, COUNT(DISTINCT primaryid) AS report_count
FROM drug
WHERE drugname IS NOT NULL AND TRIM(drugname) <> ''
GROUP BY drugname;

CREATE OR REPLACE VIEW vw_reaction_summary AS
SELECT pt AS reaction, COUNT(DISTINCT primaryid) AS report_count
FROM reaction
WHERE pt IS NOT NULL AND TRIM(pt) <> ''
GROUP BY pt;

CREATE OR REPLACE VIEW vw_quarterly_trend AS
SELECT
    QUARTER(STR_TO_DATE(fda_dt, '%Y%m%d')) AS quarter,
    COUNT(DISTINCT primaryid) AS report_count
FROM demo
WHERE fda_dt IS NOT NULL AND TRIM(fda_dt) <> ''
GROUP BY QUARTER(STR_TO_DATE(fda_dt, '%Y%m%d'));

CREATE OR REPLACE VIEW vw_country_summary AS
SELECT reporter_country, COUNT(DISTINCT primaryid) AS case_count
FROM demo
WHERE reporter_country IS NOT NULL AND TRIM(reporter_country) <> ''
GROUP BY reporter_country;

CREATE OR REPLACE VIEW vw_sex_summary AS
SELECT
    CASE
        WHEN sex = 'M' THEN 'Male'
        WHEN sex = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS sex,
    COUNT(DISTINCT primaryid) AS case_count
FROM demo
GROUP BY sex;

CREATE OR REPLACE VIEW vw_age_summary AS
SELECT age_grp, COUNT(DISTINCT primaryid) AS case_count
FROM demo
WHERE age_grp IS NOT NULL AND TRIM(age_grp) <> ''
GROUP BY age_grp;

CREATE OR REPLACE VIEW vw_drug_reaction_pairs AS
SELECT
    d.drugname,
    r.pt AS reaction,
    COUNT(DISTINCT d.primaryid) AS case_count
FROM drug d
JOIN reaction r ON r.primaryid = d.primaryid
WHERE d.drugname IN (
    'DUPIXENT','PREDNISONE','ACETAMINOPHEN','ASPIRIN',
    'MOUNJARO','ZEPBOUND','ATORVASTATIN','METHOTREXATE',
    'GABAPENTIN','OMEPRAZOLE'
)
GROUP BY d.drugname, r.pt;

CREATE OR REPLACE VIEW vw_executive_summary AS
SELECT
    (SELECT COUNT(*) FROM demo) AS total_report_rows,
    (SELECT COUNT(DISTINCT caseid) FROM demo) AS unique_case_ids,
    (SELECT COUNT(DISTINCT primaryid)
     FROM outcome
     WHERE outc_cod IN ('DE','LT','DS','CA','HO','OT','RI')) AS serious_report_ids,
    ROUND(
        100.0 * (SELECT COUNT(DISTINCT primaryid)
                 FROM outcome
                 WHERE outc_cod IN ('DE','LT','DS','CA','HO','OT','RI'))
        / NULLIF((SELECT COUNT(*) FROM demo), 0),
        2
    ) AS serious_report_pct;

-- J. Latest-case serious outcome analysis
DROP TABLE IF EXISTS serious_case;
CREATE TABLE serious_case AS
SELECT DISTINCT l.caseid
FROM vw_latest_case_version l
JOIN outcome o ON o.primaryid = l.primaryid
WHERE o.outc_cod IN ('DE','LT','DS','CA','HO','OT','RI');

CREATE INDEX idx_serious_caseid ON serious_case(caseid);

DROP TABLE IF EXISTS drug_serious_summary;
CREATE TABLE drug_serious_summary AS
SELECT
    d.drugname,
    COUNT(DISTINCT d.caseid) AS total_cases,
    COUNT(DISTINCT s.caseid) AS serious_cases,
    ROUND(
        100.0 * COUNT(DISTINCT s.caseid)
        / NULLIF(COUNT(DISTINCT d.caseid), 0),
        2
    ) AS serious_outcome_pct
FROM prr_drug_case d
LEFT JOIN serious_case s ON s.caseid = d.caseid
GROUP BY d.drugname;

-- This section depends on PRR working tables from 03_prr_analysis.sql.
-- Interpret percentages as proportions of submitted reports, NOT drug risk.
SELECT drugname, total_cases, serious_cases, serious_outcome_pct
FROM drug_serious_summary
WHERE total_cases >= 500
ORDER BY serious_outcome_pct DESC
LIMIT 20;

-- K. Serious outcome summary by sex and age group (latest case version)
DROP TABLE IF EXISTS serious_demographic_summary;
CREATE TABLE serious_demographic_summary AS
SELECT
    'Sex' AS dimension,
    CASE
        WHEN d.sex = 'M' THEN 'Male'
        WHEN d.sex = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS category,
    COUNT(DISTINCT l.caseid) AS total_cases,
    COUNT(DISTINCT s.caseid) AS serious_cases,
    ROUND(
        100.0 * COUNT(DISTINCT s.caseid)
        / NULLIF(COUNT(DISTINCT l.caseid), 0),
        2
    ) AS serious_pct
FROM vw_latest_case_version l
JOIN demo d ON d.primaryid = l.primaryid
LEFT JOIN serious_case s ON s.caseid = l.caseid
GROUP BY
    CASE
        WHEN d.sex = 'M' THEN 'Male'
        WHEN d.sex = 'F' THEN 'Female'
        ELSE 'Unknown'
    END

UNION ALL

SELECT
    'Age Group' AS dimension,
    CASE
        WHEN d.age_grp IS NULL OR TRIM(d.age_grp) = '' THEN 'Unknown'
        ELSE d.age_grp
    END AS category,
    COUNT(DISTINCT l.caseid),
    COUNT(DISTINCT s.caseid),
    ROUND(
        100.0 * COUNT(DISTINCT s.caseid)
        / NULLIF(COUNT(DISTINCT l.caseid), 0),
        2
    )
FROM vw_latest_case_version l
JOIN demo d ON d.primaryid = l.primaryid
LEFT JOIN serious_case s ON s.caseid = l.caseid
GROUP BY
    CASE
        WHEN d.age_grp IS NULL OR TRIM(d.age_grp) = '' THEN 'Unknown'
        ELSE d.age_grp
    END;

SELECT *
FROM serious_demographic_summary
ORDER BY dimension, category;

-- NOTE: The supplied SQL file references drug_quarterly_counts and
-- vw_drug_quarterly_change, but does not include the original CREATE TABLE /
-- VIEW definition for drug_quarterly_counts. Those objects were created during
-- the project, but their full reproducible SQL is not present in the supplied
-- script. Add the verified original query before publishing that analysis.
