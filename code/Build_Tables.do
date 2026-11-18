****** UlrickMitton_Thesis - Build Tables
****** Last Edit: 07/22/2026

	version 18.0
	capture mkdir "./logs"
	capture mkdir "./results"
	capture mkdir "./results/tables"
	log using "./logs/Build_Tables", replace
	capture confirm file "./data/CES_ACS_merged_long.dta"
	if _rc {
		display as error "Run this do-file from the repository root after CES_ACS_Merge.do."
		exit 601
	}
	use "./data/CES_ACS_merged_long.dta", clear


********************************************************************************
*SETUP: Generating mean-centered variables for use in interactions
*******************************************************************************

*   Mean-center income and Gini (mirrors Regressions_RQ2.do setup)
	quietly summarize log_median_inc
	generate log_median_inc_c = log_median_inc - r(mean)
	label variable log_median_inc_c "Log neighborhood income (mean centered)"

	quietly summarize log_faminc
	generate log_faminc_c = log_faminc - r(mean)
	label variable log_faminc_c "Log own income (mean centered)"

	quietly summarize gini_s
	generate gini_s_c = gini_s - r(mean)
	label variable gini_s_c "ZIP Gini (100x, mean centered)"


********************************************************************************
* TABLE 1: H1a Baseline — Neighborhood Income Effect on Tax Preferences
* (1) Reduced pooled  (2) Full pooled  (3) 2020 full  (4) 2022 full
********************************************************************************

*** Column 1: Reduced — pooled
	regress tax_pref log_median_inc log_faminc gini_s i.year ///
		[pweight = commonweight_22], ///
		robust cluster(cid)
	estimates store h1a_reduced_pool

*** Column 2: Full controls — pooled
*** Column 2: Full controls — pooled
*** Column 2: Full controls — pooled
	regress tax_pref ///
		log_median_inc log_faminc gini_s ///
		i.year age i.gender i.educ i.race ///
		i.inputstate ///
		[pweight = commonweight_22], ///
		robust cluster(cid)
	estimates store h1a_full_pool

*** Column 3: Full controls — 2020
	regress tax_pref ///
		log_median_inc log_faminc gini_s ///
		age i.gender i.educ i.race ///
		i.inputstate ///
		[pweight = commonweight_22] if year == 2020, ///
		robust cluster(zipcode)
	estimates store h1a_full_20

