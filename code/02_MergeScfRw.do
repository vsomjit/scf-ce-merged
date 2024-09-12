/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
Purpose: This file merges the cleaned SCF dataset with its replicate weights. I 
		 follow the guidelines provided by Charlie Rafkin in his documentation 
		 for the scfses package (https://github.com/crafkin/scfses). 
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all
set more off

			* Step 1: Cleaning the raw replicate weights file 
			* ===============================================

* import dataset containing replicate weights (rw)
use $rawdata/scf/p22_rw1.dta

* rename merge column 
rename (y1) (id)
label var id "yy1 * 10 + imputation replicate number (1-5)"

* drop case ID 
drop yy1 

		* Step 2: Merging cleaned scf data to replicate weights file  
		* ==========================================================
					
* merge datasets 
merge 1:1 id using $cleandata/scf/Scf22, nogenerate

sort iid id // NOTE: if the data is not sorted, the SE estimates are wrong

* generating rep variable that counts the implicate number
gen rep = .

local totalN = _N

forval i = 1 / `totalN' {
    if mod(`i' - 1, 5) == 0 {
        replace rep = 1 in `i'
    }
    else {
        replace rep = rep[_n-1] + 1 in `i'
    }
}
label var rep "Implicate index"

* order variables 
order iid id rep wgt0 wgt age income wageInc busseFarmInc intDivInc kgInc ///
		ssRetInc transfothInc rentInc normInc stMutf tfBMutf gBMutf oBMutf ///
		coMutf oMutf nMmf hNmmf stocks hStock nStock noTxBnd mortBnd govtBnd ///
		oBnd bond hBond iRakh thrift penEq futPen currPen retQliq hRetQliq ///
		annuit trusts othma hOthma equity hEquity dEq savEq retEq equitInc ///
		faEquity, first

* save merged dataset 
save $cleandata/scf/MergedScf22, replace
