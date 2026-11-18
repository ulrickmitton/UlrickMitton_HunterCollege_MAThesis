# Stata workflow

Run all do-files from the repository root, the directory containing `code`,
`data`, `logs`, and `results`.

## Analysis sequence

1. `ACS_ZIP_Prep_API.do` retrieves and prepares the ACS ZIP-code measures.
2. `CES_ACS_Merge.do` constructs `data/CES_ACS_merged_long.dta`, the analysis
   dataset used throughout the paper.
3. `Summary_Statistics.do` produces the descriptive statistics and data figure.
4. `Run_Core_Regressions.do` runs the three replication scripts below.
5. `Build_Tables.do` estimates the same paper specifications and formats the
   publication tables. Run it only when the LaTeX table files need rebuilding.

## Regression-only replication

The regression scripts use Stata's built-in estimation and post-estimation
commands. They do not invoke `esttab`, write LaTeX, or change anything under
`results`.

- `Regressions_RQ1.do`: pooled and wave-specific baseline models plus partisan
  moderation.
- `Regressions_RQ2.do`: moderation of neighborhood- and own-income associations
  by local inequality, including marginal slopes at Gini percentiles.
- `Regressions_RQ3.do`: continuous median- and P25-kink models, slope-equality
  tests, inequality interactions, and the reported P25 marginal slopes.
- `Run_Core_Regressions.do`: runs all three scripts in sequence.

`Regressions_RQ3_PrincetonPreDoc.do` is a self-contained code-sample version of
the RQ3 analysis. It writes a separate log so that running it does not overwrite
the main replication log.

Each script reloads the analysis dataset, uses the 2020--2022 CES panel weight
stored as `commonweight_22`, and writes its own plain-text log under `logs`.
Pooled models cluster by respondent unless otherwise specified. The RQ1
year-specific models and RQ2 neighborhood-income interaction cluster by ZIP
code, matching the paper's table notes.

Centering and percentile calculations use the unweighted pooled analysis data,
matching `Build_Tables.do`. The RQ3 specifications are continuous at their kink
and contain no threshold-discontinuity indicator.
