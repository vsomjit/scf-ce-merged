/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
Purpose: This file considers different dimensions in which to collapse the SCF & 
		 CE table and documentss the impact of these specifications on the 
		 relationship between CE & SCF population weights. 
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all 
set more off

					* Robustness Check 1: Broader Age Groups
					* =======================================

* collapsed SCF table with broader age groups

preserve 

// import cleaned dataset 
use $cleandata/scf/Scf22

// dividing income into 20 quantiles
xtile quantile = income [pweight = wgt], nq(20)
label var quantile "Income quantile of household, 1 to 20"

// broader age category variable 
gen ageCat = 1 if age == "29 & below" | age == "30 - 39"
replace ageCat = 2 if age == "40 - 49" | age == "50 - 59" | age == "60 - 69"
replace ageCat = 3 if age == "70 - 79" | age == "80 & above"

// collapse data
collapse (mean) meanInc = income meanEq = equity ///
		(median) medInc = income medEq = equity ///
		(min) minInc = income minEq = equity ///
		(max) maxInc = income maxEq = equity ///
		(sd) sdInc = income sdEq = equity ///
		(count) scfCount = income ///
		(sum) scfWgt = wgt [aweight = wgt], ///
		by (quantile ageCat)
		
sort quantile ageCat

// log transformations
gen logInc = ln(meanInc)
gen logEq = ln(meanEq)

// label variables 
label var meanInc "Average income by age & income quantile"
label var logInc "Log mean income by age & income quantile"
label var maxInc "Maximum income by age & income quantile"
label var minInc "Minimum income by age & income quantile"
label var medInc "Median income by age & income quantile"
label var sdInc "Standard deviation of income by age & income quantile"
label var meanEq "Average value of equity owned by age & income quantile"
label var logEq "Log mean equity by age & income quantile"
label var minEq "Minimum value of equity owned by age & income quantile"
label var maxEq "Maximum value of equity owned by age & income quantile"
label var medEq "Median value of equity owned by age & income quantile"
label var sdEq "Standard deviation of value of equity owned by age & income quantile"
label var scfCount "Number of SCF households"
label var scfWgt "Population weight for SCF households"
label var ageCat "Adulthood: 1 = Early (20s - 30s), 2 = Middle (40s - 60s), 3 = Late (70s - 80s)"

// order variables
order quantile ageCat scfCount scfWgt minInc medInc maxInc meanInc logInc sdInc minEq ///
	  medEq maxEq meanEq logEq sdEq

// save collapsed dataset
save $cleandata/appendix/CollapsedScf22Rc1, replace

restore 

* collapsed CE table with broader age groups

preserve 

// import dataset
use $cleandata/ce/Ce22

// broader age category variable 
gen ageCat = 1 if age == "29 & below" | age == "30 - 39"
replace ageCat = 2 if age == "40 - 49" | age == "50 - 59" | age == "60 - 69"
replace ageCat = 3 if age == "70 - 79" | age == "80 & above"

// collapse data
gen ceCount = 1
collapse (sum) aggExpn = expnWgt (sum) ceWgt = popWgt (sum) ceCount, ///
		by(ageCat quantile)

sort quantile ageCat
		
// average expenditure variable
gen meanExpn = aggExpn / ceWgt

// log transformation
gen logExpn = ln(meanExpn)

// label variables
label var ceWgt "Population weight for CE households"
label var ceCount "Number of CE households by age & income quantile"
label var meanExpn "Average expenditure by age & income quantile"
label var logExpn "Log mean expenditure by age & income quantile"
label var ageCat "Adulthood: 1 = Early (20s - 30s), 2 = Middle (40s - 60s), 3 = Late (70s - 80s)"

// clean up
drop aggExpn 
order quantile ageCat ceCount ceWgt meanExpn logExpn

save $cleandata/appendix/CollapsedCe22Rc1, replace

restore 

* merge newly defined collapsed SCF & CE tables 

preserve 

// merge the datasets 
use $cleandata/appendix/CollapsedScf22Rc1
merge 1:1 quantile ageCat using $cleandata/appendix/CollapsedCe22Rc1
keep if _merge == 3
drop _merge

// income quartile variable 
gen quartile = 1
replace quartile = 2 if quantile >= 5 & quantile < 10
replace quartile = 3 if quantile >= 10 & quantile < 15
replace quartile = 4 if quantile >= 15

// rescale weights 
sum scfWgt
gen scfWgt2 = scfWgt / r(mean)
sum ceWgt
gen ceWgt2 = ceWgt / r(mean)

// create average weight across SCF and CE
gen avgWeight = (scfWgt2 + ceWgt2) / 2

// to construct equity & expn shares, we need to account for the weight of each cell 
gen weightedEquity = meanEq*scfWgt2
egen totalEqWgted= sum(weightedEquity)
gen eqShare = weightedEquity/totalEqWgted
drop totalEqWgted

