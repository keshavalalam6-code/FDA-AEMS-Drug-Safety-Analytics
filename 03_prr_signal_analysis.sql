/*
FDA AEMS – Drug Safety Analytics
03 | PRR signal analysis
MySQL 8
Run after 01_data_cleaning.sql.
PRR is a disproportionality screening method, not proof of causation.
*/

USE fda_safety_analytics;

-- 1. Build latest-case drug dataset using primary and secondary suspect drugs.
DROP TABLE IF EXISTS prr_drug_case;
CREATE TABLE prr_drug_case AS
SELECT DISTINCT
    l.caseid,
    TRIM(d.drugname) AS drugname
FROM vw_latest_case_version l
JOIN drug d ON d.primaryid = l.primaryid
WHERE d.role_cod IN ('PS', 'SS')
  AND d.drugname IS NOT NULL
  AND TRIM(d.drugname) <> '';

CREATE INDEX idx_prr_drug_caseid ON prr_drug_case(caseid);
CREATE INDEX idx_prr_drug_name ON prr_drug_case(drugname(100));

-- 2. Build latest-case reaction dataset.
DROP TABLE IF EXISTS prr_reaction_case;
CREATE TABLE prr_reaction_case AS
SELECT DISTINCT
    l.caseid,
    TRIM(r.pt) AS reaction
FROM vw_latest_case_version l
JOIN reaction r ON r.primaryid = l.primaryid
WHERE r.pt IS NOT NULL
  AND TRIM(r.pt) <> '';

CREATE INDEX idx_prr_reaction_caseid ON prr_reaction_case(caseid);
CREATE INDEX idx_prr_reaction_name ON prr_reaction_case(reaction(100));

-- 3. Check working dataset sizes.
SELECT 'Drug' AS dataset,
       COUNT(*) AS rows_count,
       COUNT(DISTINCT caseid) AS cases_count
FROM prr_drug_case
UNION ALL
SELECT 'Reaction',
       COUNT(*),
       COUNT(DISTINCT caseid)
FROM prr_reaction_case;

-- 4. Count drug–reaction co-occurrences (A); retain pairs with at least 3 cases.
DROP TABLE IF EXISTS prr_pair_a;
CREATE TABLE prr_pair_a AS
SELECT
    d.drugname,
    r.reaction,
    COUNT(DISTINCT d.caseid) AS a
FROM prr_drug_case d
JOIN prr_reaction_case r ON r.caseid = d.caseid
GROUP BY d.drugname, r.reaction
HAVING COUNT(DISTINCT d.caseid) >= 3;

SELECT COUNT(*) AS qualifying_pairs FROM prr_pair_a;

SELECT drugname, reaction, a
FROM prr_pair_a
ORDER BY a DESC
LIMIT 10;

-- 5. Calculate the 2x2 contingency table and PRR.
-- A = drug + reaction; B = drug without reaction;
-- C = other reports with reaction; D = other reports without reaction.
DROP TABLE IF EXISTS prr_results;
CREATE TABLE prr_results AS
WITH drug_totals AS (
    SELECT drugname, COUNT(DISTINCT caseid) AS drug_cases
    FROM prr_drug_case
    GROUP BY drugname
),
reaction_totals AS (
    SELECT reaction, COUNT(DISTINCT caseid) AS reaction_cases
    FROM prr_reaction_case
    GROUP BY reaction
),
total_count AS (
    SELECT COUNT(*) AS total_cases
    FROM vw_latest_case_version
),
contingency_table AS (
    SELECT
        p.drugname,
        p.reaction,
        p.a,
        dt.drug_cases - p.a AS b,
        rt.reaction_cases - p.a AS c,
        tc.total_cases - dt.drug_cases - rt.reaction_cases + p.a AS d,
        dt.drug_cases,
        rt.reaction_cases
    FROM prr_pair_a p
    JOIN drug_totals dt ON dt.drugname = p.drugname
    JOIN reaction_totals rt ON rt.reaction = p.reaction
    CROSS JOIN total_count tc
)
SELECT
    x.*,
    CASE
        WHEN (x.a + x.b) > 0 AND (x.c + x.d) > 0
        THEN ROUND(
            (x.a / (x.a + x.b)) /
            (x.c / NULLIF(x.c + x.d, 0)),
            4
        )
        ELSE NULL
    END AS prr
