/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
Purpose: This file collapses the cleaned SCF dataset, aggregating by income 
		 quantile and age category
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all 
set more off

							* Collapsed SCF dataset
							* =====================

* import cleaned dataset 
use $cleandata/scf/Scf22

* dividing income into 20 quantiles
xtile quantile = income [pweight = wgt], nq(20)
label var quantile "Income quantile of household, 1 to 20"

* collapse data
collapse (mean) meanInc = income meanEq = equity ///
		(median) medInc = income medEq = equity ///
		(min) minInc = income minEq = equity ///
		(max) maxInc = income maxEq = equity ///
		(sd) sdInc = income sdEq = equity ///
		(count) scfCount = income ///
		(sum) scfWgt = wgt [aweight = wgt], ///
		by (quantile age)
		
sort quantile age

* log transformations
gen logInc = ln(meanInc)
gen logEq = ln(meanEq)

* label variables 
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

* order variables
order quantile age scfCount scfWgt minInc medInc maxInc meanInc logInc sdInc minEq ///
	  medEq maxEq meanEq logEq sdEq

* save collapsed dataset
save $cleandata/scf/CollapsedScf22, replace
