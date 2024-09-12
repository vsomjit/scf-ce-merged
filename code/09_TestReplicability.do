/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
Purpose: This file checks if the descriptive statistics produced by the SCF & 
		 CE cleaned datasets match those in published reports. I compared my 
		 results with the following two reports:
		 1. https://www.federalreserve.gov/publications/files/scf23.pdf
		 2. https://www.bls.gov/cex/tables/calendar-year/mean/cu-all-detail-2022.pdf

--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all 
set more off

* set number of draws for bootstapping; higher is better, but takes longer
local ndraws = 999

						* SCF Descriptive Statistics
						* ==========================

preserve
					
* import dataset (can import entire dataset if not using Stata BE)
use iid id wgt rep income equity wt* mm* using $cleandata/scf/MergedSCF22

* income (for perfect match, multiply by 1.0809 to adjust for inflation)

// summary statistics 
summarize income [aweight = wgt], detail

// SE of mean 
scfses income [pweight = wgt], p(mean) numberdraws(`ndraws')

// SE of median 
scfses income [pweight = wgt], p(50) numberdraws(`ndraws')

// selected percentiles
_pctile income [pweight = wgt], p(20 40 50 60 80 90)
return list

* equity 

//summary statistics 
summarize equity [aweight = wgt], detail

// SE of mean equity
scfses equity [pweight = wgt], p(mean) numberdraws(`ndraws')

// SE of median equity 
scfses equity [pweight = wgt], p(50) numberdraws(`ndraws')

// selected equity percentiles
_pctile equity [pweight = wgt], p(20 40 50 60 80 90)
return list

* equity (conditional on holding)

// summary statistics 
summarize equity [aweight = wgt] if equity > 0, detail

// SE of mean equity
scfses equity [pweight = wgt] if equity > 0, p(mean) numberdraws(`ndraws')

// SE of median equity 
scfses equity [pweight = wgt] if equity > 0, p(50) numberdraws(`ndraws')

// selected equity percentiles
_pctile equity [pweight = wgt] if equity > 0, p(20 40 50 60 80 90)
return list

restore

						* CE Descriptive Statistics
						* ==========================

preserve 

* import dataset
use $cleandata/ce/Ce22

* mean expenditures 
egen aggPop = sum(popWgt)
egen aggExpn = sum(expnWgt)
gen meanExpn = aggExpn/aggPop
display meanExpn

restore 
