# Data access

Respondent-level survey data are not distributed in this repository.

## Cooperative Election Study

The analysis uses the 2020 and 2022 waves of the Cooperative Election Study
(CES) panel. CES responses and documentation are available through the
[CES data portal](https://cces.gov.harvard.edu/explore).

After obtaining the panel file, place it at:

```text
data/CES_2020_2024_Panel/merged_recontact_2024_vv.dta
```

If the downloaded file uses a different name or format, update the input line in
`code/CES_ACS_Merge.do` or save a local Stata copy at the path above.

## American Community Survey

ZIP Code Tabulation Area income and inequality measures come from the 2021 and
2023 American Community Survey five-year estimates. The preparation script
retrieves the required tables through the
[Census Data API](https://www.census.gov/data/developers/data-sets/acs-5year.html).

Run `code/ACS_ZIP_Prep_API.do` before the merge script.
Set your Census API key in the `CENSUS_API_KEY` environment variable first; the
key is deliberately not stored in the repository.

## Generated data

`code/CES_ACS_Merge.do` creates `data/CES_ACS_merged_long.dta`, the analytic file
used by the summary-statistics, regression, and table-building scripts. Generated
and source data files are ignored by Git to prevent accidental redistribution.

Users are responsible for following the source providers' current terms and
citation requirements.
