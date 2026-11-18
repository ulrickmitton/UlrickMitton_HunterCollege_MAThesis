# Reproducibility notes

## Software

- Stata 18
- `estout` package for `esttab` output (`ssc install estout`)
- A Census Data API key supplied through the `CENSUS_API_KEY` environment
  variable for `code/ACS_ZIP_Prep_API.do`

The scripts use relative paths and should be run from the repository root.

## Data setup

Follow [`data/README.md`](data/README.md) to obtain the CES panel input. The ACS
inputs are downloaded through the Census Data API by
`code/ACS_ZIP_Prep_API.do`.

The merge script expects the CES input at:

```text
data/CES_2020_2024_Panel/merged_recontact_2024_vv.dta
```

It produces the analytic file used by the remaining scripts:

```text
data/CES_ACS_merged_long.dta
```

## Execution order

Run the following from Stata with the repository as the current working directory:

```text
do code/ACS_ZIP_Prep_API.do
do code/CES_ACS_Merge.do
do code/Summary_Statistics.do
do code/Run_Core_Regressions.do
do code/Build_Tables.do
```

The regression-only scripts write plain-text logs under `logs/`. Generated
figures and tables overwrite the checked-in reference outputs.

## Scope

The repository contains code and selected generated outputs, but not the
respondent-level survey data. Results may vary slightly across Stata or package
versions because of formatting or numerical precision.
