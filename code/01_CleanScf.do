/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
Purpose: This file cleans the SCF dataset. I follow the methodology outlined by 
		 the Fed in their sample SAS code:
		 https://www.federalreserve.gov/econres/files/bulletin.macro.txt
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all
set more off

                             * Import the dataset  
						     * ==================

* import specific variables 
use yy1 y1 x42001 x5729 x3915 x3821 x3822 x3829 x3830 x7785 x7787 x6577 ///
	x6587 x6551 x6559 x6567 x6552 x6560 x6568 x6553 x6561 x6569 x6554 x6562 /// 
	x6570 x5604 x5612 x5620 x5628 x6462 x6467 x6472 x6477 x6957 x6465 x6470 /// 
	x6475 x6480 x6966 x6972 x6978 x6984 x6558 x6566 x6574 x6464 x6469 x6474 /// 
	x6479 x6965 x6971 x6977 x6983 x6778 x5702 x5704 x5714 x5706 x5708 x5710 /// 
	x5712 x5722 x5716 x5718 x5720 x5724 x7362 x7650 x3823 x3824 x3825 x3826 /// 
	x3827 x3828 x3914 x3910 x3906 x3908 x7634 x7633 x6555 x6556 x6563 x6564 ///
	x6571 x6572 x6581 x6582 x6591 x6592 x6461 x6933 x6934 x6466 x6937 x6938 /// 
	x6471 x6941 x6942 x6476 x6945 x6946 x6962 x6963 x6968 x6969 x6974 x6975 /// 
	x6980 x6981 x3730 x7074 x7075 x3736 x7077 x7078 x3742 x7080 x7081 x3748 /// 
	x7083 x7084 x3754 x7086 x7087 x3760 x7089 x7090 x11000 x11100 x11300 ///
	x11400 x11001 x11101 x11301 x11401 x11032 x11132 x11332 x11432 x11025 ///
	x11125 x11325 x11425 x11031 x11131 x11331 x11431 x11036 x11136 x11336 ///
	x11436 x11037 x11137 x11337 x11437 x11259 x11559 x14 x3129 x3124 x3126 ///
	x3127 x3121 x3122 x3130 x3119 x3229 x3224 x3226 x3227 x3221 x3222 x3230 ///
	x3219 x3420 using $rawdata/scf/p22i6.dta
	
* id variables 
rename (yy1 y1) (iid id) 
label var iid "Case ID number"
label var id "yy1 * 10 + imputation replicate number (1-5)"

* age variable
gen age = "29 & below"
replace age = "30 - 39" if x14 >= 30 & x14 < 40
replace age = "40 - 49" if x14 >= 40 & x14 < 50
replace age = "50 - 59" if x14 >= 50 & x14 < 60
replace age = "60 - 69" if x14 >= 60 & x14 < 70
replace age = "70 - 79" if x14 >= 70 & x14 < 80
replace age = "80 & above" if x14 >= 80 

label var age "Age of reference person from household"

* only keep observations with valid id and weight
keep if (iid > 0 & id > 0 & x42001 > 0)

* original weight variable 
rename (x42001) (wgt0)
label var wgt0 "Revised Kennickell-Woodburn consistent weight"


* divide weight by 5 so totals estimated on the 5 implicates jointly are correct
gen wgt = wgt0 / 5
label var wgt "wgt0 / 5"

							* Income variables 
							* ================

* total HH income - (IRA + pension withdrawals)
gen income = cond(x5729 >= 0, x5729, 0)

* convert pension withdrawal frequency to annual frequency 
local accountList x6465 x6470 x6475 x6480 x6966 x6972 x6978 x6984
foreach account of local accountList {
	replace `account' = 12 if `account' == 4 // monthly withdrawals
	replace `account' = 4 if `account' == 5 // quarterly withdrawals 
	replace `account' = 1 if `account' == 6 // yearly withdrawals 
	replace `account' = 0 if `account' == -1 // no withdrawals
}

