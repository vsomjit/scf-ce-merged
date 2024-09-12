clear all
****Begin with Merged SCF and CE dataset
use $cleandata/MainDataset.dta

count
tab quantile
tab age
tab ageCat
list in 1/2

***Check for consistency with summary stats
*** Top decile's equity share as reported by FRED:  
*** https://fred.stlouisfed.org/series/WFRBST01122   
*** https://fred.stlouisfed.org/series/WFRBSN09149

    egen TopQuintileEqShare = sum(eqShare) if quantile == 20 | quantile==19
    egen TopQuintileExpShare = sum(expnShare) if quantile == 20 | quantile==19

*Unit of observation is the income quantile-age category
*There are 20 income quantiles
*There are 7 age categories in age
*(Supplmentary variable ageCat has 3 age categories)

*Weights:
*scfWgt is the sum of population weights for the cell, coming from the SCF
*ceWgt is the parallel sum coming from the CE

*We calculated lambda = expnShare/eqShare

local theta = 0.2
gen lambdaWithTheta = (expnShare+`theta')/(eqShare+`theta')
sum lambdaWithTheta,detail
cor lambdaWithTheta lambda

gen lambdaTopcoded = lambda
    replace lambdaTopcoded =100 if lambda>100

***Relationship between lambda and income
scatter lambda quantile 
scatter lambdaTopcoded quantile, ytitle("{&lambda}") xtitle("Household income quantile (1=Lowest, 20=Highest)")
graph save $output/lambdaVincomeScatter.gph, replace
graph export $output/lambdaVincomeScatter.png, replace
graph export $output/lambdaVincomeScatter.pdf, replace

***Relationship between lambda and income, by age
label define ageCatLabels 1 "Age 20 - 39" 2 "Age 40 - 69" 3 "Age 70 - 89", replace
label value ageCat ageCatLabels
twoway (scatter lambdaTopcoded quantile), by(ageCat, ixaxes ixtick noiytitle noixtitle) subtitle(, nobox) by(, note("")) 
graph save $output/lambdaVincomeScatterByAge.gph, replace
graph export $output/lambdaVincomeScatterByAge.png, replace
graph export $output/lambdaVincomeScatterByAge.pdf, replace


***Relationship between lambda of cell and equity share of cell-- 
scatter lambdaTopcoded eqShare,ytitle("{&lambda}") xtitle("Equity Share of Demographic Cell")
graph rename Graph g1
scatter lambdaTopcoded eqShare if lambdaTopcoded <2,ytitle("{&lambda}")  xtitle("Equity Share of Demographic Cell")
graph rename Graph g2
graph combine g1 g2
graph save $output/lambdaVEquityShare.gph, replace
graph export $output/lambdaVEquityShare.png, replace
graph export $output/lambdaVEquityShare.pdf, replace


sum eqShare,detail

***A major takeaway is that most equity is owned by 4 cells: old high income individuals
 list age ageCat meanInc eqShare expnShare lambda age avgWeight if eqShare >0.07
***We can read off this list that the equity weighted median lambda is about 0.06.


***Summarize Lambda
* MVL (unweighted, incorrect)
summarize lambda, detail


***Population Weighted Lambda
    * MVL (weighted by SCF population)
    summarize lambda [aweight = scfWgt], detail

    * MVL (weighted by CE population)
    summarize lambda [aweight = ceWgt], detail

    *** (weighted by averageweight population)
    summarize lambda [aweight = avgWeight], detail

***Equity Weighted lambda
    * MVL (weighted by equity shares, probably right)
    summarize lambda [aweight = eqShare], detail 

/*    ***In retrospect, I don't think these make sense since eqshare of j already accounts for population size.
    ***Note that median jumps from 0.06 to 0.25 depending on exact weight here. But that is a result of the cells jumping.

    *** This would make sense if it were equity share of i in j. But that is not 
    * MVL (weighted by SCF population & equity shares)
    gen lambdaWgtScf = eqShare * scfWgt
    summarize lambda [aweight = lambdaWgtScf], detail 

    * MVL (weighted by CE population & equity shares)
    gen lambdaWgtCe = eqShare * ceWgt 
    summarize lambda [aweight = lambdaWgtCe], detail 

    * MVL by average weights
    gen lambdaWgtAvg = eqShare * avgWeight 
    summarize lambda [aweight = lambdaWgtAvg], detail 
*/


***Plot CDF
cumul lambda, generate(cumu_lambdaWgtNo) equal
cumul lambda [aweight=avgWeight], generate(cumu_lambdaWgtAvg) equal
cumul lambda [aweight=eqShare], generate(cumu_lambdaWgtEq) equal

sort cumu_lambdaWgtAvg

twoway (line cumu_lambdaWgtAvg lambda, lwidth(thick)) (line cumu_lambdaWgtEq lambda) if lambda<1, legend(label(1 "Population Weighted") label(2 "Equity Weighted") position(6) rows(1)) xtitle("{&lambda}") ytitle("Cumulation Distribution of {&lambda}")
graph rename Graph g1, replace
twoway (line cumu_lambdaWgtAvg lambda, lwidth(thick)) (line cumu_lambdaWgtEq lambda) if lambda<100, legend(label(1 "Population Weighted") label(2 "Equity Weighted") position(6) rows(1)) xtitle("{&lambda}") ytitle("Cumulation Distribution of {&lambda}")
graph rename Graph g2, replace
graph combine g1 g2

graph save $output/CDFlambda.gph, replace
graph export $output/CDFlambda.png, replace
graph export $output/CDFlambda.pdf, replace

* Linear Interpolation
foreach var in cumu_lambdaWgtAvg cumu_lambdaWgtEq {
    gen lambda_`var'_50 = .
    forvalues i = 1/`=_N' {
        local next = `i' + 1
        if `var'[`i'] <= 0.5 & `var'[`next'] >= 0.5 {
            replace lambda_`var'_50 = lambda[`i'] + (0.5 - `var'[`i']) * (lambda[`next'] - 			  lambda[`i']) / (`var'[`next'] - `var'[`i'])
        }
    }
}

display lambda_cumu_lambdaWgtAvg_50[1]
display lambda_cumu_lambdaWgtEq_50[1]

cumul lambdaWithTheta [aweight=avgWeight], generate(cumu_lambdaThetaWgtAvg) 
cumul lambdaWithTheta [aweight=eqShare], generate(cumu_lambdaThetaWgtEq) 

sort cumu_lambdaThetaWgtAvg
twoway (line cumu_lambdaThetaWgtAvg lambdaWithTheta, sort lwidth(thick)) (line cumu_lambdaThetaWgtEq lambdaWithTheta,sort), legend(label(1 "Population Weighted") label(2 "Equity Weighted") position(6) rows(1)) xtitle("{&lambda} | {&theta}=0.2") ytitle("Cumulation Distribution of {&lambda} | {&theta}=0.2 ")

summarize lambdaWithTheta [aweight = avgWeight], detail
summarize lambdaWithTheta [aweight = eqShare], detail

graph save $output/CDFlambdaWithTheta.gph, replace
graph export $output/CDFlambdaWithTheta.png, replace
graph export $output/CDFlambdaWithTheta.pdf, replace
