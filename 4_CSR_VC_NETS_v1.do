set more off
set matsize 5000



global root="C:\Users\xzhen\Dropbox\IPO_CSR"


global bi="$root/Build/Input"
global bt="$root/Build/Temp"
global bc="$root/Build/Code"
global bo="$root/Build/Output"
global NAMDIR ="$root/Build/Code/std_name"
cap log close
cap log using $bt/2_CSR_VC_NETS,t replace
	
*step 0: import NETS data
	import delimited $bi/NETS2015_LehighTargets.txt, clear 
	save $bi/NETS2015, replace

	import delimited $bi/NETS2017_BostonCollegeTargets072720.txt, clear 
	save $bi/NETS2017, replace
	
*step 1: clean NETS data	
	use $bi/NETS2015, clear
		destring sic8_3 sic8_4 sic8_5 sic8_6 salesc13  salesc15, replace
		append using $bi/NETS2017
			replace hqcompany=trim(upper(hqcompany))
	save $bt/NETS_1990_2017, replace

	do $NAMDIR/nameonly_main_NETS.do	

*step 2: match NETS data with csr firms	

*run  NETS_CSR_mat.do to produce $bt/crs_nets_matched (it is coded by Harshit)
	use  $bt/crs_nets_matched, clear
		keep dunsnumber  all_name_listed
		duplicates drop
			rename all_name_listed all_name_listed_UPCASE
		joinby all_name_listed_UPCASE using $bt/vc_csr_list
		drop stem_name id stem_name1
			merge m:1 dunsnumber using $bt/NETS_1990_2017_std
				keep if _merge==3
				drop _merge file asstype  
	save $bt/csr_vc_nets_2015_2017, replace
		
	use $bt/csr_vc_nets_2015_2017, clear
		rename score vc_csr_score
		*keep only csr firm with highest match score within each establishment
		gen  original_name_csr_UPCASE=trim(upper(original_name_csr))
			matchit original_name_csr_UPCASE company  , gen (nets_csr_score)
		bys dunsnumber: egen double max_nets_csr_score = max(nets_csr_score)
		keep if max_nets_csr_score == nets_csr_score
			sort dunsnumber original_name_csr
			bys dunsnumber: keep if _n == 1 //drop 16 duplicates
			
		*aggregate by hqcompany_st
			bys hqcompany_st: gen num_establishments = _N
		forvalue i = 90/99{
			rename *`i' *19`i'
		}
		foreach v in "00" "01" "02" "03" "04" "05" "06" "07" "08" "09"{
			rename *`v' *20`v'
		}
		forvalue i = 10/17{
			rename *`i' *20`i'
		}

		forvalue i = 1990/2017{
			gen active_establish`i' = 1 if firstyear <= `i' & lastyear >= `i'
			bys hqcompany_st: egen num_establish`i' = sum(active_establish`i')
		
			bys hqcompany_st: egen hqemp`i' = sum(emp`i')
			bys hqcompany_st: egen double hqsales`i' = sum(sales`i')
			}
			
			drop if hqcompany == ""
			
			keep hqcompany_st hqemp* hqsales* all_name_listed_UPCASE  vc_csr_score similscore  CompanyName_UPCASE vc_id CompanyName vc_name_std original_name_csr all_name_listed csr_name_std original_name_csr_UPCASE  num*
			duplicates drop
		*keep only nets firm with highest match score within each csr firm
		matchit original_name_csr_UPCASE hqcompany_st  , gen (nets_csr_score)
			bys original_name_csr_UPCASE: egen double max_nets_csr_score1 = max(nets_csr_score)
			keep if max_nets_csr_score1 == nets_csr_score
			bys hqcompany_st: egen double max_nets_csr_score2 = max(nets_csr_score)
			keep if max_nets_csr_score2 == nets_csr_score
			sort original_name_csr num_establishments
				bys original_name_csr: keep if _n == _N //drop 9 mismatched firm
				drop if nets_csr_score == 0
				drop max_nets_csr_score* nets_csr_score
		*keep only csr firm with highest match score within each vc firm
		matchit original_name_csr_UPCASE CompanyName_UPCASE  , gen (csr_vc_score)
			bys CompanyName_UPCASE: egen double max_csr_vc_score = max(csr_vc_score)
			keep if max_csr_vc_score == csr_vc_score
			drop max_csr_vc_score csr_vc_score
	save $bt/csr_vc_matched_nets_nodup, replace

