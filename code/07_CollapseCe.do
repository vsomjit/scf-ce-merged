/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
Purpose: This file collapses the cleaned CE dataset, aggregated by income
		 quantile and age category. The calculation of average expenditure 
		 follows the documentation provided by BLS:
		 https://www.bls.gov/cex/pumd-getting-started-guide.htm#section6
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all
set more off

							* Collapsed CE dataset
							* =====================

* import dataset
use $cleandata/ce/Ce22

* collapse data
gen ceCount = 1
collapse (sum) aggExpn = expnWgt (sum) ceWgt = popWgt (sum) ceCount, ///
		by(age quantile)

sort quantile age
		
* average expenditure variable
gen meanExpn = aggExpn / ceWgt

* log transformation
gen logExpn = ln(meanExpn)

* label variables
label var ceWgt "Population weight for CE households"
label var ceCount "Number of CE households by age & income quantile"
label var meanExpn "Average expenditure by age & income quantile"
label var logExpn "Log mean expenditure by age & income quantile"

* clean up
drop aggExpn 
order quantile age ceCount ceWgt meanExpn logExpn

save $cleandata/ce/CollapsedCe22, replace

