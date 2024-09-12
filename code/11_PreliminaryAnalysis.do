/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
Purpose: This file analyzes the trends in income, equity, expenditure, &
		 lambda using the merged SCF & CE collapsed tables
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all
set more off

use $cleandata/MainDataset.dta

							* Equity vs Income
							* ================

* scatter plot separated by age category   
sepscatter logEq logInc, separate(ageCat)

* scatter plot separated by income quartile   
sepscatter logEq logInc, separate(quartile)

* bivariate regression (subsets by age category)
quietly reg logEq logInc, vce(robust)
_eststo logEq

levelsof ageCat
local ageCatVal = r(levels)
foreach age of local ageCatVal {
	quietly reg logEq logInc if ageCat == `age', vce(robust)
	_eststo logEq_Age`age'
}
esttab, r2 ar2 se mtitles nonumbers
eststo clear

* bivariate regression (subsets by income quartile)
quietly reg logEq logInc, vce(robust)
_eststo logEq

levelsof quartile
local quartVal = r(levels)
foreach quart of local quartVal {
	quietly regress logEq logInc if quartile == `quart', vce(robust)
	_eststo logEq_Quart`quart'
}
esttab, r2 ar2 se mtitles nonumbers
eststo clear

						* Expenditure vs Income
						* =====================

* scatter plot separated by age category 
sepscatter logExpn logInc, separate(ageCat) 

* scatter plot separated by income quartile 
sepscatter logExpn logInc, separate(quartile)

* bivariate regression (subsets by age category)
quietly reg logExpn logInc, vce(robust)
_eststo logExpn

levelsof ageCat
local ageCatVal = r(levels)
foreach age of local ageCatVal {
	quietly reg logExpn logInc if ageCat == `age', vce(robust)
	_eststo logExpn_Age`age'
}
esttab, r2 ar2 se mtitles nonumbers
eststo clear

* bivariate regression (subsets by income quartile)
quietly reg logExpn logInc, vce(robust)
_eststo logExpn

levelsof quartile
local quartval = r(levels)
foreach quart of local quartval {
	quietly regress logExpn logInc if quartile == `quart', vce(robust)
	_eststo logExpn_Quartile`quart'
}
esttab, r2 ar2 se mtitles nonumbers
eststo clear 

						* Expenditure vs Equity
						* =====================

* scatter plot separated by income quartile
sepscatter logExpn logEq, separate(quartile)

* scatter plot separated by age category 
sepscatter logExpn logEq, separate(ageCat)

* bivariate regression output (subsets by income quartile)
quietly reg logExpn logEq, vce(robust)
_eststo logExpn

levelsof quartile
local quartVal = r(levels)
foreach quart of local quartVal {
	quietly regress logExpn logEq if quartile == `quart', vce(robust)
	_eststo logExpn_Quartile`quart'
}
esttab, r2 ar2 se mtitles nonumbers
eststo clear

* bivariate regression output (subsets by age category)
quietly reg logExpn logEq, vce(robust)
_eststo logExpn

levelsof ageCat
local agecatval = r(levels)
foreach age of local agecatval {
	quietly reg logExpn logEq if ageCat == `age', vce(robust)
	_eststo logExpn_Age`age'
}
esttab, r2 ar2 se mtitles nonumbers
eststo clear

						* Expenditure vs Equity Shares 
						* ============================

* scatter plot separated by income quartile 
binscatter expnShare eqShare if eqShare < 0.015, by(quartile) linetype(none)

* bivariate regression (subsets by income quartile)
quietly reg expnShare eqShare, vce(robust)
_eststo expnShare

levelsof quart
local quartVal = r(levels)
foreach quart of local quartVal {
	quietly regress expnShare eqShare if quartile == `quart', vce(robust)
	_eststo expnShare_Quartile`quart'
}
esttab, r2 ar2 se mtitles nonumbers
eststo clear

* bivariate regression (subsets by age category)
quietly reg expnShare eqShare, vce(robust)
_eststo expnShare

levelsof ageCat
local ageCatVal = r(levels)
foreach age of local ageCatVal {
	quietly reg expnShare eqShare if ageCat == `age', vce(robust)
	_eststo expnShare_Age`age'
}
esttab, r2 ar2 se mtitles nonumbers
eststo clear 

						* Expenditure vs Income & Equity
						* ==============================

* multivariate regression 			
reg logExpn logEq logInc, vce(robust) 

						* Median Voter Lambda (Made Up Data)
						* ==================================

/*
* import dataset 
preserve 

clear
use $cleandata/Simulation

* median voter lambda (unweighted)
summarize lambda, detail 

* median voter lambda (weighted by population)
summarize lambda [aweight = personWeight], detail

* median voter lambda (weighted by equity share)
summarize lambda [aweight = equityShare], detail

* median voter lambda (weighted by population & equity share
gen wgt = personWeight * equityShare
summarize lambda [aweight = wgt], detail 

restore 
*/

						
					   * Median Voter Lambda (Real Data)
					   * ===============================
					   
* analyzing the CE and SCF population weights

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

// MVL (weighted by equity shares)
summarize lambda [aweight = eqShare], detail 

// MVL (weighted by SCF population & equity shares)
gen lambdaWgtScf = eqShare * scfWgt
summarize lambda [aweight = lambdaWgtScf], detail 

// MVL (weighted by CE population & equity shares)
gen lambdaWgtCe = eqShare * ceWgt 
summarize lambda [aweight = lambdaWgtCe], detail 