*** Column 4: Full controls — 2022
	regress tax_pref ///
		log_median_inc log_faminc gini_s ///
		age i.gender i.educ i.race ///
		i.inputstate ///
		[pweight = commonweight_22] if year == 2022, ///
		robust cluster(zipcode)
	estimates store h1a_full_22

	esttab h1a_reduced_pool h1a_full_pool h1a_full_20 h1a_full_22 ///
		using "./results/tables/RQ1_baseline.tex", ///
		replace booktabs ///
		keep(log_median_inc log_faminc gini_s) ///
		varlabels(log_median_inc "Neighborhood median income (log)" ///
		          log_faminc "Own family income (log)" ///
		          gini_s "ZIP Gini coefficient (100x scaled)") ///
		mgroups("Pooled" "2020" "2022", pattern(1 0 1 1) ///
		    prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
		mtitles("Reduced" "Full Controls" "Full Controls" "Full Controls") ///
		stats(N r2, labels("Observations" "R-squared") fmt(%9.0fc %9.3f)) ///
		se star(* 0.10 ** 0.05 *** 0.01) b(%9.3f) ///
		title("Effect of Neighborhood Income on Tax Preferences") ///
		nonotes addnotes("Robust standard errors in parentheses." ///
		                 "Pooled columns cluster at the individual (cid) level." ///
		                 "Year-specific columns cluster at the ZIP code level." ///
		                 "Full controls: age, gender, education, race, and state fixed effects." ///
		                 "Pooled columns include a year fixed effect." ///
		                 "* p<0.10, ** p<0.05, *** p<0.01")


********************************************************************************
* TABLE 2: H1b Partisan Moderation — Interaction with Party Identification
* Single regression; Panel A: interaction coefficients, Panel B: margins by party
* Note: base category for pid3 is Democrats (pid3 == 1)
********************************************************************************

*** H1b interaction — full sample, no state FE (matches Regressions_RQ1.do)
	regress tax_pref ///
		c.log_median_inc_c##i.pid3 log_faminc gini_s ///
		age i.gender i.educ i.race i.inputstate i.year ///
		[pweight = commonweight_22] if inlist(pid3, 1, 2, 3), ///
		robust cluster(cid)
	test 2.pid3#c.log_median_inc_c = 3.pid3#c.log_median_inc_c
	estimates store h1b_int

*** Implied slopes by party — post replaces active estimates; store separately
	margins pid3, dydx(log_median_inc_c) post
	estimates store h1b_slopes

* Panel A: Interaction coefficients
esttab h1b_int ///
    using "./results/tables/RQ1_pid.tex", ///
    replace booktabs ///
    keep(log_median_inc_c ///
         2.pid3#c.log_median_inc_c 3.pid3#c.log_median_inc_c ///
         2.pid3 3.pid3 ///
         log_faminc gini_s) ///
    order(log_median_inc_c ///
          2.pid3#c.log_median_inc_c 3.pid3#c.log_median_inc_c ///
          2.pid3 3.pid3 ///
          log_faminc gini_s) ///
    varlabels(log_median_inc_c "Neighborhood median income (log)(Democrats)" ///
              2.pid3#c.log_median_inc_c "Neighborhood median income (log) $\times$ Republican" ///
              3.pid3#c.log_median_inc_c "Neighborhood median income (log) $\times$ Independent" ///
              2.pid3 "Republican (vs.\ Democrat)" ///
              3.pid3 "Independent (vs.\ Democrat)" ///
              log_faminc "Own family income (log)" ///
              gini_s "ZIP Gini coefficient (100$\times$ scaled)") ///
    stats(N r2, labels("Observations" "R-squared") fmt(%9.0fc %9.3f)) ///
    se star(* 0.10 ** 0.05 *** 0.01) b(%9.3f) ///

* Panel B: Implied slopes by party (margins-derived)
	esttab h1b_slopes ///
		using "./results/tables/RQ1_pidslopes.tex", ///
		append booktabs ///
		keep(1.pid3 2.pid3 3.pid3) ///
		varlabels(1.pid3 "Democrats" ///
		          2.pid3 "Independents" ///
		          3.pid3 "Republicans") ///
		se star(* 0.10 ** 0.05 *** 0.01) b(%9.3f) ///
		nomtitles nonumbers noobs ///
		nonotes addnotes("Robust standard errors clustered at the individual (cid) level." ///
		                 "Panel A: OLS estimates. Base category for party identification is Democrats (pid3 = 1)." ///
		                 "Panel B: dy/dx of log neighborhood income by party, from post-estimation margins." ///
		                 "Controls: own family income (log), ZIP Gini, year FE, age, gender, education, race." ///
		                 "* p<0.10, ** p<0.05, *** p<0.01")



********************************************************************************
* TABLES 3 & 4: RQ2 — Inequality Moderation (H3a and H3b)
* Source: Regressions_RQ2.do
* H3a: Gini moderates the neighborhood income effect on tax preferences
* H3b: Gini moderates the self-interest (own income) effect
********************************************************************************

*** Store centered Gini percentiles for margins at() calls
	quietly summarize gini_s_c, detail
	local gini_p25 = r(p25)
	local gini_p50 = r(p50)
	local gini_p75 = r(p75)
	local gini_p90 = r(p90)


*** H3a: Gini moderates neighborhood income effect
*   Uses log_faminc_c as control so both income rows share a variable name in Table 3
	regress tax_pref ///
		c.log_median_inc_c##c.gini_s_c log_faminc_c ///
		i.year age i.gender i.educ i.race i.inputstate i.pid3 ///
		[pweight = commonweight_22], ///
		robust cluster(zipcode)
	estimates store h3a

*** H3b: Gini moderates own-income (Meltzer-Richard) effect
*   Uses log_median_inc_c as control (parallel structure to H3a)
	regress tax_pref ///
		c.log_faminc_c##c.gini_s_c log_median_inc_c ///
		i.year age i.gender i.educ i.race i.inputstate i.pid3 ///
		[pweight = commonweight_22], ///
		robust cluster(cid)
	estimates store h3b


********************************************************************************
* TABLE 3: OLS Estimates — H3a and H3b
* 5 rows: log nbhd income, log own income, Gini, H3a interaction, H3b interaction
********************************************************************************

	esttab h3a h3b ///
		using "./results/tables/RQ2_ols.tex", ///
		replace booktabs ///
		keep(log_median_inc_c log_faminc_c gini_s_c ///
		     c.log_median_inc_c#c.gini_s_c c.log_faminc_c#c.gini_s_c) ///
		order(log_median_inc_c log_faminc_c gini_s_c ///
		      c.log_median_inc_c#c.gini_s_c c.log_faminc_c#c.gini_s_c) ///
		varlabels(log_median_inc_c "Neighborhood median income (log)" ///
		          log_faminc_c "Own family income (log)" ///
		          gini_s_c "ZIP Gini coefficient (mean centered)" ///
		          c.log_median_inc_c#c.gini_s_c "Neighborhood income $\times$ Gini" ///
		          c.log_faminc_c#c.gini_s_c "Own income $\times$ Gini") ///
		mtitles("H3a" "H3b") ///
		stats(N r2, labels("Observations" "R-squared") fmt(%9.0fc %9.3f)) ///
		se star(* 0.10 ** 0.05 *** 0.01) b(%9.3f) ///
		title("Inequality Moderation of Income Effects on Tax Preferences (H3a, H3b)") ///
		nonotes addnotes("Robust standard errors in parentheses." ///
		                 "H3a clusters at ZIP code; H3b clusters at individual (cid)." ///
		                 "All income and Gini variables mean-centered for slope interpretation at the mean." ///
		                 "Controls: year FE, birth year, gender, education, race, state FE, party ID." ///
		                 "* p<0.10, ** p<0.05, *** p<0.01")


********************************************************************************
* TABLE 4: Implied Slopes at Gini Percentiles — H3a and H3b
* dy/dx of log_median_inc_c (H3a) and log_faminc_c (H3b) at p25/p50/p75/p90
* Written directly as LaTeX via file write (avoids esttab auto-naming of at() points)
********************************************************************************

*** H3a slopes at Gini percentiles
	estimates restore h3a
	margins, dydx(log_median_inc_c) ///
		at(gini_s_c = (`gini_p25' `gini_p50' `gini_p75' `gini_p90')) post
	matrix B3a = e(b)
	matrix V3a = e(V)

*** H3b slopes at Gini percentiles
	estimates restore h3b
	margins, dydx(log_faminc_c) ///
		at(gini_s_c = (`gini_p25' `gini_p50' `gini_p75' `gini_p90')) post
	matrix B3b = e(b)
	matrix V3b = e(V)

*** Extract b and SE into scalars (scalar() prevents ambiguity with variables)
	forvalues i = 1/4 {
		scalar sc_b3a_`i'  = B3a[1, `i']
		scalar sc_se3a_`i' = sqrt(V3a[`i', `i'])
		scalar sc_b3b_`i'  = B3b[1, `i']
		scalar sc_se3b_`i' = sqrt(V3b[`i', `i'])
	}

*** Format values and compute significance stars
	forvalues i = 1/4 {

		local ta = abs(scalar(sc_b3a_`i') / scalar(sc_se3a_`i'))
		if      `ta' >= 2.576 local s3a_`i' "***"
		else if `ta' >= 1.960 local s3a_`i' "**"
		else if `ta' >= 1.645 local s3a_`i' "*"
		else                  local s3a_`i' ""
		local b3a_`i'  : display %7.3f scalar(sc_b3a_`i')
		local se3a_`i' : display %7.3f scalar(sc_se3a_`i')

		local tb = abs(scalar(sc_b3b_`i') / scalar(sc_se3b_`i'))
		if      `tb' >= 2.576 local s3b_`i' "***"
		else if `tb' >= 1.960 local s3b_`i' "**"
		else if `tb' >= 1.645 local s3b_`i' "*"
		else                  local s3b_`i' ""
		local b3b_`i'  : display %7.3f scalar(sc_b3b_`i')
		local se3b_`i' : display %7.3f scalar(sc_se3b_`i')
	}

*** Write LaTeX
	file open tab4 using "./results/tables/rq2_slopes.tex", write replace

	file write tab4 "\begin{table}[htbp]" _n
	file write tab4 "\centering" _n
	file write tab4 "\caption{Implied Slopes at Percentiles of Local Inequality (H3a and H3b)}" _n
	file write tab4 "\label{tab:h3-slopes}" _n
	file write tab4 "\begin{tabular}{lcc}" _n
	file write tab4 "\toprule" _n
	file write tab4 "                            & (1)    & (2) \\" _n
	file write tab4 "                            & H3a    & H3b \\" _n
	file write tab4 "                            & Nbhd.\ income slope & Own income slope \\" _n
	file write tab4 "\midrule" _n

	file write tab4 "25th percentile of Gini     & `b3a_1'`s3a_1' & `b3b_1'`s3b_1' \\" _n
	file write tab4 "                            & (`se3a_1') & (`se3b_1') \\" _n
	file write tab4 "50th percentile of Gini     & `b3a_2'`s3a_2' & `b3b_2'`s3b_2' \\" _n
	file write tab4 "                            & (`se3a_2') & (`se3b_2') \\" _n
	file write tab4 "75th percentile of Gini     & `b3a_3'`s3a_3' & `b3b_3'`s3b_3' \\" _n
	file write tab4 "                            & (`se3a_3') & (`se3b_3') \\" _n
	file write tab4 "90th percentile of Gini     & `b3a_4'`s3a_4' & `b3b_4'`s3b_4' \\" _n
	file write tab4 "                            & (`se3a_4') & (`se3b_4') \\" _n

	file write tab4 "\bottomrule" _n
	file write tab4 "\multicolumn{3}{p{11cm}}{\footnotesize " _n
	file write tab4 "Marginal effects (\texttt{margins, dydx()}) evaluated at the 25th, 50th, " _n
	file write tab4 "75th, and 90th percentiles of the ZIP Gini coefficient (mean-centered). " _n
	file write tab4 "Column (1): slope of log neighborhood income on \texttt{tax\_pref} (H3a). " _n
	file write tab4 "Column (2): slope of log own income on \texttt{tax\_pref} (H3b). " _n
	file write tab4 "Standard errors in parentheses. " _n
	file write tab4 "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.} \\" _n
	file write tab4 "\end{tabular}" _n
	file write tab4 "\end{table}" _n

	file close tab4



********************************************************************************
* TABLES 6–8: RQ3 — Asymmetric Position Effects and Inequality Moderation
* Source: Regressions_RQ3.do
* Table 6: RQ3a — baseline asymmetry (parsimonious, full, p25 kink)
* Table 7: RQ3b — Gini moderation of asymmetric slopes
* Table 8: Implied slopes at Gini percentiles (p25 kink, file write)
********************************************************************************

*** Spline slope variables around the local income median
	capture drop above_median below_dist above_dist
	generate above_median = (log_rel_inc >= 0) if !missing(log_rel_inc)
	generate below_dist   = log_rel_inc * (log_rel_inc <  0)
	generate above_dist   = log_rel_inc * (log_rel_inc >= 0)

*** p25 kink variants
	quietly summarize log_rel_inc, detail
	local p25_rel = r(p25)
	capture drop below_dist_p25 above_dist_p25
	generate below_dist_p25 = (log_rel_inc - `p25_rel') * (log_rel_inc <  `p25_rel')
	generate above_dist_p25 = (log_rel_inc - `p25_rel') * (log_rel_inc >= `p25_rel')

*** gini_s_c created in RQ2 setup; guard for standalone run
	capture confirm variable gini_s_c
	if _rc {
		quietly summarize gini_s
		generate gini_s_c = gini_s - r(mean)
		label variable gini_s_c "ZIP Gini (100x) — mean centered"
	}

*** Gini percentiles for Table 8 margins at() calls
	quietly summarize gini_s_c, detail
	local gini_p25 = r(p25)
	local gini_p50 = r(p50)
	local gini_p75 = r(p75)
	local gini_p90 = r(p90)


********************************************************************************
* TABLE 6: RQ3a — Asymmetric Position Effects on Tax Preferences
* (1) Parsimonious  (2) Full controls  (3) p25 kink, full controls
********************************************************************************

*** Column 1: Parsimonious — median kink
	regress tax_pref below_dist above_dist ///
		log_median_inc ///
		[pweight = commonweight_22], ///
		robust cluster(cid)
	test below_dist = above_dist
	estadd scalar F_equal = r(F)
	estadd scalar p_equal = r(p)
	estimates store rq3a_pars

*** Column 2: Full controls — median kink
	regress tax_pref below_dist above_dist ///
		log_median_inc gini_s i.pid3 ///
		i.year age i.gender i.educ i.race i.inputstate ///
		[pweight = commonweight_22], ///
		robust cluster(cid)
	test below_dist = above_dist
	estadd scalar F_equal = r(F)
	estadd scalar p_equal = r(p)
	estimates store rq3a_full

*** Column 3: Full controls — p25 kink
	regress tax_pref below_dist_p25 above_dist_p25 ///
		log_median_inc gini_s i.pid3 ///
		i.year age i.gender i.educ i.race i.inputstate ///
		[pweight = commonweight_22], ///
		robust cluster(cid)
	test below_dist_p25 = above_dist_p25
	estadd scalar F_equal = r(F)
	estadd scalar p_equal = r(p)
	estimates store rq3a_p25

	esttab rq3a_pars rq3a_full rq3a_p25 ///
		using "./results/tables/RQ3a.tex", ///
		replace booktabs ///
		keep(below_dist above_dist ///
		     below_dist_p25 above_dist_p25 ///
		     log_median_inc gini_s) ///
		order(below_dist above_dist ///
		      below_dist_p25 above_dist_p25 ///
		      log_median_inc gini_s) ///
		refcat(below_dist "\textit{Median kink}" ///
		       below_dist_p25 "\textit{25th-percentile kink}" ///
		       log_median_inc "\textit{Controls}", nolabel) ///
		varlabels(below_dist "Below-median slope" ///
		          above_dist "Above-median slope" ///
		          below_dist_p25 "Below-P25 slope" ///
		          above_dist_p25 "Above-P25 slope" ///
		          log_median_inc "Neighborhood median income (log)" ///
		          gini_s "ZIP Gini coefficient (100x scaled)") ///
		mtitles("Parsimonious" "Full Controls" "P25 Kink") ///
		stats(F_equal p_equal N r2, ///
		      labels("Slope-equality \textit{F} test" ///
		             "Slope-equality \textit{p}-value" ///
		             "Observations" "R-squared") ///
		      fmt(%6.2f %6.3f %9.0fc %9.3f)) ///
		se star(* 0.10 ** 0.05 *** 0.01) b(%9.3f) ///
		title("Asymmetric Position Effects on Tax Preferences (RQ3a)") ///
		nonotes addnotes("Robust standard errors clustered at individual (cid) in parentheses." ///
		                 "The slope-equality test compares the below- and above-threshold slopes (null: no kink)." ///
		                 "Columns (1)--(2): kink at the ZIP median ($\log y/\bar{y} = 0$)." ///
		                 "Column (3): kink at the 25th percentile of $\log y/\bar{y}$." ///
		                 "Full controls: year FE, age, gender, education, race, state FE, party ID." ///
		                 "* p<0.10, ** p<0.05, *** p<0.01")



********************************************************************************
* TABLE 7: RQ3b — Gini Moderation of Asymmetric Position Effects
* (1) Median kink × Gini   (2) p25 kink × Gini (labeled RQ3b in source file)
* gini_s_c mean-centered; slope coefficients evaluated at mean Gini (= 0)
********************************************************************************

*** Column 1: Median kink with Gini interactions
*   Continuous spline: the below- and above-median segments meet at the kink
	regress tax_pref ///
		c.below_dist c.above_dist c.gini_s_c ///
		c.below_dist#c.gini_s_c c.above_dist#c.gini_s_c ///
		log_median_inc i.pid3 ///
		i.year age i.gender i.educ i.race i.inputstate ///
		[pweight = commonweight_22], ///
		robust cluster(cid)
	estimates store rq3b_med

*** Column 2: p25 kink with Gini interactions (RQ3b in Regressions_RQ3.do)
	regress tax_pref ///
		c.below_dist_p25 c.above_dist_p25 c.gini_s_c ///
		c.below_dist_p25#c.gini_s_c c.above_dist_p25#c.gini_s_c ///
		log_median_inc i.pid3 ///
		i.year age i.gender i.educ i.race i.inputstate ///
		[pweight = commonweight_22], ///
		robust cluster(cid)
	estimates store rq3b_p25

	esttab rq3b_med rq3b_p25 ///
		using "./results/tables/RQ3b.tex", ///
		replace booktabs ///
		keep(below_dist c.below_dist#c.gini_s_c ///
		     above_dist c.above_dist#c.gini_s_c ///
		     below_dist_p25 c.below_dist_p25#c.gini_s_c ///
		     above_dist_p25 c.above_dist_p25#c.gini_s_c ///
		     gini_s_c log_median_inc) ///
		order(below_dist c.below_dist#c.gini_s_c ///
		      above_dist c.above_dist#c.gini_s_c ///
		      below_dist_p25 c.below_dist_p25#c.gini_s_c ///
		      above_dist_p25 c.above_dist_p25#c.gini_s_c ///
		      gini_s_c log_median_inc) ///
		refcat(below_dist "\textit{Median kink}" ///
		       below_dist_p25 "\textit{25th-percentile kink}" ///
		       gini_s_c "\textit{Inequality main effect}", nolabel) ///
		varlabels(below_dist "Below-median slope (at mean Gini)" ///
		          c.below_dist#c.gini_s_c "Below-median slope $\times$ Gini" ///
		          above_dist "Above-median slope (at mean Gini)" ///
		          c.above_dist#c.gini_s_c "Above-median slope $\times$ Gini" ///
		          below_dist_p25 "Below-P25 slope (at mean Gini)" ///
		          c.below_dist_p25#c.gini_s_c "Below-P25 slope $\times$ Gini" ///
		          above_dist_p25 "Above-P25 slope (at mean Gini)" ///
		          c.above_dist_p25#c.gini_s_c "Above-P25 slope $\times$ Gini" ///
		          gini_s_c "ZIP Gini (mean centered)" ///
		          log_median_inc "Neighborhood median income (log)") ///
		mtitles("Median kink" "P25 kink") ///
		stats(N r2, labels("Observations" "R-squared") fmt(%9.0fc %9.3f)) ///
		se star(* 0.10 ** 0.05 *** 0.01) b(%9.3f) ///
		title("Gini Moderation of Asymmetric Position Effects (RQ3b)") ///
		nonotes addnotes("Robust standard errors clustered at individual (cid) in parentheses." ///
		                 "Both specifications are continuous at the kink and include no threshold-discontinuity indicator." ///
		                 "\texttt{gini\_s\_c} is mean-centered; slope coefficients are evaluated at mean Gini ($= 0$)." ///
		                 "Controls: year FE, age, gender, education, race, state FE, party ID." ///
		                 "* p<0.10, ** p<0.05, *** p<0.01")


********************************************************************************
* TABLE 8: Implied Slopes at Gini Percentiles — p25 kink spec (RQ3b col 2)
* Separate margins calls for below and above to avoid ambiguous matrix indexing
********************************************************************************

*** Below-P25 slopes at Gini percentiles
	estimates restore rq3b_p25
	margins, dydx(below_dist_p25) ///
		at(gini_s_c = (`gini_p25' `gini_p50' `gini_p75' `gini_p90')) post
	matrix B_bel = e(b)
	matrix V_bel = e(V)

*** Above-P25 slopes
	estimates restore rq3b_p25
	margins, dydx(above_dist_p25) ///
		at(gini_s_c = (`gini_p25' `gini_p50' `gini_p75' `gini_p90')) post
	matrix B_abo = e(b)
	matrix V_abo = e(V)

*** Extract scalars
	forvalues i = 1/4 {
		scalar sc_bel`i'   = B_bel[1, `i']
		scalar sc_belse`i' = sqrt(V_bel[`i', `i'])
		scalar sc_abo`i'   = B_abo[1, `i']
		scalar sc_abose`i' = sqrt(V_abo[`i', `i'])
	}

*** Format and stars
	forvalues i = 1/4 {
		local t = abs(scalar(sc_bel`i') / scalar(sc_belse`i'))
		if      `t' >= 2.576 local s_bel`i' "***"
		else if `t' >= 1.960 local s_bel`i' "**"
		else if `t' >= 1.645 local s_bel`i' "*"
		else                 local s_bel`i' ""
		local b_bel`i'  : display %7.3f scalar(sc_bel`i')
		local se_bel`i' : display %7.3f scalar(sc_belse`i')

		local t = abs(scalar(sc_abo`i') / scalar(sc_abose`i'))
		if      `t' >= 2.576 local s_abo`i' "***"
		else if `t' >= 1.960 local s_abo`i' "**"
		else if `t' >= 1.645 local s_abo`i' "*"
		else                 local s_abo`i' ""
		local b_abo`i'  : display %7.3f scalar(sc_abo`i')
		local se_abo`i' : display %7.3f scalar(sc_abose`i')
	}

*** Write LaTeX
	file open tab8 using "./results/tables/RQ3b_slopes.tex", write replace

	file write tab8 "\begin{table}[htbp]" _n
	file write tab8 "\centering" _n
	file write tab8 "\caption{Implied Position Slopes at Percentiles of Local Inequality (RQ3b)}" _n
	file write tab8 "\label{tab:rq3b-slopes}" _n
	file write tab8 "\begin{tabular}{lcc}" _n
	file write tab8 "\toprule" _n
	file write tab8 "                              & Below-P25 slope & Above-P25 slope \\" _n
	file write tab8 "\midrule" _n
	file write tab8 "25th percentile of Gini       & `b_bel1'`s_bel1' & `b_abo1'`s_abo1' \\" _n
	file write tab8 "                              & (`se_bel1') & (`se_abo1') \\" _n
	file write tab8 "50th percentile of Gini       & `b_bel2'`s_bel2' & `b_abo2'`s_abo2' \\" _n
	file write tab8 "                              & (`se_bel2') & (`se_abo2') \\" _n
	file write tab8 "75th percentile of Gini       & `b_bel3'`s_bel3' & `b_abo3'`s_abo3' \\" _n
	file write tab8 "                              & (`se_bel3') & (`se_abo3') \\" _n
	file write tab8 "90th percentile of Gini       & `b_bel4'`s_bel4' & `b_abo4'`s_abo4' \\" _n
	file write tab8 "                              & (`se_bel4') & (`se_abo4') \\" _n
	file write tab8 "\bottomrule" _n
	file write tab8 "\multicolumn{3}{p{11cm}}{\footnotesize " _n
	file write tab8 "Marginal effects from the RQ3b p25-kink $\times$ Gini specification, " _n
	file write tab8 "evaluated at the 25th, 50th, 75th, and 90th percentiles of the ZIP Gini " _n
	file write tab8 "coefficient (mean-centered). Standard errors in parentheses. " _n
	file write tab8 "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.} \\" _n
	file write tab8 "\end{tabular}" _n
	file write tab8 "\end{table}" _n

	file close tab8


	capture log close
