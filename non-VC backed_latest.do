
ssc install matchit

ssc install freqindex

set more off
set matsize 5000


global root="C:\Users\hrajaiya\Documents\GitHub\IPO_CSR_Code"


global bi="$root/Build/Input"
global bt="$root/Build/Temp"
global bc="$root/Build/Code"
global bo="$root/Build/Output"
global NAMDIR ="$root/Build/Code/std_name"


**** prepare list of non-VC backed firms

*match NETS CSR list with VC-backed firms and keep the non-VC backed firms

		use $bt/vc_csr_list, clear
		gen upper_name = upper( original_name_csr ) 
		gen vc_back=1
		save $bt/vc_list, replace
		
		use $bt/pm_rri_US_year_nodup, clear
	    sort original_name_csr year sector
		by original_name_csr year: keep if _n == 1 
		**//drop 33 duplicated obs	
		
		gen upper_name = upper( original_name_csr) 


			merge m:1 upper_name using $bt/vc_list
			replace vc_back=0 if vc_back==.
			
				keep if _merge==1 
				drop _merge
				
				drop score similscore vc_id stem_name id stem_name1 CompanyName vc_name_std all_name_listed csr_name_std
				 drop all_name_listed_UPCASE CompanyName_UPCASE
				 
		save $bt/non_VC_firm, replace
	
	
	use $bt/pm_identifiers_all_names_std, clear
			gen upper_name = upper( original_name) 
			duplicates drop upper_name, force
			keep original_name stem_name upper_name standard_name all_name_listed
			gen uniq_repr_id=_n
			
	save $bt/reprik_std, replace

		****** match non-VC backed firms with IPO firms (identify IPOs)
		
	use $bt/non_VC_firm, clear
	
	merge m:1 upper_name  using $bt/reprik_std
	keep if _merge==3
	drop _merge
	matchit uniq_repr_id  stem_name using $bt/ipo_05_20_deal_id.dta, idu(ipo_deal_id) txtu(issuer_stem) override di sim(token) weights(root)  threshold(0.7)
	joinby ipo_deal_id using $bt/ipo_05_20_deal_id
	joinby uniq_repr_id using $bt/reprik_std
	
	save $bt/non_vc_ipo, replace
	
	*** check the match rate
	use $bt/non_vc_ipo, clear
	
	keep uniq_repr_id stem_name ipo_deal_id issuer_stem similscore upper_name original_name I TIC
	duplicates drop upper_name, force
	
	order upper_name I similscore
	gen IPO_name=upper(I)
	matchit upper_name IPO_name, gen (score)
    order upper_name IPO_name similscore score   
	
	keep if sim > 0.98 | (sim >0.97 & score>0.6)
	
	save $bt/non_vc_ipo-final, replace
	
	
	****** match non-VC backed firms with acquired firms (identify M&As)
	
		use $bt/non_VC_firm, clear
		merge m:1 upper_name  using $bt/reprik_std
	    keep if _merge==3
	    drop _merge
		
	matchit uniq_repr_id  stem_name using $bt/ma_05_20_deal_id.dta, idu(ma_deal_id ) txtu(target_stem ) override di sim(token) weights(root)  threshold(0.7)
	joinby  ma_deal_id using $bt/ma_05_20_deal_id
	joinby uniq_repr_id using $bt/reprik_std
	
	save $bt/non_vc_m&a, replace
	
	*** check the match rate
	use  $bt/non_vc_m&a, clear

	keep uniq_repr_id stem_name ma_deal_id target_stem similscore upper_name original_name TN
	duplicates drop upper_name, force
	
	order upper_name TN similscore
	gen target_name=upper(TN)
	matchit upper_name target_name, gen (score)
    order upper_name target_name similscore score   
	
	keep if sim ==1 | (sim >0.99 & score>0.6) | (sim >0.98 & score>0.7)
	
	save $bt/non_vc_m&a-final, replace
	
	
	*** track acquisition and IPO date of sample firms
	
		use $bt/non_VC_firm, clear
		
			merge m:1 upper_name  using $bt/reprik_std
		keep if _merge==3
		drop _merge
		
		** track IPOs
		merge m:1 uniq_repr_id using $bt/non_vc_ipo-final
		drop if _merge==2
		drop _merge
		
		merge m:1 ipo_deal_id using $bt/ipo_05_20_deal_id
		drop if _merge==2
		drop _merge
	
	   *** track acquisitions
	    merge m:1 uniq_repr_id using $bt/non_vc_m&a-final
		drop if _merge==2
		drop _merge
		
		merge m:1 ma_deal_id using $bt/ma_05_20_deal_id
		drop if _merge==2
		drop _merge
		
		**** find the exit date (IPO or acquisition)
		** determine which form of exit occured first 
		gen exit_date = D if D!=. & DE==.
		replace exit_date = DE if DE!=. & D==.
		replace exit_date = D if (D!=. & DE!=. & D<=DE)
		replace exit_date = DE if (D!=. & DE!=. & D>DE)
		
		gen status ="IPO" if exit_date == D & D!=.
		replace status ="M&A" if exit_date == DE & DE!=.
		
		save $bt/non_VC_final_sample, replace

		*** filter unique non-VC firms
		use  $bt/non_VC_final_sample, clear
		
		keep uniq_repr_id upper_name original_name_csr status sectors 
		
		sort uniq_repr_id
		by uniq_repr_id: keep if _n==_N
		
		save $bt/non_VC_uniq, replace
		
		
		***** list of public firms
		
		use $bt/csr_gvk, clear
	   
		rename all_name_listed upper_name
		duplicates drop upper_name, force
		duplicates drop standard_name, force
		duplicates drop stem_name, force
		gen name_std = trim(standard_name)
		drop name_st
		gen name_st=trim(stem_name)
		save $bt/csr_public_gvk, replace
		
		
		**** match non-VC backed firms with Crunchbase data
		
		use  $bt/non_VC_final_sample, clear
		
		keep uniq_repr_id upper_name original_name_csr standard_name stem_name  status sectors
		gen name_merge = stem_name
		
		sort uniq_repr_id
		by uniq_repr_id: keep if _n==_N
		
		*** fuzzy-match crunchbase data
		matchit uniq_repr_id  stem_name using $bt/CB_name_st.dta, idu(cruid) txtu(name_merge) override di sim(token) weights(root)  threshold(0.9)
		
		joinby  uniq_repr_id using $bt/non_VC_uniq
	    joinby  cruid using $bt/CB_name_st
		
		save $bt/non_VC_cb, replace
		
		*** clean the data
		use $bt/non_VC_cb, clear
		
		
		bysort uniq_repr_id: egen maxsimi=max(similscore)
		keep if abs(maxsimi-similscore)<0.00001
		drop maxsimi
		
		*** manual check
	
		matchit upper_name upp_comp_name, gen (score)
		
		order upper_name upp_comp_name score similscore
		
		sort similscore
		
		keep if (sim==1) | (sim>0.99 & score>0.6) | (score>0.7) | (score>0.65 & sim>0.98)
		
		 drop if strpos(upper_name,"UNIVERSITY")>0
		 drop if strpos(upper_name,"COLLEGE")>0
		 
		 duplicates drop uniq_repr_id  upper_name, force
		 
		save $bt/non_VC_cb_uniq, replace 
		

			
			
			**********************************
			
			*** prepare sample to run regressions

			*** keep only first VC investment in firms
			use $bt/matched_csr_nets_vc, clear
			
			keep original_name_csr sectors year avg_environmental_rri_year max_environmental_rri_year avg_environmental_rri max_environmental_rri avg_social_rri_year max_social_rri_year avg_social_rri max_social_rri avg_governance_rri_year max_governance_rri_year avg_governance_rri max_governance_rri avg_current_rri_year max_current_rri_year avg_current_rri max_current_rri max_reprisk_rating_year min_reprisk_rating_year max_reprisk_rating min_reprisk_rating InvestmentYear1
			
			***drop if InvestmentYear==.
			
			keep original_name_csr year InvestmentYear1
			sort original_name_csr year InvestmentYear1
			
			by original_name_csr: keep if _n==1
			
			rename 	InvestmentYear1 first_InvestmentYear
			
			save $bt/csr_vc_first_investment, replace
			
			
			**** prepare list of non-Vc backed CS firms (removing public firms from the list)
			use  $bt/non_VC_final_sample, clear
			
			merge m:1 uniq_repr_id using $bt/non_VC_cb_uniq
			keep if _merge==3
			
			drop _merge
			
			gen exit_year = year(exit_date)
			
			*** remove publicly listed non-Vc firms
			gen name_st=trim(stem_name)
			
			merge m:1 upper_name using $bt/csr_public_gvk
			drop if _merge==2
			drop if year>=ipo_year
			drop _merge
			
						
			keep original_name_csr sectors year avg_environmental_rri_year max_environmental_rri_year avg_environmental_rri max_environmental_rri avg_social_rri_year max_social_rri_year avg_social_rri max_social_rri avg_governance_rri_year    max_governance_rri_year avg_governance_rri max_governance_rri avg_current_rri_year max_current_rri_year avg_current_rri max_current_rri max_reprisk_rating_year min_reprisk_rating_year avg_reprisk_rating_year max_reprisk_rating min_reprisk_rating status exit_date exit_year uniq_repr_id standard_name
			
			**keep if exit_year-year>5
			
			sort original_name_csr year
			
			**** keep unique firm observations (earliest CSR rating for a firm)
			by original_name_csr: keep if _n==1
			
			save $bt/non-VC-csr-uniq1, replace
			
			
			use $bt/non-VC-csr-uniq1, clear
			
		    gen name_std=standard_name
			
			merge m:1 name_std using $bt/csr_public_gvk
			drop if _merge==2
			drop if year>=ipo_year
			drop _merge
			
			**gen exit_year = year(exit_date)
			
			keep original_name_csr sectors year avg_environmental_rri_year max_environmental_rri_year avg_environmental_rri max_environmental_rri avg_social_rri_year max_social_rri_year avg_social_rri max_social_rri avg_governance_rri_year    max_governance_rri_year avg_governance_rri max_governance_rri avg_current_rri_year max_current_rri_year avg_current_rri max_current_rri max_reprisk_rating_year min_reprisk_rating_year avg_reprisk_rating_year max_reprisk_rating min_reprisk_rating status exit_date exit_year uniq_repr_id 
			
			**keep if exit_year-year>5
			
			sort original_name_csr year
			
			**** keep unique firm observations (earliest CSR rating for a firm)
			by original_name_csr: keep if _n==1
			
			drop if original_name_csr == "Adobe Systems Inc (Adobe)"
			drop if original_name_csr == "Citigroup Inc (Citi; Citigroup)"
			drop if original_name_csr == "Citigroup Investments Inc"
			drop if original_name_csr == "Google Inc (Google)"
			drop if original_name_csr == "Massachusetts Institute of Technology (MIT)"
			drop if original_name_csr == "Merck & Co Inc (Merck)"
			drop if original_name_csr == "New Jersey Institute of Technology"
			drop if original_name_csr  == "Regeneron Pharmaceuticals Inc"
			drop if original_name_csr  == "Starbucks Corp (Starbucks)"
			drop if original_name_csr  == "World Bank Group (WBG); The"
			
			save $bt/non-VC-csr-uniq, replace
			
					
		**** match unique non-VC firms with NETS data
		
		use $bt/non_VC_firm, clear
		
			merge m:1 upper_name  using $bt/reprik_std
		keep if _merge==3
		drop _merge
		
		joinby standard_name using $bt/crs_nets_matched
		
		merge m:1 uniq_repr_id using $bt/non-VC-csr-uniq
		keep if _merge==3
		drop _merge
		
		duplicates drop dunsnumber, force
	
		keep company dunsnumber
		sort company dunsnumber
		save $bt/cb_nets_csr_duns_list, replace
				
	   
	   *** list of VC-backed firms that received first VC investment after the CSR ratings
	   use $bt/matched_csr_nets_vc, clear
			
			keep original_name_csr sectors year avg_environmental_rri_year max_environmental_rri_year avg_environmental_rri max_environmental_rri avg_social_rri_year max_social_rri_year avg_social_rri max_social_rri avg_governance_rri_year max_governance_rri_year avg_governance_rri max_governance_rri avg_current_rri_year max_current_rri_year avg_current_rri max_current_rri max_reprisk_rating_year min_reprisk_rating_year avg_reprisk_rating_year max_reprisk_rating min_reprisk_rating InvestmentYear1 
			
			** track first investment year of VC backed firms
			merge m:1 original_name_csr using $bt/csr_vc_first_investment
			keep if _merge==3
			drop _merge
			
			sort original_name_csr year
			
			**** keep the earliest csr rating for a firm
			by original_name_csr: keep if _n==1
			
			***** keep cases where CSR rating was given before VC investment
			keep if year<first_InvestmentYear
			
            keep original_name_csr
			
			*gen all_name_listed_UPCASE = upper( original_name_csr)
			
			save $bt/csr_vc_final_list, replace
	   
	   
	     use $bt/vc_csr_list, clear
		 
		 merge 1:1 original_name_csr using $bt/csr_vc_final_list
		 keep if _merge==3
		 
		 keep all_name_listed_UPCASE CompanyName_UPCASE CompanyName original_name_csr vc_name_std csr_name_std stem_name
		 
		 duplicates drop all_name_listed_UPCASE , force
		 
		 save $bt/csr_vc_final_reg_sample, replace
	   
			
		*** create final regression sample
		
			use $bt/matched_csr_nets_vc, clear
			
				**** find the exit date (IPO or acquisition)
		gen exit_date = D if D!=. & DE==.
		replace exit_date = DE if DE!=. & D==.
		replace exit_date = D if (D!=. & DE!=. & D<=DE)
		replace exit_date = DE if (D!=. & DE!=. & D>DE)
		
		gen status ="IPO" if exit_date == D & D!=.
		replace status ="M&A" if exit_date == DE & DE!=.
		
			
			keep original_name_csr sectors year avg_environmental_rri_year max_environmental_rri_year avg_environmental_rri max_environmental_rri avg_social_rri_year max_social_rri_year avg_social_rri max_social_rri avg_governance_rri_year max_governance_rri_year avg_governance_rri max_governance_rri avg_current_rri_year max_current_rri_year avg_current_rri max_current_rri max_reprisk_rating_year min_reprisk_rating_year avg_reprisk_rating_year max_reprisk_rating min_reprisk_rating InvestmentYear1 exit_date status
			
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
		
		*** 1-year
		reghdfe vc_fund_1year avg_reprisk_rating_year, absorb (year ind) cluster(ind)
		est store e1
		reghdfe vc_fund_1year avg_environmental_rri_year, absorb (year ind) cluster(ind)
		est store e2
		reghdfe vc_fund_1year avg_social_rri_year, absorb (year ind) cluster(ind)
		est store e3
		reghdfe vc_fund_1year avg_governance_rri_year, absorb (year ind) cluster(ind)	
		est store e4
		reghdfe vc_fund_1year avg_current_rri_year, absorb (year ind) cluster(ind)	
		est store e5
		
		
		outreg2 [e1 e2 e3 e4 e5] using VC_funding1.xls, keep (avg_reprisk_rating_year avg_current_rri_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year) adjr2 dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace

		*** 3-year
		reghdfe vc_fund_3year avg_reprisk_rating_year, absorb (year ind) cluster(ind)
		est store e1
		reghdfe vc_fund_3year avg_environmental_rri_year, absorb (year ind) cluster(ind)
		est store e2
		reghdfe vc_fund_3year avg_social_rri_year, absorb (year ind) cluster(ind)
		est store e3
		reghdfe vc_fund_3year avg_governance_rri_year, absorb (year ind) cluster(ind)	
		est store e4
		reghdfe vc_fund_3year avg_current_rri_yea, absorb (year ind) cluster(ind)
		est store e5
		
		outreg2 [e1 e2 e3 e4 e5] using VC_funding3.xls, keep (avg_reprisk_rating_year avg_current_rri_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year) adjr2 dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace
		
		*** 5-year
		reghdfe vc_fund_5year avg_reprisk_rating_year, absorb (year ind) cluster(ind)
		est store e1
		reghdfe vc_fund_5year avg_environmental_rri_year, absorb (year ind) cluster(ind)
		est store e2
		reghdfe vc_fund_5year avg_social_rri_year, absorb (year ind) cluster(ind)
		est store e3
		reghdfe vc_fund_5year avg_governance_rri_year, absorb (year ind) cluster(ind)
		est store e4
		reghdfe vc_fund_5year avg_current_rri_yea, absorb (year ind) cluster(ind)
		est store e5
		
		outreg2 [e1 e2 e3 e4 e5] using VC_funding5.xls, keep (avg_reprisk_rating_year avg_current_rri_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year) adjr2 dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace
		
		*** any point in future
		
		reghdfe vc_backed avg_reprisk_rating_year, absorb (year ind) cluster(ind)
		est store e1
		reghdfe vc_backed avg_environmental_rri_year, absorb (year ind) cluster(ind)
		est store e2
		reghdfe vc_backed avg_social_rri_year, absorb (year ind) cluster(ind)
		est store e3
		reghdfe vc_backed avg_governance_rri_year, absorb (year ind) cluster(ind)
		est store e4
		reghdfe vc_backed avg_current_rri_yea, absorb (year ind) cluster(ind)
		est store e5
		
		outreg2 [e1 e2 e3 e4 e5] using VC_funding.xls, keep (avg_reprisk_rating_year avg_current_rri_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year) adjr2 dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace
		

		
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
		univar avg_reprisk_rating_year avg_current_rri_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year vc_backed ipo ma exit
		
		
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
		
			outreg2 [e1 e2 e3 e4 e5] using IPO_funding.xls, keep (avg_reprisk_rating_year avg_current_rri_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year) adjr2 dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace
				
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
		
			outreg2 [e1 e2 e3 e4 e5] using M&A_funding.xls, keep (avg_reprisk_rating_year avg_current_rri_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year) adjr2 dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace
		
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
		
		outreg2 [e1 e2 e3 e4 e5] using Exit_funding.xls, keep (avg_reprisk_rating_year avg_current_rri_year avg_environmental_rri_year avg_social_rri_year avg_governance_rri_year) adjr2 dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace
		
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
		
			outreg2 [e1 e2 e3 e4 e5] using IPO_funding_xsection.xls, drop (constant) adjr2 dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace
		
					
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
		
			outreg2 [e1 e2 e3 e4 e5] using M&A_funding_xsection.xls, drop (constant) adjr2 dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace	
		
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
		
			outreg2 [e1 e2 e3 e4 e5] using Exit_funding_xsection.xls, drop (constant) adjr2 dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace	
			
			*************************
				
				