FROM contingency_table x;

-- 6. Initial candidate signals: PRR >= 2 and at least 3 co-reports.
SELECT drugname, reaction, a, b, c, d, prr
FROM prr_results
WHERE a >= 3 AND prr >= 2
ORDER BY prr DESC
LIMIT 20;

-- 7. Yates-corrected chi-square screening view.
CREATE OR REPLACE VIEW vw_prr_screened_candidates AS
SELECT *
FROM (
    SELECT
        p.*,
        ROUND(
            CASE
                WHEN (a+b) > 0
                 AND (c+d) > 0
                 AND (a+c) > 0
                 AND (b+d) > 0
                THEN
                    (
                        CAST(a+b+c+d AS DECIMAL(30,0))
                        * POW(
                            GREATEST(
                                ABS(
                                    CAST(a AS DECIMAL(30,0)) * CAST(d AS DECIMAL(30,0))
                                    - CAST(b AS DECIMAL(30,0)) * CAST(c AS DECIMAL(30,0))
                                )
                                - CAST(a+b+c+d AS DECIMAL(30,0))/2,
                                0
                            ),
                            2
                        )
                    )
                    /
                    (
                        CAST(a+b AS DECIMAL(30,0))
                        * CAST(c+d AS DECIMAL(30,0))
                        * CAST(a+c AS DECIMAL(30,0))
                        * CAST(b+d AS DECIMAL(30,0))
                    )
                ELSE NULL
            END,
            2
        ) AS chi_square_yates
    FROM prr_results p
) AS scored
WHERE a >= 3
  AND prr >= 2
  AND chi_square_yates >= 4;

-- 8. Review screened candidates.
SELECT
    drugname, reaction, a, b, c, d,
    prr, chi_square_yates
FROM vw_prr_screened_candidates
ORDER BY a DESC, prr DESC
LIMIT 20;

-- More stable shortlist: require at least 100 co-reports.
SELECT
    drugname,
    reaction,
    a AS case_count,
    prr,
    chi_square_yates
FROM vw_prr_screened_candidates
WHERE a >= 100
ORDER BY prr DESC
LIMIT 20;

-- Detailed interpretation columns for shortlisted pairs.
SELECT
    drugname,
    reaction,
    a AS cases_with_drug_and_reaction,
    b AS drug_without_reaction,
    c AS comparison_cases_with_reaction,
    d AS comparison_cases_without_reaction,
    drug_cases,
    reaction_cases,
    prr,
    chi_square_yates
FROM vw_prr_screened_candidates
WHERE a >= 100 AND c >= 20
ORDER BY prr DESC
LIMIT 20;

-- 9. Additional indexes used during query optimization.
CREATE INDEX idx_prr_reaction_name_case
ON prr_reaction_case (reaction(100), caseid);

CREATE INDEX idx_prr_drug_name_case
ON prr_drug_case (drugname(100), caseid);

ANALYZE TABLE prr_drug_case, prr_reaction_case;

-- Query plan / runtime investigation example.
EXPLAIN
SELECT COUNT(DISTINCT d.caseid) AS case_count
FROM prr_drug_case d
JOIN prr_reaction_case r ON r.caseid = d.caseid
WHERE d.drugname = 'DUPIXENT'
  AND r.reaction = 'Pruritus';

EXPLAIN ANALYZE
SELECT COUNT(DISTINCT d.caseid)
FROM prr_drug_case d
JOIN prr_reaction_case r ON r.caseid = d.caseid
WHERE d.drugname = 'DUPIXENT'
  AND r.reaction = 'Pruritus';
