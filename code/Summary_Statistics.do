****** UlrickMitton_Thesis - Summary Statistics Tables
****** Exports LaTeX tables (booktabs) for Overleaf
****** Data: CES_ACS_merged_long.dta (2020 and 2022 waves)
****** Last Edit: 07/21/2026

	cd "~\Documents\Classwork\Thesis\Thesis"
	log using ".\logs\Summary_Statistics", replace
	use ".\data\CES_ACS_merged_long.dta", clear

*******************************************************************************
* DATA SECTION OUTPUTS
********************************************************************************

	capture mkdir "./figures"
	capture mkdir "./results"
	capture mkdir "./results/tables"

* Figure: distribution of tax preferences by survey wave
* Raw counts are intentional. Matching bins and axes make the waves comparable.
	capture graph drop taxpref_2020 taxpref_2022

	histogram tax_pref if year == 2020, ///
		width(5) start(0) frequency ///
		fcolor(gs8) lcolor(white) ///
		xlabel(0(25)100, labsize(small)) ///
		ylabel(0(100)700, angle(horizontal) labsize(small)) ///
		xtitle("Tax preference (0 = sales, 100 = income)", size(small)) ///
		ytitle("Number of respondents", size(small)) ///
		title("Panel A. 2020", size(medsmall)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		scheme(s1mono) name(taxpref_2020, replace)

	histogram tax_pref if year == 2022, ///
		width(5) start(0) frequency ///
		fcolor(gs8) lcolor(white) ///
		xlabel(0(25)100, labsize(small)) ///
		ylabel(0(100)700, angle(horizontal) labsize(small)) ///
		xtitle("Tax preference (0 = sales, 100 = income)", size(small)) ///
		ytitle("Number of respondents", size(small)) ///
		title("Panel B. 2022", size(medsmall)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		scheme(s1mono) name(taxpref_2022, replace)

	graph combine taxpref_2020 taxpref_2022, ///
		cols(2) xcommon ycommon imargin(tiny) ///
		graphregion(color(white))

	graph export "./figures/fig_tax_pref_by_wave.pdf", as(pdf) replace
	graph export "./figures/fig_tax_pref_by_wave.png", as(png) width(3200) replace
	graph drop taxpref_2020 taxpref_2022

* Table 1: outcome and income measures (pooled respondent-wave sample)
* Dollar variables are shown in thousands of 2020 dollars.
	capture drop median_inc_k faminc_k
	generate median_inc_k = median_inc / 1000
	generate faminc_k = exp(log_faminc) / 1000

	label variable tax_pref "Tax preference"
	label variable median_inc_k "ZIP median household income (\$000s)"
	label variable gini "ZIP Gini coefficient"
	label variable faminc_k "Family income (\$000s)"
	label variable rel_inc "Relative income ratio"

	eststo clear
	estpost summarize ///
		tax_pref median_inc_k gini faminc_k rel_inc ///
		[aweight = commonweight_22], detail

	esttab using "./results/tables/data_income_summary.tex", replace ///
		title("Summary Statistics for the Outcome and Income Measures") ///
		label booktabs nonumber noobs ///
		cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") ///
		collabels("N" "Mean" "Std. dev." "Min." "Max.") ///
		refcat(tax_pref "Survey response" median_inc_k "Income measures", nolabel) ///
		addnotes("Balanced panel: 3,574 respondents and 7,148 respondent-waves." ///
			"Means and SDs are weighted by commonweight\_22; other statistics are unweighted." ///
			"Income is in thousands of 2020 dollars; ZIP measures are missing for 13 observations.")

* Table 2: respondent demographics
* The 2022 observation supplies one record per respondent and preserves the
* four-category gender measure, which was not available in the 2020 survey.
	capture drop age_mean_stat age_sd_stat man woman nonbinary gender_other ///
		no_hs high_school some_college two_year four_year postgraduate ///
		white black hispanic asian native_american middle_eastern multiracial race_other ///
		democrat republican independent party_other party_unsure

	quietly summarize age [aweight = commonweight_22] if year == 2022
	generate age_mean_stat = r(mean)
	generate age_sd_stat = r(sd)

	generate man = 100 * (gender == 1) if !missing(gender)
	generate woman = 100 * (gender == 2) if !missing(gender)
	generate nonbinary = 100 * (gender == 3) if !missing(gender)
	generate gender_other = 100 * (gender == 4) if !missing(gender)

	generate no_hs = 100 * (educ == 1) if !missing(educ)
	generate high_school = 100 * (educ == 2) if !missing(educ)
	generate some_college = 100 * (educ == 3) if !missing(educ)
	generate two_year = 100 * (educ == 4) if !missing(educ)
	generate four_year = 100 * (educ == 5) if !missing(educ)
	generate postgraduate = 100 * (educ == 6) if !missing(educ)

	generate white = 100 * (race == 1) if !missing(race)
	generate black = 100 * (race == 2) if !missing(race)
	generate hispanic = 100 * (race == 3) if !missing(race)
	generate asian = 100 * (race == 4) if !missing(race)
	generate native_american = 100 * (race == 5) if !missing(race)
	generate middle_eastern = 100 * (race == 6) if !missing(race)
	generate multiracial = 100 * (race == 7) if !missing(race)
	generate race_other = 100 * (race == 8) if !missing(race)

	generate democrat = 100 * (pid3 == 1) if !missing(pid3)
	generate republican = 100 * (pid3 == 2) if !missing(pid3)
	generate independent = 100 * (pid3 == 3) if !missing(pid3)
	generate party_other = 100 * (pid3 == 4) if !missing(pid3)
	generate party_unsure = 100 * (pid3 == 5) if !missing(pid3)

	label variable age_mean_stat "Mean"
	label variable age_sd_stat "Standard deviation"
	label variable man "Man"
	label variable woman "Woman"
	label variable nonbinary "Non-binary"
	label variable gender_other "Other gender"
	label variable no_hs "No high school diploma"
	label variable high_school "High school graduate"
	label variable some_college "Some college"
	label variable two_year "Two-year degree"
	label variable four_year "Four-year degree"
	label variable postgraduate "Postgraduate degree"
	label variable white "White"
	label variable black "Black"
	label variable hispanic "Hispanic"
	label variable asian "Asian"
	label variable native_american "Native American"
	label variable middle_eastern "Middle Eastern"
	label variable multiracial "Two or more races"
	label variable race_other "Other race"
	label variable democrat "Democrat"
	label variable republican "Republican"
	label variable independent "Independent"
	label variable party_other "Other party identification"
	label variable party_unsure "Not sure"

	estpost summarize ///
		age_mean_stat age_sd_stat man woman nonbinary gender_other ///
		no_hs high_school some_college two_year four_year postgraduate ///
		white black hispanic asian native_american middle_eastern multiracial race_other ///
		democrat republican independent party_other party_unsure ///
		[aweight = commonweight_22] if year == 2022

	esttab using "./results/tables/data_demographics.tex", replace ///
		title("Respondent Demographics") ///
		label booktabs nonumber noobs ///
		cells("mean(fmt(1))") ///
		collabels("Statistic") ///
		refcat(age_mean_stat "Age (years)" man "Gender (percent)" ///
			no_hs "Educational attainment (percent)" ///
			white "Race and ethnicity (percent)" ///
			democrat "Party identification (percent)", nolabel) ///
		addnotes("One 2022 observation per respondent; N = 3,574." ///
			"Age is the baseline (2020) measure; rows report its weighted mean and SD." ///
			"Category rows show weighted percentages using commonweight\_22.")

	eststo clear