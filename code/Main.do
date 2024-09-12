/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all 
set more off
version 18
set seed 20240325

log using Main.log, replace

* Directories 

	***Set here to use relative paths for code
	*local main_dir "~/Documents/Git/urop_research"
	local main_dir "."
	
	global code "`main_dir'/code"
	global output "`main_dir'/output"
	global rawdata "`main_dir'/data/raw"
	global cleandata "`main_dir'/data/cleaned"
	capture mkdir $cleandata
	capture mkdir $cleandata/scf
	capture mkdir $cleandata/ce
	capture mkdir "`main_dir'/output"

* Data Handling 

	// Download packages
	do $code/00_Setup
	
	// Clean SCF dataset 
	do $code/01_CleanScf
	
	// Merge cleaned SCF dataset w/ replicate weights
	do $code/02_MergeScfRw
	
	// Construct collapsed SCF dataset 
	do $code/03_CollapseScf
	
	// Clean CE Interview dataset 
	do $code/04_CleanCeIntrvw
	
	// Clean CE Diary dataset
	do $code/05_CleanCeDiary
	
	// Append Interview & Diary datasets
	do $code/06_AppendCe
	
	// Construct collapsed CE dataset 
	do $code/07_CollapseCe

	// Merge SCF & CE collapsed datasets 
	do $code/08_MergeScfCe

/* 

* Preliminary Analysis

	// Descriptive statistics 
	*Takes a long time-- can comment out
	do $code/09_TestReplicability
	
	// Distributions
	***XXXWill want to identify key graphs and export them
	do $code/10_Distributions
	
	// Preliminary Analysis 
	do $code/11_PreliminaryAnalysis

*/

* Main Analysis
	capture mkdir $output/20_MainAnalysis
	do $code/12_MainAnalysis

* Appendix 

	// Different Ways to Collapse SCF & CE
	do $code/13_AlternateCollapses

log close 