* value of ira and pension withdrawals 
gen penAcctWd = x6558 + x6566 + x6574 + cond(x6464 > 0, x6464 * x6465, 0) ///
				+ cond(x6469 >= 0, x6469 * x6470, 0) ///
				+ cond(x6474 >= 0, x6474 * x6475, 0) ///
				+ cond(x6479 >= 0, x6479 * x6480, 0) ///
				+ cond(x6965 >= 0, x6965 * x6966, 0) ///
				+ cond(x6971 >= 0, x6971 * x6972, 0) ///
				+ cond(x6977 >= 0, x6977 * x6778, 0) ///
				+ cond(x6983 >= 0, x6983 * x6984, 0)
				
label var penAcctWd "Annual withdrawals from IRAs and tax-deferred pension accounts"

* add pension withdrawals to income 
replace income = income + penAcctWd
label var income "Total family income before taxes in 2021"

* HH income components 
gen wageInc = x5702
label var wageInc "Income from wages and salaries"

gen busseFarmInc = x5704 + x5714
label var busseFarmInc "Income from business / farm"

gen intDivInc = x5706 + x5708 + x5710
label var intDivInc "Income from dividends and interest"

gen kgInc = x5712
label var kgInc "Income from sale of stocks"

gen ssRetInc = x5722 + penAcctWd
label var ssRetInc "Income from Social Security and other retirement programs"

gen transfothInc = x5716 + x5718 + x5720 + x5724
label var transfothInc "Income from government transfer payments"

gen rentInc = x5714
label var rentInc "Income from rent"

* normal income 
gen normInc = income 
replace normInc = (cond(x7362 >= 0, x7362, 0) + penAcctWd) if x7650 != 3
label var normInc "Expected income in a 'normal' year"

* clean up
drop penAcctWd

					* Financial assets & related variables
					* ====================================

* mututal funds 
gen stMutf = (x3821 == 1) * cond(x3822 >= 0, x3822, 0)
label var stMutf "$$ in stock mutual funds"

gen tfBMutf = (x3823 == 1) * cond(x3824 >= 0, x3824, 0)
label var tfBMutf "$$ in tax-free bond mutual funds"

gen gBMutf = (x3825 == 1) * cond(x3826 >= 0, x3826, 0)
label var gBMutf "$$ in government-backed bond mutual funds"

gen oBMutf = (x3827 == 1) * cond(x3828 >= 0, x3828, 0)
label var oBMutf "$$ in other bond mutual funds"

gen coMutf = (x3829 == 1) * cond(x3830 >= 0, x3830, 0)
label var coMutf "$$ in combination mutual funds"

gen oMutf = (x7785 == 1) * cond(x7787 >= 0, x7787, 0)
label var oMutf "$$ in any other mutual funds"

gen nMmf = stMutf + tfBMutf + gBMutf + oBMutf + coMutf + oMutf
label var nMmf "$$ in any mutual funds, exlcuding MMFs"

gen hNmmf = (nMmf > 0)
label var hNmmf "Have mutual funds? 1 = yes, 0 = no"


* stocks
gen stocks = cond(x3915 >= 0, x3915, 0)
label var stocks "$$ in stocks"

gen hStock = (stocks > 0)
label var hStock "Have directly held stocks? 1 = yes, 0 = no"

rename (x3914) (nStock)
label var nStock "Number of different companies in which stock is held"

* bonds, exlcuding bond funds or savings bonds
rename (x3910) (noTxBnd)
label var noTxBnd "$$ in tax-exempt bonds"

rename (x3906) (mortBnd)
label var mortBnd "$$ in mortgage-backed bonds"

rename (x3908) (govtBnd)
label var govtBnd "$$ in US government and government agency bonds and bills"

gen oBnd = x7634 + x7633 
label var oBnd "$$ in corporate and foreign bonds"

gen bond = noTxBnd + mortBnd + govtBnd + oBnd
label var bond "$$ in all types of bonds, excluding bond funds or saving bonds"

gen hBond = (bond>0)
label var hBond "Have bonds? 1 = yes, 0 = no"

* quasi-liquid retirement accounts (iras and thrift-type accounts)
egen iRakh = rowtotal(x6551 x6559 x6567 x6552 x6560 x6568 x6553 x6561 x6569 ///
						x6554 x6562 x6570)
label var iRakh "$$ in individual retirement accounts / Keoghs"
						
/* account-type pension plans (included if type is 401k, 403b, thrift, savings, 
	SRA, or if participant has option to borrow or withdraw */

