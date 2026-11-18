****** CES_ACS_Merge_Final
****** Last Edit: 07/22/2026


version 18.0
capture mkdir "./logs"
log using "./logs/CES_AES_Merge", replace
capture confirm file "./data/CES_2020_2024_Panel/merged_recontact_2024_vv.dta"
if _rc {
	display as error "Place the CES panel file under data/CES_2020_2024_Panel before running this script."
	exit 601
}
use "./data/CES_2020_2024_Panel/merged_recontact_2024_vv.dta", clear


* Adjustments to CES variables
	rename CC20_422r tax_pref_20
	rename CC22_422r tax_pref_22
	rename gender gender_20
	drop if faminc_new_20 == 97 | faminc_new_22 == 97
	drop if tax_pref_20 ==. | tax_pref_22==.


* Convert numeric ZIP to string with leading zeros
	tostring lookupzip_20, generate(zipcode_20) format(%05.0f)
	tostring lookupzip_22, generate(zipcode_22) format(%05.0f)
	drop lookupzip_20 lookupzip_22


* Family income midpoints and CPI deflation
* 2022 midpoints are deflated to 2020 dollars using BLS CPI-U annual averages
* CPI-U: 2020 = 258.811, 2022 = 292.655  (source: BLS series CUUR0000SA0

	* BLS CPI-U annual averages, series CUUR0000SA0
	local cpi_2020 = 258.811
	local cpi_2021 = 270.970
	local cpi_2022 = 292.655
	local cpi_2023 = 304.702

	foreach yr in 20 22 {
		generate faminc_mid_`yr' = .
		replace faminc_mid_`yr' = 5000    if faminc_new_`yr' == 1
		replace faminc_mid_`yr' = 15000   if faminc_new_`yr' == 2
		replace faminc_mid_`yr' = 25000   if faminc_new_`yr' == 3
		replace faminc_mid_`yr' = 35000   if faminc_new_`yr' == 4
		replace faminc_mid_`yr' = 45000   if faminc_new_`yr' == 5
		replace faminc_mid_`yr' = 55000   if faminc_new_`yr' == 6
		replace faminc_mid_`yr' = 65000   if faminc_new_`yr' == 7
		replace faminc_mid_`yr' = 75000   if faminc_new_`yr' == 8
		replace faminc_mid_`yr' = 90000   if faminc_new_`yr' == 9
		replace faminc_mid_`yr' = 110000  if faminc_new_`yr' == 10
		replace faminc_mid_`yr' = 135000  if faminc_new_`yr' == 11
		replace faminc_mid_`yr' = 175000  if faminc_new_`yr' == 12
		replace faminc_mid_`yr' = 225000  if faminc_new_`yr' == 13
		replace faminc_mid_`yr' = 300000  if faminc_new_`yr' == 14
		replace faminc_mid_`yr' = 425000  if faminc_new_`yr' == 15
		replace faminc_mid_`yr' = 600000  if faminc_new_`yr' == 16
	}

	replace faminc_mid_22 = faminc_mid_22 * ///
    (`cpi_2020' / `cpi_2022')

	generate log_faminc_20 = log(faminc_mid_20)
	generate log_faminc_22 = log(faminc_mid_22)

* Merge 2020 ACS data
	merge m:1 zipcode_20 using "./data/ACS/acs_2021_merged.dta", ///
        keepusing(median_inc_20 median_inc_20_moe gini_20 gini_20_moe pov_rate_20 pov_rate_20_moe)
	keep if _merge == 1 | _merge == 3
	drop _merge
	count if missing(median_inc_20)
	list caseid_20 zipcode_20 if missing(median_inc_20)

* Merge 2022 ACS data
	merge m:1 zipcode_22 using "./data/ACS/acs_2023_merged.dta", ///
        keepusing(median_inc_22 median_inc_22_moe n_obs gini_22 gini_22_moe pov_rate_22 pov_rate_22_moe)
	keep if _merge == 1 | _merge == 3
	drop _merge n_obs
	count if missing(median_inc_22)
	list caseid_22 zipcode_22 if missing(median_inc_22)


	* Convert ACS dollar estimates to 2020 dollars
	replace median_inc_20 = median_inc_20 * ///
		(`cpi_2020' / `cpi_2021')

	replace median_inc_22 = median_inc_22 * ///
		(`cpi_2020' / `cpi_2023')
* Generating log median income
	generate log_median_inc_20 = log(median_inc_20)
	generate log_median_inc_22 = log(median_inc_22)


* Relative income position
* rel_inc    = faminc_mid / median_inc  (ratio of own income to ZIP median)
* log_rel_inc = log_faminc - log_median_inc  (log relative income; = log(rel_inc))
* rel_inc_cat = 4-category position (below 0.5x, 0.5–1x, 1–2x, 2x+ median)
	foreach yr in 20 22 {
		generate rel_inc_`yr'     = faminc_mid_`yr' / median_inc_`yr'
		generate log_rel_inc_`yr' = log_faminc_`yr' - log_median_inc_`yr'

		generate rel_inc_cat_`yr' = .
		replace  rel_inc_cat_`yr' = 1 if rel_inc_`yr' <  0.5
		replace  rel_inc_cat_`yr' = 2 if rel_inc_`yr' >= 0.5 & rel_inc_`yr' <  1.0
		replace  rel_inc_cat_`yr' = 3 if rel_inc_`yr' >= 1.0 & rel_inc_`yr' <  2.0
		replace  rel_inc_cat_`yr' = 4 if rel_inc_`yr' >= 2.0 & !missing(rel_inc_`yr')
	}

	label define rel_inc_cat_lbl 1 "Below 0.5x median" 2 "0.5–1.0x" 3 "1.0–2.0x" 4 "2.0x+"
	label values rel_inc_cat_20 rel_inc_cat_lbl
	label values rel_inc_cat_22 rel_inc_cat_lbl

* Mover indicator: ZIP changed between 2020 and 2022 (time-invariant — not reshaped)
	generate mover = (zipcode_20 != zipcode_22)
	label variable mover "=1 if respondent changed ZIP between 2020 and 2022"


* Rename variables to align year-suffix position before reshape
* MOE vars: median_inc_20_moe → median_inc_moe_20  (so stub = median_inc_moe_)
	rename median_inc_20_moe  median_inc_moe_20
	rename median_inc_22_moe  median_inc_moe_22
	rename gini_20_moe        gini_moe_20
	rename gini_22_moe        gini_moe_22
	rename pov_rate_20_moe    pov_rate_moe_20
	rename pov_rate_22_moe    pov_rate_moe_22
* Note: 2022 uses a 4-category gender variable; renamed to align stub with 2020
	rename gender4_22 gender_22


* Reshape wide → long
	reshape long tax_pref_ faminc_new_ faminc_mid_ log_faminc_ ///
		zipcode_ median_inc_ median_inc_moe_ gini_ gini_moe_ log_median_inc_ ///
		pov_rate_ pov_rate_moe_ ///
		rel_inc_ log_rel_inc_ rel_inc_cat_ ///
		pid3_ ///
		birthyr_ gender_ educ_ race_ inputstate_, ///
		i(cid) j(wave)

* Remove trailing underscores from reshaped variable names
	rename (tax_pref_ faminc_new_ faminc_mid_ log_faminc_ zipcode_ ///
		median_inc_ median_inc_moe_ gini_ gini_moe_ log_median_inc_ ///
		pov_rate_ pov_rate_moe_ ///
		rel_inc_ log_rel_inc_ rel_inc_cat_ ///
		pid3_ ///
		birthyr_ gender_ educ_ race_ inputstate_) ///
		(tax_pref faminc_new faminc_mid log_faminc zipcode ///
		median_inc median_inc_moe gini gini_moe log_median_inc ///
		pov_rate pov_rate_moe ///
		rel_inc log_rel_inc rel_inc_cat ///
		pid3 ///
		birthyr gender educ race inputstate)

* Reapply value label lost in reshape
	label values rel_inc_cat rel_inc_cat_lbl

* Create full year from wave suffix (20 → 2020, 22 → 2022)
	generate year = 2000 + wave
	drop wave
	drop if year == 2024

* GINI Rescaling: Upscaling GINI coefficient to ease interpetation of marginal effects
	generate gini_s = gini * 100


********************************************************************************
* PANEL BALANCE CHECK
* Each cid must appear exactly twice: 2020 and 2022
* Any deviation means the reshape or the raw panel file has an anomaly
********************************************************************************

	tabulate year

	bysort cid: generate n_obs_cid = _N
	count if n_obs_cid != 2
	if r(N) > 0 {
		display as error "WARNING: " r(N) " obs belong to cids with != 2 waves"
		list cid year if n_obs_cid != 2, sepby(cid)
	}
	else {
		display as text "Panel balance OK — " _N/2 " respondents × 2 waves = " _N " total obs"
	}
	drop n_obs_cid


	label variable year "Survey year"
	label variable tax_pref     "Tax preference (1=raise taxes on rich, 5=cut taxes)"
	label variable faminc_new   "Family income category (CES)"
	label variable log_faminc   "Log family income midpoint (2020 dollars)"
	label variable median_inc   "ZIP median household income (ACS)"
	label variable log_median_inc "Log ZIP median household income"
	label variable gini         "ZIP Gini coefficient (ACS)"
	label variable gini_s		"100x scaled ZIP Gini coefficent (ACS)"
	label variable pov_rate     "ZIP poverty rate, % below poverty level (ACS S1701)"
	label variable rel_inc      "Own income / ZIP median income"
	label variable log_rel_inc  "Log relative income (log_faminc - log_median_inc)"
	label variable rel_inc_cat  "Relative income position (4 categories)"
	label variable pid3         "Party identification (1=Dem, 2=Rep, 3=Ind)"
	label variable zipcode      "5-digit ZIP code"


* Ordered tax preference outcome (for ologit)
* Collapses the 0–100 tax_pref slider into three ordered categories:
*   1 = Sales tax preference  (tax_pref < 50)
*   2 = Indifferent           (tax_pref == 50)
*   3 = Income tax preference (tax_pref > 50 and <= 100)
	generate tax_pref_3 = .
	replace  tax_pref_3 = 1 if tax_pref < 50
	replace  tax_pref_3 = 2 if tax_pref == 50
	replace  tax_pref_3 = 3 if tax_pref > 50 & tax_pref <= 100
	label define tax3 1 "Sales preference" 2 "Indifferent" 3 "Income preference"
	label values tax_pref_3 tax3
	label variable tax_pref_3 "Tax preference (ordered: 1=Sales, 2=Indiff, 3=Income)"


* Drop all variables not used in downstream analysis
* Removes: faminc_mid (intermediate construction), MOE variables (median_inc_moe,
*   gini_moe, pov_rate_moe), and any unrenamed raw CES variables surviving the reshape
	keep cid year ///
		tax_pref tax_pref_3 ///
		log_median_inc median_inc gini gini_s pov_rate ///
		log_faminc faminc_new ///
		rel_inc log_rel_inc rel_inc_cat ///
		pid3 birthyr age gender educ race ///
		inputstate zipcode mover commonweight_22


********************************************************************************
* MISSING VALUE DIAGNOSTIC
* All regression variables checked; any variable with missing obs will appear.
* Variables absent from this table have zero missing values.
* Investigate any missings before running regressions — they silently drop obs.
********************************************************************************

	misstable summarize ///
		tax_pref tax_pref_3 ///
		log_median_inc median_inc gini pov_rate ///
		log_faminc faminc_new ///
		rel_inc log_rel_inc rel_inc_cat ///
		pid3 birthyr age gender educ race ///
		inputstate zipcode mover commonweight_22, all

* Flag any obs where the primary regression sample would be dropped
* (complete case across the core Luttmer spec + demographics + state FE)
	egen n_missing_core = rowmiss(tax_pref log_median_inc log_faminc gini pov_rate ///
		birthyr gender educ race inputstate pid3 commonweight_22)
	count if n_missing_core > 0
	if r(N) > 0 {
		display as error "WARNING: " r(N) " obs will be dropped from core regressions due to missing values"
		tabulate year if n_missing_core > 0
	}
	else {
		display as text "No missing values in core regression variables — full sample usable"
	}
	drop n_missing_core



* Declare panel structure
	xtset cid year
	xtdescribe


* Save long dataset
	save "./data/CES_ACS_merged_long.dta", replace
