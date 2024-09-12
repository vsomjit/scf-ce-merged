/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
Purpose: This file analyzes the distribution of income, equity, expenditure, &
		 lambda using the merged SCF & CE collapsed tables
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all
set more off

use $cleandata/MainDataset.dta

									* Income 
									* ======

* summary statistics
sum meanInc, detail

* overall distribution
graph hbox meanInc

* understanding frequency of outliers
count if meanInc > 200000
count if meanInc > 300000

* overall distribution with trimmed income 
histogram meanInc if meanInc < 300000, fraction

* distribution by age
graph box meanInc, over(age)

									* Equity 
									* ======

* summary statistics
sum meanEq, detail

* summary statistics for equity shares
sum eqShare, detail

* overall distribution 
graph hbox eqShare 

* understanding frequency of outliers
count if meanEq > 500000

* overall distribution with trimmed equity 
histogram meanEq if meanEq < 500000, fraction

* distribution by age 
graph box meanEq, over(age) 

								* Expenditures
								* ============

*  summary statistics
sum meanExpn, detail

* summary statistics for expenditure shares
sum expnShare, detail

* overall distribution 
graph hbox meanExpn
histogram meanExpn, fraction

* outlier analysis
count if meanExpn > 180000

* distribution by income
histogram meanExpn, freq by(quartile)
graph box meanExpn, over(quartile)

* distribution by age
histogram meanExpn, freq by(age) 

graph box meanExpn, over(age) 

									* Lambda 
									* ======

* summary statistics 
sum lambda, detail

* overall distribution 
graph hbox lambda

* outlier analysis 
count if lambda > 40

* overall distribution with trimmed data
histogram lambda if lambda < 40, fraction

* distribution by income 
graph box lambda, over(quartile)
graph bar (median) lambda, over(quantile) 

* median lambda for top decile
egen mlambda = median(lambda) if quantile == 19 | quantile == 20
list mlambda
drop mlambda

* median lambda for "middle class"
egen mlambda = median(lambda) if ///
	quantile == 8 | quantile == 9 | quantile == 10 | quantile == 11 | quantile == 12
list mlambda
drop mlambda

* distribution by age 
graph box lambda, over(age) 