gen weightedExpenditure = meanExpn*ceWgt2
egen totalExpWgted= sum(weightedExpenditure)
gen expnShare = weightedExpenditure/totalExpWgted 
drop totalExpWgted

// CHECK: eqShare & expnShare should add up to 1 since they say 
//        "this demo group has this share of equity & expenditure"

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

// lambda 
gen lambda = expnShare/eqShare

// label variables 
label var quartile "Income quartile of household, 1 to 4" 
label var eqShare "Share of total equity by age & income quantile"
label var expnShare "Share of total expenditure by age & income quantile"
label var lambda "(Expenditure Share) / (Equity Share) by age & income quantile"
label var scfCount "Number of SCF households by age & income quantile"

// order variables 
order quantile quartile age ageCat scfCount ceCount scfWgt ceWgt minInc medInc ///
	maxInc meanInc logInc sdInc minEq medEq maxEq meanEq logEq eqShare sdEq ///
		meanExpn logExpn expnShare lambda
		
// save dataset
save $cleandata/appendix/MergedDatasetRc1, replace

restore

* weights analysis 

// import rc1 dataset
use $cleandata/appendix/MergedDatasetRc1, clear

// overall relationship 
summarize scfWgt ceWgt
scatter ceWgt scfWgt 
corr ceWgt scfWgt

// relationship without the 3 outliers
summarize scfWgt ceWgt
scatter ceWgt scfWgt 
corr ceWgt scfWgt if scfWgt < 3700000

// relationship for above 80th percentile 
scatter ceWgt scfWgt if quantile >= 16
corr ceWgt scfWgt if quantile >= 16

// relationship for below 80th percentile
scatter ceWgt scfWgt if quantile < 16
corr ceWgt scfWgt if quantile < 16

* median voter lambda (MVL) estimations

// MVL (unweighted)
summarize lambda, detail

// MVL (weighted by SCF population)
summarize lambda [aweight = scfWgt], detail

// MVL (weighted by CE population)
summarize lambda [aweight = ceWgt], detail

// MVL (weighted by averageweight population)
summarize lambda [aweight = avgWeight], detail

// MVL (weighted by equity shares)
summarize lambda [aweight = eqShare], detail 

/* 

// MVL (weighted by SCF population & equity shares)
gen lambdaWgtScf = eqShare * scfWgt
summarize lambda [aweight = lambdaWgtScf], detail 

// MVL (weighted by CE population & equity shares)
gen lambdaWgtCe = eqShare * ceWgt 
summarize lambda [aweight = lambdaWgtCe], detail 

*/

clear

					* Robustness Check 2: Only By Quantile
					* ====================================

* collapsed SCF table only by quantile 

preserve 

// import cleaned dataset 
use $cleandata/scf/Scf22

// dividing income into 20 quantiles
xtile quantile = income [pweight = wgt], nq(20)
label var quantile "Income quantile of household, 1 to 20"

// collapse data
collapse (mean) meanInc = income meanEq = equity ///
		(median) medInc = income medEq = equity ///
		(min) minInc = income minEq = equity ///
		(max) maxInc = income maxEq = equity ///
		(sd) sdInc = income sdEq = equity ///
		(count) scfCount = income ///
		(sum) scfWgt = wgt [aweight = wgt], ///
		by (quantile)
		
sort quantile 

// log transformations
gen logInc = ln(meanInc)
gen logEq = ln(meanEq)

// label variables 
label var meanInc "Average income by age & income quantile"
label var logInc "Log mean income by age & income quantile"
label var maxInc "Maximum income by age & income quantile"
label var minInc "Minimum income by age & income quantile"
label var medInc "Median income by age & income quantile"
label var sdInc "Standard deviation of income by age & income quantile"
label var meanEq "Average value of equity owned by age & income quantile"
label var logEq "Log mean equity by age & income quantile"
label var minEq "Minimum value of equity owned by age & income quantile"
label var maxEq "Maximum value of equity owned by age & income quantile"
label var medEq "Median value of equity owned by age & income quantile"
label var sdEq "Standard deviation of value of equity owned by age & income quantile"
label var scfCount "Number of SCF households"
label var scfWgt "Population weight for SCF households"

// order variables
order quantile scfCount scfWgt minInc medInc maxInc meanInc logInc sdInc minEq ///
	  medEq maxEq meanEq logEq sdEq

// save collapsed dataset
save $cleandata/appendix/CollapsedScf22Rc2, replace

restore 

* collapsed CE table only by quantile 

preserve 

// import dataset
use $cleandata/ce/Ce22

// collapse data
gen ceCount = 1
collapse (sum) aggExpn = expnWgt (sum) ceWgt = popWgt (sum) ceCount, ///
		by(quantile)

