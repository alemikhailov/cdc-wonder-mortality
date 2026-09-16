# CDC WONDER Heart Disease Mortality Disparities Analysis

A SAS-based statistical analysis of heart disease mortality disparities
in the United States (2020–2024) using publicly available CDC WONDER data.
Examines differences in crude mortality rates across racial/ethnic groups,
sex, and US Census regions using descriptive statistics and Poisson
regression modeling.

## Data Source

CDC WONDER Underlying Cause of Death database (2018–2024, Single Race).
ICD-10 codes I00–I09, I11, I13, I20–I25, I26–I28, I30–I52 (Diseases of Heart).
Data accessed September 2026.

**Source:** https://wonder.cdc.gov/ucd-icd10-expanded.html

## Analysis Pipeline

The analysis consists of three SAS programs executed in sequence:

| Program | Purpose |
|---|---|
| `01_import.sas` | Import raw TSV export, convert variable types, exclude subtotals, create analysis-ready dataset (390 raw → 238 clean records) |
| `02_validate.sas` | Six validation checks: record count, duplicates, missing values, value ranges, CI consistency, rate recalculation |
| `03_analysis.sas` | Descriptive tables (PROC TABULATE), visualizations (PROC SGPLOT/SGPANEL), Poisson regression with rate ratios (PROC GENMOD) |

## Key Findings

- All race and sex effects were statistically significant (p < 0.0001)
- White populations had the highest crude mortality rates, largely attributable to older age distribution (rates are not age-adjusted — see Limitations in the report)
- Males had 25% higher heart disease mortality than females (rate ratio: 1.25)
- Heart disease mortality showed a small but significant decline over 2020–2024
- Two records were suppressed by CDC for small cell sizes (NHOPI females, Northeast)

## Validation Summary

| Check | Result |
|---|---|
| Record count (238 of 240 expected) | PASS |
| Duplicate records | PASS |
| Missing values in key variables | PASS |
| Value range checks | PASS |
| Confidence interval consistency | PASS |
| Rate recalculation verification | PASS |

## Project Structure


## Statistical Methods

- **Descriptive:** PROC FREQ, PROC MEANS, PROC TABULATE
- **Visualization:** PROC SGPLOT (grouped bar charts, trend lines), PROC SGPANEL (regional panels)
- **Modeling:** Poisson regression via PROC GENMOD with log link and log(Population) offset; ESTIMATE statements for exponentiated rate ratios with 95% CIs
- **Validation:** PROC SQL-based checks for completeness, consistency, and accuracy

## Environment

- SAS Studio (SAS OnDemand for Academics)
- Git / GitHub for version control

## Limitations

The most important limitation is that mortality rates in this analysis are crude (not age-adjusted). Because heart disease disproportionately affects older adults and racial/ethnic groups differ in age distribution, crude rates primarily reflect population age structure. See Section 6 of the full report for detailed discussion.