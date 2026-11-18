********************************************************************************
* RQ1 replication: neighborhood income and tax preferences
*
* Run from the repository root. This script estimates the models underlying
* Tables 1 and 2 but does not construct or overwrite any tables.
********************************************************************************

version 18.0
clear all
set more off

capture confirm file "./data/CES_ACS_merged_long.dta"
if _rc {
    display as error "Run this do-file from the repository root after CES_ACS_Merge.do."
    exit 601
}

capture log close rq1
log using "./logs/Regressions_RQ1.log", text replace name(rq1)

use "./data/CES_ACS_merged_long.dta", clear
estimates clear

* The interaction model evaluates party-specific slopes at the pooled,
* unweighted mean of log neighborhood income.
quietly summarize log_median_inc
generate double log_median_inc_c = log_median_inc - r(mean)
label variable log_median_inc_c "Log neighborhood income (mean centered)"

********************************************************************************
* RQ1a: baseline neighborhood-income models
********************************************************************************

display as text _newline "RQ1a, Model 1: pooled reduced specification"
regress tax_pref log_median_inc log_faminc gini_s i.year ///
    [pweight = commonweight_22], ///
    robust cluster(cid)
estimates store rq1_reduced_pool

display as text _newline "RQ1a, Model 2: pooled full specification"
regress tax_pref ///
    log_median_inc log_faminc gini_s ///
    i.year age i.gender i.educ i.race i.inputstate ///
    [pweight = commonweight_22], ///
    robust cluster(cid)
estimates store rq1_full_pool

display as text _newline "RQ1a, Model 3: 2020 full specification"
regress tax_pref ///
    log_median_inc log_faminc gini_s ///
    age i.gender i.educ i.race i.inputstate ///
    [pweight = commonweight_22] if year == 2020, ///
    robust cluster(zipcode)
estimates store rq1_full_2020

display as text _newline "RQ1a, Model 4: 2022 full specification"
regress tax_pref ///
    log_median_inc log_faminc gini_s ///
    age i.gender i.educ i.race i.inputstate ///
    [pweight = commonweight_22] if year == 2022, ///
    robust cluster(zipcode)
estimates store rq1_full_2022

********************************************************************************
* RQ1b: partisan moderation
********************************************************************************

display as text _newline "RQ1b: neighborhood income by party identification"
regress tax_pref ///
    c.log_median_inc_c##i.pid3 log_faminc gini_s ///
    age i.gender i.educ i.race i.inputstate i.year ///
    [pweight = commonweight_22] if inlist(pid3, 1, 2, 3), ///
    robust cluster(cid)
estimates store rq1_party_interaction

display as text _newline "Test: Republican and Independent interaction coefficients are equal"
test 2.pid3#c.log_median_inc_c = 3.pid3#c.log_median_inc_c

display as text _newline "Implied neighborhood-income slopes by party"
margins pid3, dydx(log_median_inc_c)

display as text _newline "Stored RQ1 estimates"
estimates dir

log close rq1
