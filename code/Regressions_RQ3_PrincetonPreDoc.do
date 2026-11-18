********************************************************************************
* CODE SAMPLE: Asymmetric relative-income models
* Author: Ulrick Mitton
*
* Accompanying paper: "Relative Income and Tax Progressivity Preferences:
* Evidence from Local Comparisons" (M.A. thesis draft, September 2026)
*
* This do-file is drawn from a larger Stata replication workflow.
*
* It estimates the piecewise models underlying Tables 7 and 8 and the marginal
* slopes reported in the accompanying text.
*
* The input is a respondent-wave panel constructed by merging 2020 and 2022
* CES data with ZIP-level ACS measures.
*
* Data construction is performed separately.
*
* Required input: ./data/CES_ACS_merged_long.dta
* Run from the project root.
********************************************************************************

version 18.0
clear all
set more off

capture mkdir "./logs"

capture confirm file "./data/CES_ACS_merged_long.dta"
if _rc {
    display as error "Run this do-file from the repository root after CES_ACS_Merge.do."
    exit 601
}

capture log close rq3_sample
log using "./logs/Regressions_RQ3_PrincetonPreDoc.log", ///
    text replace name(rq3_sample)

use "./data/CES_ACS_merged_long.dta", clear
estimates clear

********************************************************************************
* Piecewise variables and evaluation points
********************************************************************************

* Median kink: log relative income is zero when family income equals the
* matched ZIP-code median. No threshold-discontinuity indicator is included.
generate double below_dist = log_rel_inc * (log_rel_inc < 0)
generate double above_dist = log_rel_inc * (log_rel_inc >= 0)
label variable below_dist "Below-median distance"
label variable above_dist "Above-median distance"

* Alternative kink: pooled-sample 25th percentile of log relative income.
quietly summarize log_rel_inc, detail
local p25_rel = r(p25)
generate double below_dist_p25 = ///
    (log_rel_inc - `p25_rel') * (log_rel_inc < `p25_rel')
generate double above_dist_p25 = ///
    (log_rel_inc - `p25_rel') * (log_rel_inc >= `p25_rel')
label variable below_dist_p25 "Below-P25 distance"
label variable above_dist_p25 "Above-P25 distance"

* RQ3b evaluates position slopes at the pooled, unweighted mean of ZIP Gini.
quietly summarize gini_s
generate double gini_s_c = gini_s - r(mean)
label variable gini_s_c "ZIP Gini (100x, mean centered)"

quietly summarize gini_s_c, detail
local gini_p25 = r(p25)
local gini_p50 = r(p50)
local gini_p75 = r(p75)
local gini_p90 = r(p90)

display as text "P25 kink in log relative income = " as result `p25_rel'
display as text "Centered Gini evaluation points:"
display as result "p25 = `gini_p25'; p50 = `gini_p50'; p75 = `gini_p75'; p90 = `gini_p90'"

********************************************************************************
* RQ3a: are the below- and above-threshold slopes different?
********************************************************************************

* RQ3a, Model 1: parsimonious median-kink specification
regress tax_pref below_dist above_dist log_median_inc ///
    [pweight = commonweight_22], ///
    vce(cluster cid)
estimates store rq3_median_parsimonious

* Slope-equality test, H0: below-median slope = above-median slope
test below_dist = above_dist

* RQ3a, Model 2: full median-kink specification
regress tax_pref below_dist above_dist ///
    log_median_inc gini_s i.pid3 ///
    i.year age i.gender i.educ i.race i.inputstate ///
    [pweight = commonweight_22], ///
    vce(cluster cid)
estimates store rq3_median_full

* Slope-equality test, H0: below-median slope = above-median slope
test below_dist = above_dist

* RQ3a, Model 3: full P25-kink specification
regress tax_pref below_dist_p25 above_dist_p25 ///
    log_median_inc gini_s i.pid3 ///
    i.year age i.gender i.educ i.race i.inputstate ///
    [pweight = commonweight_22], ///
    vce(cluster cid)
estimates store rq3_p25_full

* Slope-equality test, H0: below-P25 slope = above-P25 slope
test below_dist_p25 = above_dist_p25

********************************************************************************
* RQ3b: does local inequality moderate the piecewise position slopes?
********************************************************************************

* RQ3b, Model 1: median-kink slopes by local Gini
regress tax_pref ///
    c.below_dist c.above_dist c.gini_s_c ///
    c.below_dist#c.gini_s_c c.above_dist#c.gini_s_c ///
    log_median_inc i.pid3 ///
    i.year age i.gender i.educ i.race i.inputstate ///
    [pweight = commonweight_22], ///
    vce(cluster cid)
estimates store rq3_median_gini

* RQ3b, Model 2: P25-kink slopes by local Gini
regress tax_pref ///
    c.below_dist_p25 c.above_dist_p25 c.gini_s_c ///
    c.below_dist_p25#c.gini_s_c c.above_dist_p25#c.gini_s_c ///
    log_median_inc i.pid3 ///
    i.year age i.gender i.educ i.race i.inputstate ///
    [pweight = commonweight_22], ///
    vce(cluster cid)
estimates store rq3_p25_gini

* Implied below-P25 slopes at Gini percentiles
margins, dydx(below_dist_p25) ///
    at(gini_s_c = (`gini_p25' `gini_p50' `gini_p75' `gini_p90'))

* Implied above-P25 slopes at Gini percentiles
margins, dydx(above_dist_p25) ///
    at(gini_s_c = (`gini_p25' `gini_p50' `gini_p75' `gini_p90'))

* Stored RQ3 estimates
estimates dir

log close rq3_sample