*step 3: merge with csr data
	use $bt/pm_rri_US_year_nodup, clear
		sort original_name_csr year sector
		bys original_name_csr year: keep if _n == 1 //drop 33 duplicated obs
		merge m:1 original_name_csr using $bt/csr_vc_matched_nets_nodup
			keep if _merge == 3
			drop _merge
		foreach v in num_establish hqemp  hqsales {
			gen `v' = .
			gen l1_`v' = .
			gen f1_`v' = .
		}	
		forvalue i = 2007/2017{
			replace num_establish = num_establish`i' if year == `i'
			replace hqemp = hqemp`i' if year == `i'
			replace hqsales = hqsales`i' if year == `i'
		}
			forvalue i = 2007/2017{
				local j = `i' - 1
			replace l1_num_establish = num_establish`j' if year == `i'
			replace l1_hqemp = hqemp`j' if year == `i'
			replace l1_hqsales = hqsales`j' if year == `i'
		}
			forvalue i = 2007/2016{
				local j = `i' + 1
			replace f1_num_establish = num_establish`j' if year == `i'
			replace f1_hqemp = hqemp`j' if year == `i'
			replace f1_hqsales = hqsales`j' if year == `i'
		}
		forvalue i = 1990/2017{
			drop num_establish`i'  hqemp`i'  hqsales`i' 
		}
		drop num_establishments
	save $bt/vc_matched_csr_nets_nodup, replace

*step 4: merge with vc data
	use $bt/vc_matched_csr_nets_nodup, clear
		merge m:1 CompanyName using $bt/vc_company_2002_2020_nodup
			drop if _merge == 2
			drop _merge
		merge 1:1 CompanyName year using $bt/vc_investment_2002_2020_nodup
			drop if _merge == 2
			drop _merge
		drop all_name_listed_UPCASE CompanyName_UPCASE vc_csr_score similscore vc_id vc_name_std all_name_listed csr_name_std original_name_csr_UPCASE
			merge m:1 CompanyName using $bt/vc_investment_2002_2020_nodup_by_investment_year_order
			drop if _merge == 2
			drop _merge
	save $bt/matched_csr_nets_vc, replace
		
*step 5: label all variables
	use $bt/matched_csr_nets_vc, clear
		label var avg_current_rri_year "Average Monthly Current RepRisk Index (RRI) This Year"
		label var avg_environmental_rri_year "Average Monthly Enviromental RepRisk Index (RRI) This Year"
		label var avg_social_rri_year "Average Monthly Social RepRisk Index (RRI) This Year"
		label var avg_governance_rri_year "Average Monthly Governance RepRisk Index (RRI) This Year"
		label var max_current_rri_year "Maximum Monthly Current RepRisk Index (RRI) This Year"
		label var max_environmental_rri_year "Maximum Monthly Enviromental RepRisk Index (RRI) This Year"
		label var max_social_rri_year "Maximum Monthly Social RepRisk Index (RRI) This Year"
		label var max_governance_rri_year "Maximum Monthly Governance RepRisk Index (RRI) This Year"		
		label var max_reprisk_rating_year "Best Monthly RepRisk Rating This Year"		
		label var min_reprisk_rating_year "Worst Monthly RepRisk Rating This Year"		
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

		label var num_establish "Number of Establishments This Year"	
		label var l1_num_establish "Number of Establishments Last Year"	
		label var f1_num_establish "Number of Establishments Next Year"	
		label var hqemp "Total Number of Employment This Year"	
		label var l1_hqemp "Total Number of Employment Last Year"	
		label var f1_hqemp "Total Number of Employment Next Year"	
		label var hqsales "Total Sales This Year"	
		label var l1_hqsales "Total Sales Last Year"	
		label var f1_hqsales "Total Sales Next Year"	

		label var InvestmentYear "VC Investment Year"
		label var avg_EquityAmountEstimated "Average Equity Amount Estimated Investement per Deal This Year"
		label var sum_EquityAmountEstimated "Total Equity Amount Estimated Investement This Year"
		label var avg_EquityAmountDisclosed "Average Equity Amount Disclosed Investement per Deal This Year"
		label var sum_EquityAmountDisclosed "Total Equity Amount Disclosed Investement This Year"	
		label var max_RoundNumber "Latest Round Number This Year"
		label var min_RoundNumber "Earliest Round Number This Year"	
		label var avg_NoofFunds "Average Number of VC Funds Invested per Deal This Year"
		label var max_NoofFunds "Largest Number of VC Funds Invested per Deal This Year"
		label var avg_NoofFirms "Average Number of VC Firms Invested per Deal This Year"
		label var max_NoofFirms "Largest Number of VC Firms Invested per Deal This Year"
	save $bo/matched_csr_nets_vc, replace

	erase $bt/NETS_1990_2017.dta          		
  