// defining local variables 
local pType1 x11000 x11100 x11300 x11400
local pType2 x11001 x11101 x11301 x11401
local pAmt x11032 x11132 x11332 x11432
local pBor x11025 x11125 x11325 x11425
local pWit x11031 x11131 x11331 x11431
local pAll x11036 x11136 x11336 x11436
local pPct x11037 x11137 x11337 x11437

// generating initialization variables 
gen thrift = 0
gen penEq = 0
gen rThrift = 0 
gen sThrift = 0
gen rEq = 0
gen sEq = 0 
gen pMop = 0

// calculating PENEQ 
local pType1_n: word count `pType1'

forvalues i = 1/`pType1_n' {
	local pType1_var: word `i' of `pType1'
	local pType2_var: word `i' of `pType2'
	local pAmt_var: word `i' of `pAmt'
	local pBor_var: word `i' of `pBor'
	local pWit_var: word `i' of `pWit'
	local pAll_var: word `i' of `pAll'
	local pPct_var: word `i' of `pPct'
	
	gen hold_`i' = max(0, `pAmt_var') * ( ///
				`pType1_var' == 1 | ///
				inlist(`pType2_var', 2, 3, 4, 6, 20, 21, 22, 26) | ///
				`pBor_var' == 1 | ///
				`pWit_var' == 1)
	
	if `i' <= 2 {
		replace rThrift = rThrift + hold_`i'
	}
	else {
		replace sThrift = sThrift + hold_`i'
	}
	
	replace thrift = thrift + hold_`i'
	
	replace penEq = penEq + hold_`i' * ((`pAll_var' == 1) + ///
			inlist(`pAll_var', 3, 30) * max(0, `pPct_var') / 10000)
	
	if `i' <= 2 {
		replace rEq = penEq
	}
	else {
		replace sEq = penEq - rEq
	}
} 

// allocate the pension mopups
if x11259 > 0 {
	if (x11000 == 1 | x11100 == 1 | ///
		inlist(x11001, 2, 3, 4, 6, 20, 21, 22, 26) | /// 
		inlist(x11101, 2, 3, 4, 6, 20, 21, 22, 26) | ///
		x11031 == 1 | x11131 == 1 | x11025 == 1 | x11125 == 1) {
		replace pMop = x11259
		}
	else if (x11000 != 0 & x11100 != 0 & x11031 != 0 & x11131 != 0) {
		replace pMop = 0
	}
	else {
		replace pMop = x11259
	}
	
	replace thrift = thrift + pMop 
	
	if rEq > 0 {
		replace penEq = penEq + pMop * (rEq / rThrift)
	}
	else {
		penEq = penEq + (pMop / 2)
	}
}

if x11559 > 0 {
	if (x11300 == 1 | x11400 == 1 | ///
		inlist(x11301, 2, 3, 4, 6, 20, 21, 22, 26) | ///
		inlist(x11401, 2, 3, 4, 6, 20, 21, 22, 26) | ///
		x11331 == 1 | x11431 == 1 | x11325 == 1 | x11425 == 1 |){
		replace pMop = x11559
		}
	else if (x11300 != 0 & x11400 != 0 & x11331 != 0 & x11431 != 0){
		replace pMop = 0
	}
	else {
		replace pMop = x11559
	}
		
	replace thrift = thrift + pMop 
	
	if sEq > 0 { 
		replace penEq = penEq + pMop * (sEq / sThrift)
	}
	else{
		replace penEq = penEq + (pMop / 2)
	}
}

// clean up
drop hold_1 hold_2 hold_3 hold_4 pMop rThrift sThrift rEq sEq
label var thrift "$$ in thrift accounts"
label var penEq "Thrift amounts invested in stock"

gen futPen = max(0, x5604) + max(0, x5612) + max(0, x5620) + max(0, x5628)
label var futPen "$$ in future pension accounts"

gen currPen = x6462 + x6467 + x6472 + x6477 + x6957
label var currPen "$$ in current pension accunts"

gen retQliq = iRakh + thrift + futPen + currPen
label var retQliq "$$ in all quasi-liquid accounts"

gen hRetQliq = (retQliq > 0)
label var hRetQliq "Have quasi-liquid assets? 1 = yes, 0 = no"

* other managed assets in which HH has equity interest

gen annuit = cond(x6577 >= 0, x6577, 0)
label var annuit "$$ in annuities"

gen trusts = cond(x6587 >= 0, x6587, 0)
label var trusts "$$ in trusts"

gen othma = annuit + trusts
label var othma "$$ in annuities and trusts"

gen hOthma = (othma > 0)
label var hOthma "Have other managed assets? 1 = yes, 0 = no"

* value of financial assets invested in stocks

gen equity = stocks + stMutf + (0.5 * coMutf) + oMutf + ///
        (x6551 + x6552 + x6553 + x6554) * ///
		((x6555 == 1) + (inlist(x6555, 3, 30)) * (max(0, x6556) / 10000)) + ///
        (x6559 + x6560 + x6561 + x6562) * ///
		((x6563 == 1) + (inlist(x6563, 3, 30)) * (max(0, x6564) / 10000)) + ///
        (x6567 + x6568 + x6569 + x6570) * ///
		((x6571 == 1) + (inlist(x6571, 3, 30)) * (max(0, x6572) / 10000)) + ///
        annuit * ///
		((x6581 == 1) + (inlist(x6581,3, 30)) * (max(0,x6582) / 10000)) + ///
		trusts * ///
		((x6591 == 1) + (inlist(x6591, 3, 30)) * (max(0, x6592) / 10000)) + ///
		penEq + (x6461 == 1) * x6462 * ///
		((x6933 == 1) + (inlist(x6933, 3, 30)) * (max(0, x6934) / 10000)) + ///
		(x6466 == 1) * x6467 * ///
		((x6937 == 1) + (inlist(x6937, 3, 30)) * (max(0, x6938) / 10000)) + ///
        (x6471 == 1) * x6472 * ///
		((x6941 == 1) + (inlist(x6941, 3, 30)) * (max(0, x6942) / 10000)) + ///
		(x6476 == 1) * x6477 * ///
		((x6945 == 1) + (inlist(x6945, 3, 30)) * (max(0, x6946) / 10000)) + ///
        x5604 * ///
		((x6962 == 1) + (inlist(x6962, 3, 30)) * (max(0, x6963) / 10000)) + ///
		x5612 * ///
		((x6968 == 1) + (inlist(x6968, 3, 30)) * (max(0, x6969) / 10000)) + ///
        x5620 * ///
		((x6974 == 1) + (inlist(x6974, 3, 30)) * (max(0, x6975) / 10000)) + ///
        x5628 * ///
		((x6980 == 1) + (inlist(x6980, 3, 30)) * (max(0, x6981) / 10000)) + ///
        x3730 * ///
		((x7074 == 1) + (inlist(x7074, 3, 30)) * (max(0, x7075) / 10000)) + ///
        x3736 * ///
		((x7077 == 1) + (inlist(x7077, 3, 30)) * (max(0, x7078) / 10000)) + ///
        x3742 * ///
		((x7080 == 1) + (inlist(x7080, 3, 30)) * (max(0, x7081) / 10000)) + ///
        x3748 * ///
		((x7083 == 1) + (inlist(x7083, 3, 30)) * (max(0, x7084) / 10000)) + ///
        x3754 * ///
		((x7086 == 1) + (inlist(x7086, 3, 30)) * (max(0, x7087) / 10000)) + ///
        x3760 * ///
		((x7089 == 1) + (inlist(x7089, 3, 30)) * (max(0, x7090) / 10000)) 
label var equity "Total $$ invested in stocks in any form"

gen hEquity = (equity > 0)
label var hEquity "Have stock equity? 1 = yes, 0 = no"

gen dEq = stocks + stMutf + (0.5 * coMutf) + oMutf
label var dEq "Equity in stocks and mutual funds"

gen savEq = x3730 * ((x7074 == 1) + (x7074 == 3) * (max(0, x7075) / 10000)) + ///
			x3736 * ((x7077 == 1) + (x7077 == 3) * (max(0, x7078) / 10000)) + ///
			x3742 * ((x7080 == 1) + (x7080 == 3) * (max(0, x7081) / 10000)) + ///
			x3748 * ((x7083 == 1) + (x7083 == 3) * (max(0, x7084) / 10000)) + ///
			x3754 * ((x7086 == 1) + (x7086 == 3) * (max(0, x7087) / 10000)) + ///
			x3760 * ((x7089 == 1) + (x7089 == 3) * (max(0, x7090) / 10000)) 
label var savEq "Equity in savings accounts such as 529s and Coverdells"

gen retEq = x6551 + x6552 + x6553 + x6554 * ///
		((x6555 == 1) + (inlist(x6555, 3, 30)) * (max(0, x6556) / 10000)) + ///
        (x6559 + x6560 + x6561 + x6562) * ///
		((x6563 == 1) + (inlist(x6563, 3, 30)) * (max(0, x6564) / 10000)) + ///
        (x6567 + x6568 + x6569 + x6570) * ///
		((x6571 == 1) + (inlist(x6571, 3, 30)) * (max(0, x6572) / 10000)) + ///
		penEq + (x6461 == 1) * x6462 * ///
		((x6933 == 1) + (inlist(x6933, 3, 30)) * (max(0, x6934) / 10000)) + ///
		(x6466 == 1) * x6467 * ///
		((x6937 == 1) + (inlist(x6937, 3, 30)) * (max(0, x6938) / 10000)) + ///
        (x6471 == 1) * x6472 * ///
		((x6941 == 1) + (inlist(x6941, 3, 30)) * (max(0, x6942) / 10000)) + ///
		(x6476 == 1) * x6477 * ///
		((x6945 == 1) + (inlist(x6945, 3, 30)) * (max(0, x6946) / 10000)) + ///
        x5604 * ///
		((x6962 == 1) + (inlist(x6962, 3, 30)) * (max(0, x6963) / 10000)) + ///
		x5612 * ///
		((x6968 == 1) + (inlist(x6968, 3, 30)) * (max(0, x6969) / 10000)) + ///
        x5620 * ///
		((x6974 == 1) + (inlist(x6974, 3, 30)) * (max(0, x6975) / 10000)) + ///
        x5628 * ///
		((x6980 == 1) + (inlist(x6980, 3, 30)) * (max(0, x6981) / 10000))
label var retEq "Equity in quasi-liquid retirement assets"

gen equitInc = equity / max(100, normInc)
label var equitInc "Ratio of equity to normal income "

gen faEquity = stocks + nMmf + (x6551 + x6552 + x6553 + x6554) * ///
		((x6555 == 1) + (inlist(x6555, 3, 30)) * (max(0, x6556) / 10000)) + ///
        (x6559 + x6560 + x6561 + x6562) * ///
		((x6563 == 1) + (inlist(x6563, 3, 30)) * (max(0, x6564) / 10000)) + ///
        (x6567 + x6568 + x6569 + x6570) * ///
		((x6571 == 1) + (inlist(x6571, 3, 30)) * (max(0, x6572) / 10000)) + ///
        annuit * ///
		((x6581 == 1) + (inlist(x6581,3, 30)) * (max(0,x6582) / 10000)) + ///
		trusts * ///
		((x6591 == 1) + (inlist(x6591, 3, 30)) * (max(0, x6592) / 10000)) + ///
		(0.5 * (max(0, x3129) + max(0, x3124) - max(0, x3126) * ///
		(x3127 == 5) + max(0, x3121) * (inlist(x3122, 1, 6))) + ///
		0.5 * (max(0, x3130))) * (inlist(x3119, 3, 4)) + ///
		(0.5 * (max(0, x3229) + max(0, x3224) - max(0, x3226) * ///
		(x3227 == 5) + max(0, x3221) * (inlist(x3222, 1, 6))) + ///
		0.5 * (max(0, x3230))) * (inlist(x3219, 3, 4)) + ///
		max(0, x3420) + savEq - (0.49 * oMutf)
label var faEquity "Equity in stocks, mutual funds, OTHMA, IRAS, and C-Corps"

								* Cleaned dataset
								* ===============

* drop all unnamed variables
drop x*

* order variables 
order iid id wgt0 wgt age income wageInc busseFarmInc intDivInc kgInc ///
		ssRetInc transfothInc rentInc normInc stMutf tfBMutf gBMutf oBMutf ///
		coMutf oMutf nMmf hNmmf stocks hStock nStock noTxBnd mortBnd govtBnd ///
		oBnd bond hBond iRakh thrift penEq futPen currPen retQliq hRetQliq ///
		annuit trusts othma hOthma equity hEquity dEq savEq retEq equitInc faEquity

* saving cleaned dataset
save $cleandata/scf/Scf22, replace
