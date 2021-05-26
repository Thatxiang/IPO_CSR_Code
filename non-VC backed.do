
ssc install matchit

ssc install freqindex

set more off
set matsize 5000


global root="D:\Harshit\Projects\IPO_CSR"


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
	
	****** match non-VC backed firms with IPO firms
	
	use $bt/pm_identifiers_all_names_std, clear
			gen upper_name = upper( original_name) 
			duplicates drop upper_name, force
			keep original_name stem_name upper_name standard_name all_name_listed
			gen uniq_repr_id=_n
			
	save $bt/reprik_std, replace
	
	use $bt/non_VC_firm, clear
	
	merge m:1 upper_name  using $bt/reprik_std
	keep if _merge==3
	drop _merge
	matchit uniq_repr_id  stem_name using $bt/ipo_05_20_deal_id.dta, idu(ipo_deal_id) txtu(issuer_stem) override di sim(token) weights(root)  threshold(0.7)
	joinby ipo_deal_id using $bt/ipo_05_20_deal_id
	joinby uniq_repr_id using $bt/reprik_std
	
	save $bt/non_vc_ipo, replace
	
	use $bt/non_vc_ipo, clear
	
	keep uniq_repr_id stem_name ipo_deal_id issuer_stem similscore upper_name original_name I TIC
	duplicates drop upper_name, force
	
	order upper_name I similscore
	gen IPO_name=upper(I)
	matchit upper_name IPO_name, gen (score)
    order upper_name IPO_name similscore score   
	
	keep if sim > 0.98 | (sim >0.97 & score>0.6)
	
	save $bt/non_vc_ipo-final, replace
	
	
	****** match non-VC backed firms with acquired firms
	
		use $bt/non_VC_firm, clear
		merge m:1 upper_name  using $bt/reprik_std
	    keep if _merge==3
	    drop _merge
		
	matchit uniq_repr_id  stem_name using $bt/ma_05_20_deal_id.dta, idu(ma_deal_id ) txtu(target_stem ) override di sim(token) weights(root)  threshold(0.7)
	joinby  ma_deal_id using $bt/ma_05_20_deal_id
	joinby uniq_repr_id using $bt/reprik_std
	
	save $bt/non_vc_m&a, replace
	
	
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
		gen exit_date = D if D!=. & DA==.
		replace exit_date = DA if DA!=. & D==.
		replace exit_date = D if (D!=. & DA!=. & D<=DA)
		replace exit_date = DA if (D!=. & DA!=. & D>DA)
		
		gen status ="IPO" if exit_date == D & D!=.
		replace status ="M&A" if exit_date == DA & DA!=.
		
		save $bt/non_VC_final_sample, replace

		*** filter unique non-VC firms
		use  $bt/non_VC_final_sample, clear
		
		keep uniq_repr_id upper_name original_name_csr status
		
		sort uniq_repr_id
		by uniq_repr_id: keep if _n==1
		
		save $bt/non_VC_uniq, replace
		
		
		***** public firms
		
		use $bt/csr_gvk, clear
	   
		rename all_name_listed upper_name
		duplicates drop upper_name, force
		
		save $bt/csr_public_gvk, replace
		
		
		**** match unique non-VC firms with NETS data
			use  $bt/crs_nets_matched, clear
		keep dunsnumber  all_name_listed
		duplicates drop
			rename all_name_listed upper_name
		joinby upper_name using $bt/non_VC_uniq
		
		*** drop public firms from the sample
			merge m:1 upper_name using $bt/csr_public_gvk
			keep if _merge==1
			drop _merge
		
			merge m:1 dunsnumber using $bt/NETS_1990_2017_std
			drop if _merge==2
				
				drop _merge file asstype  
	save $bt/csr_non_vc_nets_2015_2017, replace
		
	use $bt/csr_non_vc_nets_2015_2017, clear
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


	use $bt/pm_rri_US_year_nodup, clear
		sort original_name_csr year sector
		bys original_name_csr year: keep if _n == 1 //drop 33 duplicated obs
		merge m:1 original_name_csr using $bt/csr_vc_matched_nets_nodup
			keep if _merge == 3