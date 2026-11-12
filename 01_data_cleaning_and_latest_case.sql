/*
FDA AEMS – Drug Safety Analytics
01 | Data cleaning and preparation
MySQL 8

IMPORTANT:
- This script is based on the SQL supplied by the project owner.
- Download FDA quarterly files separately; do not commit raw data to GitHub.
- Update the file paths below to match your own MySQL secure_file_priv directory.
- Run the CREATE TABLE statements once. For a fresh reload, TRUNCATE staging
  tables before loading; do not rerun LOAD DATA without checking row counts.
*/

CREATE DATABASE IF NOT EXISTS fda_safety_analytics;
USE fda_safety_analytics;

-- 1. Create staging tables
CREATE TABLE IF NOT EXISTS stg_demo (
    primaryid BIGINT,
    caseid BIGINT,
    caseversion INT,
    i_f_code VARCHAR(5),
    event_dt VARCHAR(20),
    mfr_dt VARCHAR(20),
    init_fda_dt VARCHAR(20),
    fda_dt VARCHAR(20),
    rept_cod VARCHAR(20),
    auth_num VARCHAR(255),
    mfr_num VARCHAR(255),
    mfr_sndr VARCHAR(255),
    lit_ref TEXT,
    age VARCHAR(30),
    age_cod VARCHAR(10),
    age_grp VARCHAR(20),
    sex VARCHAR(10),
    e_sub VARCHAR(10),
    wt VARCHAR(30),
    wt_cod VARCHAR(10),
    rept_dt VARCHAR(20),
    to_mfr VARCHAR(10),
    occp_cod VARCHAR(10),
    reporter_country VARCHAR(255),
    occr_country VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS stg_drug (
    primaryid BIGINT,
    caseid BIGINT,
    drug_seq INT,
    role_cod VARCHAR(10),
    drugname VARCHAR(500),
    prod_ai VARCHAR(500),
    val_vbm VARCHAR(10),
    route VARCHAR(100),
    dose_vbm VARCHAR(500),
    cum_dose_chr VARCHAR(100),
    cum_dose_unit VARCHAR(50),
    dechal VARCHAR(10),
    rechal VARCHAR(10),
    lot_num VARCHAR(100),
    exp_dt VARCHAR(20),
    nda_num VARCHAR(50),
    dose_amt VARCHAR(100),
    dose_unit VARCHAR(50),
    dose_form VARCHAR(100),
    dose_freq VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS stg_indi (
    primaryid BIGINT,
    caseid BIGINT,
    indi_drug_seq INT,
    indi_pt VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS stg_outc (
    primaryid BIGINT,
    caseid BIGINT,
    outc_cod VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS stg_reac (
    primaryid BIGINT,
    caseid BIGINT,
    pt VARCHAR(500),
    drug_rec_act VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS stg_rpsr (
    primaryid BIGINT,
    caseid BIGINT,
    rpsr_cod VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS stg_ther (
    primaryid BIGINT,
    caseid BIGINT,
    dsg_drug_seq INT,
    start_dt VARCHAR(20),
    end_dt VARCHAR(20),
    dur VARCHAR(50),
    dur_cod VARCHAR(10)
);

-- 2. Check MySQL import configuration before loading
SHOW VARIABLES LIKE 'secure_file_priv';
SHOW VARIABLES LIKE 'local_infile';

-- 3. Load the four quarterly files into each staging table.
-- Replace the sample paths if your import directory is different.
-- These commands expect FDA pipe/dollar-delimited TXT files as in the source project.

-- DEMO
LOAD DATA INFILE 'D:/MySQLUploads/DEMO25Q1.TXT' INTO TABLE stg_demo
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/DEMO25Q2.TXT' INTO TABLE stg_demo
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/DEMO25Q3.TXT' INTO TABLE stg_demo
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/DEMO25Q4.TXT' INTO TABLE stg_demo
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;

-- DRUG
SET SESSION sql_mode = '';
LOAD DATA INFILE 'D:/MySQLUploads/DRUG25Q1.TXT' INTO TABLE stg_drug
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/DRUG25Q2.TXT' INTO TABLE stg_drug
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/DRUG25Q3.TXT' INTO TABLE stg_drug
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/DRUG25Q4.TXT' INTO TABLE stg_drug
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

-- INDI
LOAD DATA INFILE 'D:/MySQLUploads/INDI25Q1.TXT' INTO TABLE stg_indi
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/INDI25Q2.TXT' INTO TABLE stg_indi
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/INDI25Q3.TXT' INTO TABLE stg_indi
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/INDI25Q4.TXT' INTO TABLE stg_indi
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;

-- OUTC
LOAD DATA INFILE 'D:/MySQLUploads/OUTC25Q1.TXT' INTO TABLE stg_outc
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/OUTC25Q2.TXT' INTO TABLE stg_outc
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/OUTC25Q3.TXT' INTO TABLE stg_outc
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/OUTC25Q4.TXT' INTO TABLE stg_outc
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;

-- REAC
LOAD DATA INFILE 'D:/MySQLUploads/REAC25Q1.TXT' INTO TABLE stg_reac
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/REAC25Q2.TXT' INTO TABLE stg_reac
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/REAC25Q3.TXT' INTO TABLE stg_reac
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/REAC25Q4.TXT' INTO TABLE stg_reac
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;

-- RPSR
LOAD DATA INFILE 'D:/MySQLUploads/RPSR25Q1.TXT' INTO TABLE stg_rpsr
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/RPSR25Q2.TXT' INTO TABLE stg_rpsr
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/RPSR25Q3.TXT' INTO TABLE stg_rpsr
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/RPSR25Q4.TXT' INTO TABLE stg_rpsr
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;

-- THER
LOAD DATA INFILE 'D:/MySQLUploads/THER25Q1.TXT' INTO TABLE stg_ther
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/THER25Q2.TXT' INTO TABLE stg_ther
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/THER25Q3.TXT' INTO TABLE stg_ther
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;
LOAD DATA INFILE 'D:/MySQLUploads/THER25Q4.TXT' INTO TABLE stg_ther
FIELDS TERMINATED BY '$' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;

-- 4. Verify staging row counts after loading
SELECT 'stg_demo' AS table_name, COUNT(*) AS row_count FROM stg_demo
UNION ALL SELECT 'stg_drug', COUNT(*) FROM stg_drug
UNION ALL SELECT 'stg_indi', COUNT(*) FROM stg_indi
UNION ALL SELECT 'stg_outc', COUNT(*) FROM stg_outc
UNION ALL SELECT 'stg_reac', COUNT(*) FROM stg_reac
UNION ALL SELECT 'stg_rpsr', COUNT(*) FROM stg_rpsr
UNION ALL SELECT 'stg_ther', COUNT(*) FROM stg_ther;

-- 5. Create de-duplicated analytical tables.
-- DISTINCT removes exact duplicate rows; it does not select the latest case version.
CREATE TABLE IF NOT EXISTS demo AS SELECT DISTINCT * FROM stg_demo;
CREATE TABLE IF NOT EXISTS drug AS SELECT DISTINCT * FROM stg_drug;
CREATE TABLE IF NOT EXISTS indication AS SELECT DISTINCT * FROM stg_indi;
CREATE TABLE IF NOT EXISTS outcome AS SELECT DISTINCT * FROM stg_outc;
CREATE TABLE IF NOT EXISTS reaction AS SELECT DISTINCT * FROM stg_reac;
CREATE TABLE IF NOT EXISTS reporter_source AS SELECT DISTINCT * FROM stg_rpsr;
CREATE TABLE IF NOT EXISTS therapy AS SELECT DISTINCT * FROM stg_ther;

-- 6. Create a latest-version view: one record per caseid.
CREATE OR REPLACE VIEW vw_latest_case_version AS
SELECT primaryid, caseid, caseversion, fda_dt
FROM (
    SELECT
        d.primaryid,
        d.caseid,
        d.caseversion,
        d.fda_dt,
        ROW_NUMBER() OVER (
            PARTITION BY d.caseid
            ORDER BY
                CAST(NULLIF(d.caseversion, '') AS UNSIGNED) DESC,
                NULLIF(d.fda_dt, '') DESC,
                CAST(d.primaryid AS UNSIGNED) DESC
        ) AS rn
    FROM demo d
    WHERE d.caseid IS NOT NULL
      AND TRIM(d.caseid) <> ''
) AS ranked
WHERE rn = 1;

-- 7. Useful indexes for common joins and date filtering.
CREATE INDEX idx_demo_primaryid ON demo(primaryid);
CREATE INDEX idx_demo_fda_dt ON demo(fda_dt);
CREATE INDEX idx_drug_primaryid ON drug(primaryid);
CREATE INDEX idx_reaction_primaryid ON reaction(primaryid);
CREATE INDEX idx_outcome_primaryid ON outcome(primaryid);
