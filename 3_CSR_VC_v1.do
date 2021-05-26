*ssc install matchit

*ssc install freqindex
set more off
set matsize 5000


global root="C:\Users\xzhen\Dropbox\IPO_CSR"


global bi="$root/Build/Input"
global bt="$root/Build/Temp"
global bc="$root/Build/Code"
global bo="$root/Build/Output"
global NAMDIR ="$root/Build/Code/std_name"
cap log close
cap log using $bt/2_CSR_VentureXpert,t replace

*get vc csr matched list
use $bt/pm_identifiers_all_names_std, clear
	duplicates drop
	keep original_name  all_name_listed  stem_name standard_name
	rename standard_name csr_name_std
	rename original_name original_name_csr 
	duplicates drop
	gen id=_n
	compress
save $bt/pm_identifiers_all_names_std_list_v2, replace

use $bt/vc_investment_2002_2020_std, clear
	keep CompanyName stem_name standard_name
	rename standard_name vc_name_std
	duplicates drop
	egen vc_id = group(stem_name) 
save $bt/vc_investment_2002_2020_std1_v2, replace

use $bt/vc_investment_2002_2020_std1_v2, clear
	matchit vc_id stem_name using $bt/pm_identifiers_all_names_std_list_v2.dta, idu(id) txtu(stem_name) override di sim(token) weights(root)  threshold(0.9)
save $bt/vc_pm_identifiers_all_names_std_list_matchit_v2, replace
	joinby vc_id using $bt/vc_investment_2002_2020_std1_v2
        joinby id using $bt/pm_identifiers_all_names_std_list_v2
save $bt/pm_identifiers_all_names_std_list_vc_v2,replace
	
use $bt/pm_identifiers_all_names_std_list_vc_v2, clear
	bysort id: egen maxsimi=max(similscore)
keep if abs(maxsimi-similscore)<0.00001
	drop maxsimi
save $bt/pm_identifiers_all_names_std_list_vc_v2_fuzzy_match, replace

*** manuall check for accuracy of matches
use $bt/pm_identifiers_all_names_std_list_vc_v2_fuzzy_match, clear
	gen all_name_listed_UPCASE = trim(upper(all_name_listed))
	gen  CompanyName_UPCASE=trim(upper(CompanyName))
	matchit all_name_listed_UPCASE CompanyName_UPCASE , gen (score)
	sort score similscore
	order all_name_listed_UPCASE CompanyName_UPCASE score similscore	
*** set following cutoff scores after manual observation	
	keep if score>0.7 | similscore ==1
	drop if score<0.9 & similscore <0.99
	drop if score<0.8 & similscore <0.98
***keep only one matched pair with the highest score among multiple matched pairs	
	sort original_name_csr score
		bys original_name_csr: keep if _n == _N		
save $bt/vc_csr_list, replace	

