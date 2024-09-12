/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
Purpose: This file cleans the FMLD and EXPD files for 2022 to produce a 
		 merged "Diary" dataset. I roughly follow the STATA sample code titled
		 'Aggregates selected UCCs' provided by the BLS:
		 https://www.bls.gov/cex/pumd-getting-started-guide.htm#section5
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all
set more off

								* FMLD file
								* =========
								
* import dataset
use $rawdata/ce/diary22/fmld221
append using $rawdata/ce/diary22/fmld222
append using $rawdata/ce/diary22/fmld223
append using $rawdata/ce/diary22/fmld224
	
rename *, lower

keep newid finlwt21 age_ref fincbefm

rename (newid finlwt21 fincbefm age_ref) (id wgt income ageRef)

* age variable
gen age = "29 & below"
replace age = "30 - 39" if ageRef >= 30 & ageRef < 40
replace age = "40 - 49" if ageRef >= 40 & ageRef < 50
replace age = "50 - 59" if ageRef >= 50 & ageRef < 60
replace age = "60 - 69" if ageRef >= 60 & ageRef < 70
replace age = "70 - 79" if ageRef >= 70 & ageRef < 80
replace age = "80 & above" if ageRef >= 80 

drop ageRef

* label variables 
label var id "Unique identifier for households"
label var wgt "Original weight"
label var age "Age of reference person"
label var income "Total (imputed) family income before taxes"

* save cleaned dataset 
save $cleandata/ce/Fmld22, replace
clear

								* EXPD file
								* =========
								
* import dataset 
use $rawdata/ce/diary22/expd221
append using $rawdata/ce/diary22/expd222
append using $rawdata/ce/diary22/expd223
append using $rawdata/ce/diary22/expd224
		
rename *, lower
		
keep newid cost pub_flag
rename (newid pub_flag) (id pubFlag)

keep if pubFlag == "2"
		
* expenditure aggregates by newid
collapse (sum) expn = cost, by(id)
label var expn "Total (imputed) expenditure of household"

* save cleaned dataset 
save $cleandata/ce/Expd22, replace
clear

						  * Merge the two datasets
						  * ======================
						  
* merging the two datasets
use $cleandata/ce/Fmld22
merge 1:1 id using $cleandata/ce/Expd22, nogenerate
drop if expn == .

* month scope & survey indicator
gen moScope = 3
label var moScope "Number of months in scope"
gen survey = 1
label var survey "Survey indicator: 0 = interview, 1 = diary"

* order variables 
order id age income expn wgt moScope survey

* save merged dataset 
save $cleandata/ce/Diary22, replace
