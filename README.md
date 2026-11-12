# FDA AEMS – Drug Safety Analytics | SQL Scripts

These scripts organize the SQL supplied for the FDA AEMS / FAERS adverse-event analytics portfolio project.

## Folder structure

- `01_data_cleaning/` – staging schemas, import commands, de-duplication, latest case version, indexes.
- `02_analysis/` – exploratory analysis, KPIs, demographics, trends, and Power BI views.
- `03_prr_analysis/` – suspect-drug/reaction datasets, PRR, Yates-corrected chi-square screening.
- `04_validation/` – row-count, duplicate, latest-case, PRR and index checks.

## Execution order

1. `01_data_cleaning/01_data_cleaning_and_latest_case.sql`
2. `03_prr_analysis/03_prr_signal_analysis.sql`
3. `02_analysis/02_exploratory_analysis_and_powerbi_views.sql`
4. `04_validation/04_data_quality_validation.sql`

The analysis script's serious-by-drug section uses `prr_drug_case`, created by step 2. Run the PRR script before the analysis script.

## Before running

- Requires MySQL 8.
- Download the FDA quarterly files separately.
- Update the `LOAD DATA INFILE` paths in the cleaning script to your local import directory.
- Ensure MySQL `secure_file_priv` permits that directory and the MySQL service account can read the files.
- The script uses the source project's Q1–Q4 2025 filenames. Change names only if your downloaded source files differ.
- Do not upload raw FDA data, database credentials, or local personal paths to the repository.

## Important reproducibility note

The original uploaded SQL references `drug_quarterly_counts` and `vw_drug_quarterly_change`, but it does not contain the complete SQL that creates `drug_quarterly_counts`. The quarterly drug trend result was discussed in the project history, but the original creation query was not included in the supplied SQL file. That analysis is therefore not represented as a runnable script here; add the verified original query if it is recovered.

## Interpretation limitations

- FDA adverse-event reports do not establish that a drug caused an event.
- Report counts are not incidence rates or patient-level risk.
- PRR and chi-square are screening methods that generate hypotheses, not confirmed safety conclusions.
- Serious outcome percentages describe proportions within submitted reports, not causal drug risk.
- Keep source-coded age and reporter-source values unless official definitions are checked.

## Verified project figures recorded during the work

- Clean DEMO report rows: 1,617,313
- Distinct case IDs: 1,469,305
- Latest case-version rows: 1,469,305
- Latest-version serious cases: 823,213

These figures are project-run results, not guaranteed outputs for a different dataset release or modified import.
