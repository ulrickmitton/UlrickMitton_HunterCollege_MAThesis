****** ACS 2021 & 2023 5-Year ZIP Prep (API Version)
****** Pulls Median Income, GINI Coefficient, and Poverty Rate for both survey years
****** Source tables: S1903 (median income), B19083 (GINI), S1701 (poverty rate)
****** Saves year-specific files with suffixed zipcode for CES merge
****** Author: Ulrick Mitton
****** Last edit: 06/27/2026

	version 18.0
	capture mkdir "./logs"
	capture mkdir "./data"
	capture mkdir "./data/ACS"
	log using "./logs/ACS_ZIP_Prep_API_Combined", replace

********************************************************************************
* Census API Key
********************************************************************************
	local censuskey : environment CENSUS_API_KEY
	if "`censuskey'" == "" {
		display as error "Set the CENSUS_API_KEY environment variable before running this script."
		exit 198
	}
	global censuskey "`censuskey'"

********************************************************************************
* Install getcensus if needed
********************************************************************************
	capture which getcensus
	if _rc != 0 {
		ssc install getcensus, replace
	}

********************************************************************************
********************************************************************************
* LOOP OVER SURVEY YEARS
********************************************************************************
********************************************************************************

	foreach survey_year in 2021 2023 {

	* Set year macros
		local data_year = `survey_year' - 1
		local ysuf = substr("`data_year'", 3, 2)

		display _newline(3)
		display "============================================================"
		display "  Processing ACS `survey_year' 5-Year (reference year `data_year')"
		display "============================================================"

	****************************************************************************
	* PULL 1: Median Household Income (Table S1903)
	****************************************************************************
		getcensus S1903_C01_001 S1903_C03_001, ///
			years(`survey_year') ///
			geography(zip code tabulation area) ///
			sample(5) ///
			clear

	* Formatting variables
		rename s1903_c01_001e n_obs_`ysuf'
		drop   s1903_c01_001m
		rename s1903_c03_001e median_inc_`ysuf'
		rename s1903_c03_001m median_inc_`ysuf'_moe

	* Clean missing/suppressed values
		drop if n_obs_`ysuf' == 0
		drop if median_inc_`ysuf' == .

	* Format ZCTA identifier — suffix with data year for CES merge
		rename zipcodetabulationarea zipcode_`ysuf'
		tostring zipcode_`ysuf', replace format(%05.0f)
		assert length(zipcode_`ysuf') == 5

		drop name   // drop ZCTA label to avoid variable conflict on subsequent merges
		sort zipcode_`ysuf'

	* Save median income file
		save "./data/ACS/acs_zip_median_inc_`data_year'.dta", replace

	****************************************************************************
	* PULL 2: GINI Coefficient (Table B19083)
	****************************************************************************
		getcensus B19083_001, ///
			years(`survey_year') ///
			geography(zip code tabulation area) ///
			sample(5) ///
			clear

	* Formatting variables
		rename b19083_001e gini_`ysuf'
		rename b19083_001m gini_`ysuf'_moe

	* Format ZCTA identifier
		rename zipcodetabulationarea zipcode_`ysuf'
		tostring zipcode_`ysuf', replace format(%05.0f)
		assert length(zipcode_`ysuf') == 5

		drop name
		sort zipcode_`ysuf'

	* Merge GINI onto median income
		merge 1:1 zipcode_`ysuf' using "./data/ACS/acs_zip_median_inc_`data_year'.dta"
		keep if _merge == 1 | _merge == 3
		drop _merge
		drop if median_inc_`ysuf' == .
		drop if gini_`ysuf' == .

		sort zipcode_`ysuf'

	* Save income + GINI intermediate (input for poverty merge below)
		save "./data/ACS/acs_`survey_year'_inc_gini.dta", replace

	****************************************************************************
	* PULL 3: Poverty Rate (Table S1701)
	* S1701_C03_001E: % of total population below poverty level
	****************************************************************************
		getcensus S1701_C03_001, ///
			years(`survey_year') ///
			geography(zip code tabulation area) ///
			sample(5) ///
			clear

	* Formatting variables
		rename s1701_c03_001e pov_rate_`ysuf'
		rename s1701_c03_001m pov_rate_`ysuf'_moe

		drop if pov_rate_`ysuf' == .

	* Format ZCTA identifier
		rename zipcodetabulationarea zipcode_`ysuf'
		tostring zipcode_`ysuf', replace format(%05.0f)
		assert length(zipcode_`ysuf') == 5

		drop name
		sort zipcode_`ysuf'

	****************************************************************************
	* Final merge: poverty rate + income + GINI
	****************************************************************************
		merge 1:1 zipcode_`ysuf' using "./data/ACS/acs_`survey_year'_inc_gini.dta"
		keep if _merge == 1 | _merge == 3
		drop _merge

		drop if median_inc_`ysuf' == .
		drop if gini_`ysuf' == .
		drop if pov_rate_`ysuf' == .

		sort zipcode_`ysuf'

	* Save final merged file
		save "./data/ACS/acs_`survey_year'_merged.dta", replace
		summarize
		describe

	}

	capture log close
