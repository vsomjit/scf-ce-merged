/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
Purpose: This file installs the Stata packages used in this project
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

* for standard error calculations using replicate weights
net install scfses, from("https://raw.github.com/crafkin/scfses/master/") replace

* for visualizations 
ssc install binscatter
ssc install sepscatter 
