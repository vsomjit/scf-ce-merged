/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
Purpose: This file takes the Interview & Diary datasets, appends them, and 
		 attributes appropriate weights to the variables. To correctly weight 
		 the variables, I follow the documentation provided by the BLS:
		 https://www.bls.gov/cex/pumd-getting-started-guide.htm#section6
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all
set more off

					     * Appending the datasets
					     * ======================

* append datasets
use $cleandata/ce/Intrvw22
append using $cleandata/ce/Diary22

* drop negative income
drop if income < 0

* income quantile 
xtile quantile = income [pweight = wgt], nq(20)
label var quantile "Income quantile of household, 1 to 20"


				   * Weighting population and expenditure
				   * ====================================

* generate aggregate population weight
gen popWgt = (wgt/4) * (moScope/3)
label var popWgt "Revised population weight"

* generate weighted expenditure
gen expnWgt = expn * wgt if survey == 0
replace expnWgt = expn * wgt * 13 if survey == 1
label var expnWgt "Weighted expenditure of household"

* clean up
drop moScope survey wgt 
order id age popWgt expn expnWgt income quantile   

* save appended dataset
save $cleandata/ce/Ce22, replace 
