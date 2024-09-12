/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
Purpose: This file merges the collapsed SCF & CE datasets
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all 
set more off

							* Merged dataset
							* ==============

* merge the datasets 
use $cleandata/scf/CollapsedScf22
merge 1:1 quantile age using $cleandata/ce/CollapsedCe22
assert _merge == 3

* broader age category variable 
gen ageCat = 1 if age == "29 & below" | age == "30 - 39"
replace ageCat = 2 if age == "40 - 49" | age == "50 - 59" | age == "60 - 69"
replace ageCat = 3 if age == "70 - 79" | age == "80 & above"

* income quartile variable 
gen quartile = 1
replace quartile = 2 if quantile >= 5 & quantile < 10
replace quartile = 3 if quantile >= 10 & quantile < 15
replace quartile = 4 if quantile >= 15

* rescale weights 
sum scfWgt
gen scfWgt2 = scfWgt / r(mean)
sum ceWgt
gen ceWgt2 = ceWgt / r(mean)

* create average weight across SCF and CE
gen avgWeight = (scfWgt2 + ceWgt2) / 2

* to construct equity & expn shares, we need to account for the weight of each cell 
gen weightedEquity = meanEq*scfWgt2
egen totalEqWgted= sum(weightedEquity)
gen eqShare = weightedEquity/totalEqWgted
drop totalEqWgted

gen weightedExpenditure = meanExpn*ceWgt2
egen totalExpWgted= sum(weightedExpenditure)
gen expnShare = weightedExpenditure/totalExpWgted 
drop totalExpWgted

* CHECK: eqShare & expnShare should add up to 1 since they say 
*        "this demo group has this share of equity & expenditure"

egen sum_eqShare = sum(eqShare)
egen sum_expnShare = sum(expnShare)
assert sum_eqShare == 1
assert sum_expnShare == 1
drop sum_expnShare sum_eqShare

/* (unweighted) equity & expenditure shares 
egen totalEqUnwgt = sum(meanEq)
gen eqShareUnwgt = meanEq/totalEqUnwgt 
drop totalEqUnwgt
egen totalExpnUnwgt = sum(meanExpn)
gen expnShareUnwgt = meanExpn/totalExpnUnwgt
drop totalExpnUnwgt
*/

* lambda 
gen lambda = expnShare/eqShare

* label variables 
label var quartile "Income quartile of household, 1 to 4" 
label var scfWgt2 "Rescaled weight: scfWgt / mean(scfWgt)"
label var ceWgt2 "Rescaled weight: ceWgt / mean(ceWgt)"
label var avgWeight "Average of rescaled scf and ce weights"
label var weightedEquity "Mean equity weighted by rescaled weights"
label var eqShare "Weighted share of total equity by age & income quantile"
label var weightedExpenditure "Mean expenditure weighted by rescaled weights"
label var expnShare "Weighted share of total expenditure by age & income quantile"
label var lambda "(Weighted Expenditure Share) / (Weightd Equity Share) by age & income quantile"
label var scfCount "Number of SCF households by age & income quantile"
label var ageCat "Adulthood: 1 = Early (20s - 30s), 2 = Middle (40s - 60s), 3 = Late (70s - 80s)"

* order variables 
order quantile quartile age ageCat scfCount ceCount scfWgt scfWgt2 ceWgt ceWgt2 ///
	avgWeight minInc medInc maxInc meanInc logInc sdInc minEq medEq maxEq meanEq ///
	weightedEquity logEq sdEq eqShare meanExpn weightedExpenditure logExpn expnShare ///
	lambda _merge
		
* save dataset
save $cleandata/MainDataset, replace
