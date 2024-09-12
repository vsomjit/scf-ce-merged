/*==============================================================================
Project: Trends in income, equity owernship, and expenditure using SCF & CE 
Author: Vignesh Somjit
Advisor: Keith M. Ericson 
--------------------------------------------------------------------------------
Stata Version: Stata/BE 17
==============================================================================*/

clear all 
set more off
version 17
set seed 20240325

log using "~/Git/scf-ce-merged/Main.log", replace

* Set the file paths (only need to change main_dir)
local main_dir "~/Git/scf-ce-merged"
global code "`main_dir'/code"
global rawdata "`main_dir'/data/raw"
global cleandata "`main_dir'/data/cleaned"
global output "`main_dir'/output"
	
* Data handling 

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

* Preliminary Analysis 

	// Descriptive statistics 
*	do $code/09_TestReplicability
		// NOTE: commented out because this takes a long time
	
	// Distributions 
	do $code/10_Distributions
	
	// Preliminary Analysis   
	do $code/11_PreliminaryAnalysis
	
	// Main Analysis 
	do $code/12_MainAnalysisCopy	

* Appendix 

	// Different Ways to Collapse SCF & CE
	do $code/13_AlternateCollapses

log close