sort quantile
		
// average expenditure variable
gen meanExpn = aggExpn / ceWgt

// log transformation
gen logExpn = ln(meanExpn)

// label variables
label var ceWgt "Population weight for CE households"
label var ceCount "Number of CE households by age & income quantile"
label var meanExpn "Average expenditure by age & income quantile"
label var logExpn "Log mean expenditure by age & income quantile"

// clean up
drop aggExpn 
order quantile ceCount ceWgt meanExpn logExpn

save $cleandata/appendix/CollapsedCe22Rc2, replace

restore 

* merge newly defined collapsed SCF & CE tables 

preserve 

// merge the datasets 
use $cleandata/appendix/CollapsedScf22Rc2
merge 1:1 quantile using $cleandata/appendix/CollapsedCe22Rc2
keep if _merge == 3
drop _merge

// income quartile variable 
gen quartile = 1
replace quartile = 2 if quantile >= 5 & quantile < 10
replace quartile = 3 if quantile >= 10 & quantile < 15
replace quartile = 4 if quantile >= 15

// rescale weights 
sum scfWgt
gen scfWgt2 = scfWgt / r(mean)
sum ceWgt
gen ceWgt2 = ceWgt / r(mean)

// create average weight across SCF and CE
gen avgWeight = (scfWgt2 + ceWgt2) / 2

// to construct equity & expn shares, we need to account for the weight of each cell 
gen weightedEquity = meanEq*scfWgt2
egen totalEqWgted= sum(weightedEquity)
gen eqShare = weightedEquity/totalEqWgted
drop totalEqWgted

gen weightedExpenditure = meanExpn*ceWgt2
egen totalExpWgted= sum(weightedExpenditure)
gen expnShare = weightedExpenditure/totalExpWgted 
drop totalExpWgted

// CHECK: eqShare & expnShare should add up to 1 since they say 
//        "this demo group has this share of equity & expenditure"

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

// lambda 
gen lambda = expnShare/eqShare

// label variables 
label var quartile "Income quartile of household, 1 to 4" 
label var eqShare "Share of total equity by age & income quantile"
label var expnShare "Share of total expenditure by age & income quantile"
label var lambda "(Expenditure Share) / (Equity Share) by age & income quantile"
label var scfCount "Number of SCF households by age & income quantile"

// order variables 
order quantile quartile scfCount ceCount scfWgt ceWgt minInc medInc ///
	maxInc meanInc logInc sdInc minEq medEq maxEq meanEq logEq eqShare sdEq ///
		meanExpn logExpn expnShare lambda
		
// save dataset
save $cleandata/appendix/MergedDatasetRc2, replace

restore

* weights analysis 

// import rc2 dataset
use $cleandata/appendix/MergedDatasetRc2, clear

// overall relationship 
summarize scfWgt ceWgt
scatter ceWgt scfWgt 
corr ceWgt scfWgt

// relationship for above 80th percentile 
scatter ceWgt scfWgt if quantile >= 16
corr ceWgt scfWgt if quantile >= 16

// relationship for below 80th percentile
scatter ceWgt scfWgt if quantile < 16
corr ceWgt scfWgt if quantile < 16

* median voter lambda (MVL) estimations

// MVL (unweighted)
summarize lambda, detail

// MVL (weighted by SCF population)
summarize lambda [aweight = scfWgt], detail

// MVL (weighted by CE population)
summarize lambda [aweight = ceWgt], detail

// MVL (weighted by averageweight population)
summarize lambda [aweight = avgWeight], detail

// MVL (weighted by equity shares)
summarize lambda [aweight = eqShare], detail 

/*

// MVL (weighted by SCF population & equity shares)
gen lambdaWgtScf = eqShare * scfWgt
summarize lambda [aweight = lambdaWgtScf], detail 

// MVL (weighted by CE population & equity shares)
gen lambdaWgtCe = eqShare * ceWgt 
summarize lambda [aweight = lambdaWgtCe], detail 

*/ 

clear

						* Robustness Check 3: Only By Age
						* ===============================

* collapsed SCF table only by age 

preserve 

// import cleaned dataset 
use $cleandata/scf/Scf22

// dividing income into 20 quantiles
xtile quantile = income [pweight = wgt], nq(20)
label var quantile "Income quantile of household, 1 to 20"

// collapse data
collapse (mean) meanInc = income meanEq = equity ///
		(median) medInc = income medEq = equity ///
		(min) minInc = income minEq = equity ///
		(max) maxInc = income maxEq = equity ///
		(sd) sdInc = income sdEq = equity ///
		(count) scfCount = income ///
		(sum) scfWgt = wgt [aweight = wgt], ///
		by (age)
		
sort age 

