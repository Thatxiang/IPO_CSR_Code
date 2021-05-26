set more off
set matsize 5000


*global root="D:\Harshit\Projects\IPO_CSR"
global root="C:\Users\xzhen\Dropbox\IPO_CSR"


global bi="$root/Build/Input"
global bt="$root/Build/Temp"
global bc="$root/Build/Code"
global bo="$root/Build/Output"
global br="$root/Build/Output/Regression"
global NAMDIR ="$root/Build/Code/std_name"

			
		*** create final regression sample
		
			use $bo/matched_csr_nets_vc, clear
			
				**** find the exit date (IPO or acquisition)
		gen exit_date = D if D!=. & DE==.
		replace exit_date = DE if DE!=. & D==.
		replace exit_date = D if (D!=. & DE!=. & D<=DE)
		replace exit_date = DE if (D!=. & DE!=. & D>DE)
		
		gen status ="IPO" if exit_date == D & D!=.
		replace status ="M&A" if exit_date == DE & DE!=.
		
			
			keep original_name_csr sectors year avg_environmental_rri_year max_environmental_rri_year avg_environmental_rri max_environmental_rri avg_social_rri_year max_social_rri_year avg_social_rri max_social_rri avg_governance_rri_year max_governance_rri_year avg_governance_rri max_governance_rri avg_current_rri_year max_current_rri_year avg_current_rri max_current_rri max_reprisk_rating_year min_reprisk_rating_year  max_reprisk_rating min_reprisk_rating InvestmentYear exit_date status
			
			gen exit_year = year(exit_date)
			
			** track first investment year of VC backed firms
			merge m:1 original_name_csr using $bt/csr_vc_first_investment
			keep if _merge==3
			drop _merge
			
			sort original_name_csr year
			
			**** keep the earliest csr rating for a firm
			by original_name_csr: keep if _n==1
			
			***** keep cases where CSR rating was given before VC investment
			keep if year<first_InvestmentYear
			
			gen vc_backed=1
			
			
			*** append non-VC backed sample firms
		append using  $bt/non-VC-csr-uniq
		
		sort original_name_csr year
		
		gen upper_name=upper(original_name_csr)
		
				 drop if strpos(upper_name,"UNIVERSITY")>0
		 drop if strpos(upper_name,"COLLEGE")>0
		 
		 replace vc_backed=0 if vc_backed==.
		 
		 replace status ="NA" if status==""
		 
		
		*** 1-year VC funding
		
		gen vc_fund_1year = 1 if first_InvestmentYear-year<2
		replace vc_fund_1year=0 if vc_fund_1year==.
		
		*** 3-year VC funding
		
		gen vc_fund_3year = 1 if first_InvestmentYear-year<4
		replace vc_fund_3year=0 if vc_fund_3year==.	
		
		*** 5-year VC funding
		
		gen vc_fund_5year = 1 if first_InvestmentYear-year<6
		replace vc_fund_5year=0 if vc_fund_5year==.
		
		**** industries
		encode sectors, gen (ind)
		
		*** keep observations with exit after csr ratings		
		keep if year<exit_year
		
		*** labels
		label var avg_current_rri_year "Average Monthly Current RepRisk Index (RRI) (Annual)"
		label var avg_environmental_rri_year "Average Monthly Enviromental RepRisk Index (RRI) (Annual)"
		label var avg_social_rri_year "Average Monthly Social RepRisk Index (RRI) (Annual)"
		label var avg_governance_rri_year "Average Monthly Governance RepRisk Index (RRI) (Annual)"
		label var max_current_rri_year "Maximum Monthly Current RepRisk Index (RRI) (Annual)"
		label var max_environmental_rri_year "Maximum Monthly Enviromental RepRisk Index (RRI) (Annual)"
		label var max_social_rri_year "Maximum Monthly Social RepRisk Index (RRI) (Annual)"
		label var max_governance_rri_year "Maximum Monthly Governance RepRisk Index (RRI) (Annual)"		
		label var max_reprisk_rating_year "Best Monthly RepRisk Rating (Annual)"		
		label var min_reprisk_rating_year "Worst Monthly RepRisk Rating (Annual)"		
		label var avg_current_rri "Average Monthly Current RepRisk Index (RRI) All Time"
		label var avg_environmental_rri "Average Monthly Enviromental RepRisk Index (RRI) All Time"
		label var avg_social_rri "Average Monthly Social RepRisk Index (RRI) All Time"
		label var avg_governance_rri "Average Monthly Governance RepRisk Index (RRI) All Time"
		label var max_current_rri "Maximum Monthly Current RepRisk Index (RRI) All Time"
		label var max_environmental_rri "Maximum Monthly Enviromental RepRisk Index (RRI) All Time"
		label var max_social_rri "Maximum Monthly Social RepRisk Index (RRI) All Time"
		label var max_governance_rri "Maximum Monthly Governance RepRisk Index (RRI) All Time"		
		label var max_reprisk_rating "Best Monthly RepRisk Rating All Time"		
		label var min_reprisk_rating "Worst Monthly RepRisk Rating All Time"	
		label var avg_reprisk_rating "Average RepRisk Rating (Annual)"		
		
		label var vc_fund_5year "VC funding within 5 years"	
		label var vc_backed "VC funding anytime in future"
		label var InvestmentYear "VC Investment Year"

		
	
		
		****** Regressions
	est clear
	local i = 0
	foreach v in  avg_reprisk_rating_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year avg_current_rri_year{
	eststo: quietly reghdfe vc_fund_1year `v', absorb (year ind) cluster(ind)
			estadd local INDFE "Yes"
			estadd local YEARFE "Yes"
			local i = `i' + 1
			estimates store f`i'
	}

esttab f* using $br/VC_funding1.tex, stats(INDFE YEARFE r2_a N, fmt(0 0 3 0) labels(`"Industry FE"'  `"Year FE"' `"Adjusted \(R^{2}\)"' `"Observations"')) compress t  label nogap b(%6.3f) noomitted  ///
		star(* 0.1 ** 0.05 *** 0.01)  nonote obslast replace 
		
	
		
		*** 1-year
	est clear
	local i = 0
	foreach v in  avg_reprisk_rating_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year avg_current_rri_year{
	eststo: quietly reghdfe vc_fund_1year `v', absorb (year ind) cluster(ind)
			estadd local INDFE "Yes"
			estadd local YEARFE "Yes"
			local i = `i' + 1
			estimates store f`i'
	}

esttab f* using $br/VC_funding1.tex, stats(INDFE YEARFE r2_a N, fmt(0 0 3 0) labels(`"Industry FE"'  `"Year FE"' `"Adjusted \(R^{2}\)"' `"Observations"')) compress t  label nogap b(%6.3f) noomitted  ///
		star(* 0.1 ** 0.05 *** 0.01)  nonote obslast replace 
		
		*** 3-year
	est clear
	local i = 0
	foreach v in  avg_reprisk_rating_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year avg_current_rri_year{
	eststo: quietly reghdfe vc_fund_3year `v', absorb (year ind) cluster(ind)
			estadd local INDFE "Yes"
			estadd local YEARFE "Yes"
			local i = `i' + 1
			estimates store f`i'
	}

esttab f* using $br/VC_funding3.tex, stats(INDFE YEARFE r2_a N, fmt(0 0 3 0) labels(`"Industry FE"'  `"Year FE"' `"Adjusted \(R^{2}\)"' `"Observations"')) compress t  label nogap b(%6.3f) noomitted  ///
		star(* 0.1 ** 0.05 *** 0.01)  nonote obslast replace 

		*** 5-year
	est clear
	local i = 0
	foreach v in  avg_reprisk_rating_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year avg_current_rri_year{
	eststo: quietly reghdfe vc_fund_5year `v', absorb (year ind) cluster(ind)
			estadd local INDFE "Yes"
			estadd local YEARFE "Yes"
			local i = `i' + 1
			estimates store f`i'
	}

esttab f* using $br/VC_funding5.tex, stats(INDFE YEARFE r2_a N, fmt(0 0 3 0) labels(`"Industry FE"'  `"Year FE"' `"Adjusted \(R^{2}\)"' `"Observations"')) compress t  label nogap b(%6.3f) noomitted  ///
		star(* 0.1 ** 0.05 *** 0.01)  nonote obslast replace 
	
		*** any point in future
	est clear
	local i = 0
	foreach v in  avg_reprisk_rating_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year avg_current_rri_year{
	eststo: quietly reghdfe vc_backed `v', absorb (year ind) cluster(ind)
			estadd local INDFE "Yes"
			estadd local YEARFE "Yes"
			local i = `i' + 1
			estimates store f`i'
	}

esttab f* using $br/VC_funding.tex, stats(INDFE YEARFE r2_a N, fmt(0 0 3 0) labels(`"Industry FE"'  `"Year FE"' `"Adjusted \(R^{2}\)"' `"Observations"')) compress t  label nogap b(%6.3f) noomitted  ///
		star(* 0.1 ** 0.05 *** 0.01)  nonote obslast replace 
		
		
	
		
		***** IPO or M&A
		
		*** exit within 5 years

		gen ipo_5 = 1 if status=="IPO" & exit_year - year<6
		replace ipo_5=0 if ipo_5==.
		gen ma_5=1 if status=="M&A" & exit_year - year<6
		replace ma_5=0 if ma_5==.
		gen exit_5=1 if exit_year - year<6 & (status=="IPO" | status=="M&A")
		replace exit_5=0 if exit_5==.
		
			label var ipo_5  "IPO within 5 years"	
			label var ma_5  "M&A within 5 years"	
			label var exit_5  "Successful Exit within 5 years"
			
		reghdfe ipo_5 avg_reprisk_rating_year, absorb (year ind) cluster(ind)
		reghdfe ipo_5 avg_environmental_rri_year, absorb (year ind) cluster(ind)
		reghdfe ipo_5 avg_social_rri_year, absorb (year ind) cluster(ind)
		reghdfe ipo_5 avg_governance_rri_year, absorb (year ind) cluster(ind)			
		reghdfe ipo_5 avg_current_rri_yea, absorb (year ind) cluster(ind)	
				
		reghdfe ma_5 avg_reprisk_rating_year, absorb (year ind) cluster(ind)
		reghdfe ma_5 avg_environmental_rri_year, absorb (year ind) cluster(ind)
		reghdfe ma_5 avg_social_rri_year, absorb (year ind) cluster(ind)
		reghdfe ma_5 avg_governance_rri_year, absorb (year ind) cluster(ind)			
		reghdfe ma_5 avg_current_rri_yea, absorb (year ind) cluster(ind)	
		
		reghdfe exit_5 avg_reprisk_rating_year, absorb (year ind) cluster(ind)
		reghdfe exit_5 avg_environmental_rri_year, absorb (year ind) cluster(ind)
		reghdfe exit_5 avg_social_rri_year, absorb (year ind) cluster(ind)
		reghdfe exit_5 avg_governance_rri_year, absorb (year ind) cluster(ind)			
		reghdfe exit_5 avg_current_rri_yea, absorb (year ind) cluster(ind)
		
		*** any exit
		
		gen ipo = 1 if status=="IPO" 
		replace ipo=0 if ipo==.
		gen ma=1 if status=="M&A"
		replace ma=0 if ma==.
		gen exit=1 if (status=="IPO" | status=="M&A")
		replace exit=0 if exit==.
		
			label var ipo  "IPO anytime in future"	
			label var ma  "M&A anytime in future"	
			label var exit  "Successful Exit anytime in future"
			
		**** summary stats
*		univar avg_reprisk_rating_year avg_current_rri_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year vc_backed ipo ma exit
			
		reghdfe ipo avg_reprisk_rating_year, absorb (year ind) cluster(ind)
		est store e1
		reghdfe ipo avg_environmental_rri_year, absorb (year ind) cluster(ind)
		est store e2
		reghdfe ipo avg_social_rri_year, absorb (year ind) cluster(ind)
		est store e3
		reghdfe ipo avg_governance_rri_year, absorb (year ind) cluster(ind)	
		est store e4
		reghdfe ipo avg_current_rri_yea, absorb (year ind) cluster(ind)
		est store e5
		
			outreg2 [e1 e2 e3 e4 e5] using $br/IPO_funding.xls, keep (avg_reprisk_rating_year avg_current_rri_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year) r2_a dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace
				
		reghdfe ma avg_reprisk_rating_year, absorb (year ind) cluster(ind)
		est store e1
		reghdfe ma avg_environmental_rri_year, absorb (year ind) cluster(ind)
		est store e2
		reghdfe ma avg_social_rri_year, absorb (year ind) cluster(ind)
		est store e3
		reghdfe ma avg_governance_rri_year, absorb (year ind) cluster(ind)
		est store e4
		reghdfe ma avg_current_rri_yea, absorb (year ind) cluster(ind)	
		est store e5
		
			outreg2 [e1 e2 e3 e4 e5] using $br/M&A_funding.xls, keep (avg_reprisk_rating_year avg_current_rri_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year) r2_a dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace
		
		reghdfe exit avg_reprisk_rating_year, absorb (year ind) cluster(ind)
		est store e1
		reghdfe exit avg_environmental_rri_year, absorb (year ind) cluster(ind)
		est store e2
		reghdfe exit avg_social_rri_year, absorb (year ind) cluster(ind)
		est store e3
		reghdfe exit avg_governance_rri_year, absorb (year ind) cluster(ind)
		est store e4
		reghdfe exit avg_current_rri_yea, absorb (year ind) cluster(ind)
		est store e5
		
		outreg2 [e1 e2 e3 e4 e5] using $br/Exit_funding.xls, keep (avg_reprisk_rating_year avg_current_rri_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year) r2_a dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace
		
		*********  x-sectional tests
		
				
		reghdfe ipo c.avg_reprisk_rating_year##c.vc_backed, absorb (year ind) cluster(ind)
		est store e1
		reghdfe ipo c.avg_environmental_rri_year##c.vc_backed, absorb (year ind) cluster(ind)
		est store e2
		reghdfe ipo c.avg_social_rri_year##c.vc_backed, absorb (year ind) cluster(ind)
		est store e3
		reghdfe ipo c.avg_governance_rri_year##c.vc_backed, absorb (year ind) cluster(ind)	
		est store e4
		reghdfe ipo c.avg_current_rri_year##c.vc_backed, absorb (year ind) cluster(ind)
		est store e5
		
			outreg2 [e1 e2 e3 e4 e5] using $br/IPO_funding_xsection.xls, drop (constant) r2_a dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace
		
					
		reghdfe ma c.avg_reprisk_rating_year##c.vc_backed, absorb (year ind) cluster(ind)
		est store e1
		reghdfe ma c.avg_environmental_rri_year##c.vc_backed, absorb (year ind) cluster(ind)
		est store e2
		reghdfe ma c.avg_social_rri_year##c.vc_backed, absorb (year ind) cluster(ind)
		est store e3
		reghdfe ma c.avg_governance_rri_year##c.vc_backed, absorb (year ind) cluster(ind)	
		est store e4
		reghdfe ma c.avg_current_rri_year##c.vc_backed, absorb (year ind) cluster(ind)
		est store e5
		
			outreg2 [e1 e2 e3 e4 e5] using $br/M&A_funding_xsection.xls, drop (constant) r2_a dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace	
		
		reghdfe exit c.avg_reprisk_rating_year##c.vc_backed, absorb (year ind) cluster(ind)
		est store e1
		reghdfe exit c.avg_environmental_rri_year##c.vc_backed, absorb (year ind) cluster(ind)
		est store e2
		reghdfe exit c.avg_social_rri_year##c.vc_backed, absorb (year ind) cluster(ind)
		est store e3
		reghdfe exit c.avg_governance_rri_year##c.vc_backed, absorb (year ind) cluster(ind)	
		est store e4
		reghdfe exit c.avg_current_rri_year##c.vc_backed, absorb (year ind) cluster(ind)
		est store e5
		
			outreg2 [e1 e2 e3 e4 e5] using $br/Exit_funding_xsection.xls, drop (constant) r2_a dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace	
			
			*************************
				
				