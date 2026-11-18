********************************************************************************
* RQ2 replication: local inequality as a moderator
*
* Run from the repository root. This script estimates the models underlying
* Tables 3 and 4 but does not construct or overwrite any tables.
********************************************************************************

version 18.0
clear all
set more off

capture confirm file "./data/CES_ACS_merged_long.dta"
if _rc {
    display as error "Run this do-file from the repository root after CES_ACS_Merge.do."
    exit 601
}

capture log close rq2
log using "./logs/Regressions_RQ2.log", text replace name(rq2)

use "./data/CES_ACS_merged_long.dta", clear
estimates clear

* Centering uses unweighted pooled-sample means, matching Build_Tables.do.
quietly summarize log_median_inc
generate double log_median_inc_c = log_median_inc - r(mean)
label variable log_median_inc_c "Log neighborhood income (mean centered)"

quietly summarize log_faminc
generate double log_faminc_c = log_faminc - r(mean)
label variable log_faminc_c "Log own income (mean centered)"

quietly summarize gini_s
generate double gini_s_c = gini_s - r(mean)
label variable gini_s_c "ZIP Gini (100x, mean centered)"

quietly summarize gini_s_c, detail
local gini_p25 = r(p25)
local gini_p50 = r(p50)
local gini_p75 = r(p75)
local gini_p90 = r(p90)

display as text "Centered Gini evaluation points:"
display as result "p25 = `gini_p25'; p50 = `gini_p50'; p75 = `gini_p75'; p90 = `gini_p90'"

********************************************************************************
* RQ2a / H3a: inequality moderates the neighborhood-income association
********************************************************************************

display as text _newline "RQ2a: neighborhood income by local Gini"
regress tax_pref ///
    c.log_median_inc_c##c.gini_s_c log_faminc_c ///
    i.year age i.gender i.educ i.race i.inputstate i.pid3 ///
    [pweight = commonweight_22], ///
    robust cluster(zipcode)
estimates store rq2_neighborhood_gini

display as text _newline "Implied neighborhood-income slopes at Gini percentiles"
margins, dydx(log_median_inc_c) ///
    at(gini_s_c = (`gini_p25' `gini_p50' `gini_p75' `gini_p90'))

********************************************************************************
* RQ2b / H3b: inequality moderates the own-income association
********************************************************************************

display as text _newline "RQ2b: own income by local Gini"
regress tax_pref ///
    c.log_faminc_c##c.gini_s_c log_median_inc_c ///
    i.year age i.gender i.educ i.race i.inputstate i.pid3 ///
    [pweight = commonweight_22], ///
    robust cluster(cid)
estimates store rq2_own_income_gini

display as text _newline "Implied own-income slopes at Gini percentiles"
margins, dydx(log_faminc_c) ///
    at(gini_s_c = (`gini_p25' `gini_p50' `gini_p75' `gini_p90'))

display as text _newline "Stored RQ2 estimates"
estimates dir

log close rq2
