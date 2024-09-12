/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
Purpose: This file cleans the FMLI and MTBI files for 2022 to produce a merged 
		 "Interview" dataset. I roughly follow the STATA sample code titled
		 'Aggregates selected UCCs' provided by the BLS:
		 https://www.bls.gov/cex/pumd-getting-started-guide.htm#section5
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all
set more off

								* FMLI file
								* =========
								
* import dataset 
  // NOTE: Have to use the 2021 FMLI file to access the first quarter of 2022
use $rawdata/ce/intrvw21/fmli221
append using $rawdata/ce/intrvw22/fmli222
append using $rawdata/ce/intrvw22/fmli223
append using $rawdata/ce/intrvw22/fmli224
append using $rawdata/ce/intrvw22/fmli231
	
drop fftaxowe fstaxowe // these unnecessary variabels are already in lower case
rename *, lower 
	
keep newid finlwt21 qintrvyr qintrvmo age_ref fincbtxm

rename (newid finlwt21 fincbtxm age_ref qintrvyr qintrvmo) ///
		(id wgt income ageRef qIntrvYr qIntrvMo)

* age variable 
gen age = "29 & below"
replace age = "30 - 39" if ageRef >= 30 & ageRef < 40
replace age = "40 - 49" if ageRef >= 40 & ageRef < 50
replace age = "50 - 59" if ageRef >= 50 & ageRef < 60
replace age = "60 - 69" if ageRef >= 60 & ageRef < 70
replace age = "70 - 79" if ageRef >= 70 & ageRef < 80
replace age = "80 & above" if ageRef >= 80 

drop ageRef  

* monthly scope variable 
gen month = real(qIntrvMo)
gen moScope = 3
replace moScope = month - 1 if month <= 3 & qIntrvYr == "2022"
replace moScope = 4 - month if month <= 3 & qIntrvYr == "2023"

drop qIntrvYr qIntrvMo month

* label variables 
label var id "Unique identifier for households"
label var wgt "Original weight"
label var moScope "Number of months in scope"
label var age "Age of reference person"
label var income "Total (imputed) family income before taxes"

* save cleaned dataset 
save $cleandata/ce/Fmli22, replace	
clear	

								* MTBI file
								* =========

* import dataset
  // NOTE: Have to use the 2021 MTBI file to access the first quarter of 2022
use $rawdata/ce/intrvw21/mtbi221
append using $rawdata/ce/intrvw22/mtbi222
append using $rawdata/ce/intrvw22/mtbi223
append using $rawdata/ce/intrvw22/mtbi224
append using $rawdata/ce/intrvw22/mtbi231
	
rename *, lower 
	
keep newid cost ref_yr pubflag
rename (newid ref_yr pubflag) (id refYr pubFlag)

keep if pubFlag == "2"
keep if refYr == "2021" 
	// NOTE: refYr = 2022 contains the exact same costs as 2021, but doubles 
	// each data point. Therefore, only refYr = 2021 matches published reports. 
	// This is also what the BLS sample code does. 

* expenditure aggregates by newid 
collapse (sum) expn = cost, by(id)
label var expn "Total (imputed) expenditure of household"

* save cleaned dataset 
save $cleandata/ce/Mtbi22, replace
clear

						  * Merge the two datasets
						  * ======================

* merge fmli and mtbi on newid 
use $cleandata/ce/Fmli22
merge 1:1 id using $cleandata/ce/Mtbi22, nogenerate 
drop if expn == . 

* survey indicator 
gen survey = 0
label var survey "Survey indicator: 0 = interview, 1 = diary"

* order variables 
order id age income expn wgt moScope survey

* save merged dataset 
save $cleandata/ce/Intrvw22, replace
