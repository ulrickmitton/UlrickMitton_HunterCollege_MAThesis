********************************************************************************
* Master replication runner for the paper's core regressions
*
* Run this file from the repository root. Each component script reloads the
* analysis dataset and writes a separate plain-text log. No tables are built.
********************************************************************************

version 18.0
clear all
set more off

capture confirm file "./data/CES_ACS_merged_long.dta"
if _rc {
    display as error "Analysis data not found. Run code/CES_ACS_Merge.do first."
    exit 601
}

display as text _newline "Running RQ1 models"
do "./code/Regressions_RQ1.do"

display as text _newline "Running RQ2 models"
do "./code/Regressions_RQ2.do"

display as text _newline "Running RQ3 models"
do "./code/Regressions_RQ3.do"

display as result _newline "Core regression replication completed."