// log transformations
gen logInc = ln(meanInc)
gen logEq = ln(meanEq)

// label variables 
label var meanInc "Average income by age & income quantile"
label var logInc "Log mean income by age & income quantile"
label var maxInc "Maximum income by age & income quantile"
label var minInc "Minimum income by age & income quantile"
label var medInc "Median income by age & income quantile"
label var sdInc "Standard deviation of income by age & income quantile"
label var meanEq "Average value of equity owned by age & income quantile"
label var logEq "Log mean equity by age & income quantile"
label var minEq "Minimum value of equity owned by age & income quantile"
label var maxEq "Maximum value of equity owned by age & income quantile"
label var medEq "Median value of equity owned by age & income quantile"
label var sdEq "Standard deviation of value of equity owned by age & income quantile"
label var scfCount "Number of SCF households"
label var scfWgt "Population weight for SCF households"

// order variables
order age scfCount scfWgt minInc medInc maxInc meanInc logInc sdInc minEq ///
	  medEq maxEq meanEq logEq sdEq

// save collapsed dataset
save $cleandata/appendix/CollapsedScf22Rc3, replace

restore 

* collapsed CE table only by age 

preserve 

// import dataset
use $cleandata/ce/Ce22

// collapse data
gen ceCount = 1
collapse (sum) aggExpn = expnWgt (sum) ceWgt = popWgt (sum) ceCount, ///
		by(age)

sort age
		
// average expenditure variable
gen meanExpn = aggExpn / ceWgt

// log transformation
gen logExpn = ln(meanExpn)

// label variables
label var ceWgt "Population weight for CE households"
label var ceCount "Number of CE households by age & income quantile"
label var meanExpn "Average expenditure by age & income quantile"
label var logExpn "Log mean expenditure by age & income quantile"

// clean up
drop aggExpn 
order age ceCount ceWgt meanExpn logExpn

save $cleandata/appendix/CollapsedCe22Rc3, replace

restore 

* merge newly defined collapsed SCF & CE tables 

preserve 

// merge the datasets 
use $cleandata/appendix/CollapsedScf22Rc3
merge 1:1 age using $cleandata/appendix/CollapsedCe22Rc3
keep if _merge == 3
drop _merge

// rescale weights 
sum scfWgt
gen scfWgt2 = scfWgt / r(mean)
sum ceWgt
gen ceWgt2 = ceWgt / r(mean)

// create average weight across SCF and CE
gen avgWeight = (scfWgt2 + ceWgt2) / 2

// to construct equity & expn shares, we need to account for the weight of each cell 
gen weightedEquity = meanEq*scfWgt2
egen totalEqWgted= sum(weightedEquity)
gen eqShare = weightedEquity/totalEqWgted
drop totalEqWgted

gen weightedExpenditure = meanExpn*ceWgt2
egen totalExpWgted= sum(weightedExpenditure)
gen expnShare = weightedExpenditure/totalExpWgted 
drop totalExpWgted

// CHECK: eqShare & expnShare should add up to 1 since they say 
//        "this demo group has this share of equity & expenditure"

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

// lambda 
gen lambda = expnShare/eqShare

// label variables 
label var eqShare "Share of total equity by age & income quantile"
label var expnShare "Share of total expenditure by age & income quantile"
label var lambda "(Expenditure Share) / (Equity Share) by age & income quantile"
label var scfCount "Number of SCF households by age & income quantile"

// order variables 
order age scfCount ceCount scfWgt ceWgt minInc medInc ///
	maxInc meanInc logInc sdInc minEq medEq maxEq meanEq logEq eqShare sdEq ///
		meanExpn logExpn expnShare lambda
		
// save dataset
save $cleandata/appendix/MergedDatasetRc3, replace

restore

* weights analysis 

// import rc3 dataset
use $cleandata/appendix/MergedDatasetRc3, clear

// overall relationship 
summarize scfWgt ceWgt
scatter ceWgt scfWgt 
corr ceWgt scfWgt

* median voter lambda (MVL) estimations

// MVL (unweighted)
summarize lambda, detail

// MVL (weighted by SCF population)
summarize lambda [aweight = scfWgt], detail

// MVL (weighted by CE population)
summarize lambda [aweight = ceWgt], detail

// MVL (weighted by averageweight population)
summarize lambda [aweight = avgWeight], detail

// MVL (weighted by equity shares)
summarize lambda [aweight = eqShare], detail 

/*

// MVL (weighted by SCF population & equity shares)
gen lambdaWgtScf = eqShare * scfWgt
summarize lambda [aweight = lambdaWgtScf], detail 

// MVL (weighted by CE population & equity shares)
gen lambdaWgtCe = eqShare * ceWgt 
summarize lambda [aweight = lambdaWgtCe], detail 

*/

clear
