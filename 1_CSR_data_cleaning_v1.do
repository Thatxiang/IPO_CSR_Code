set more off
set matsize 5000


global root="C:\Users\xzhen\Dropbox\IPO_CSR"


global bi="$root/Build/Input"
global bt="$root/Build/Temp"
global bc="$root/Build/Code"
global bo="$root/Build/Output"
global NAMDIR ="$root/Build/Code/std_name"
cap log close
cap log using $bt/1_CSR_data_cleaning,t replace

*CSR


use $bi/pm_identifiers, clear
	keep if headquarter_country_code == "US"
	compress
save  $bt/pm_identifiers_US, replace 

use $bt/pm_identifiers_US, clear
	*drop name duplicates
		sort name sectors
		bys name: gen n = _n	
		keep if n == 1
			drop n
	*separate by parentheses
	split name, gen(new_name_) p(" (")
	
	
	*remove words associated with "formerly"
		replace new_name_2 = subinstr(new_name_2, "formerly known as ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "Formerly known as ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "Formerly ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "formerly ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "please refer to ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "doing business as ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "formery ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "formerley ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "dba ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "d.b.a. ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "also known as ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "commonly known as ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "also ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "operating as ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "part of ", "",.) 
		replace new_name_2 = subinstr(new_name_2, "also ", "",.) 
	

					tab new_name_2

	
	** deal with a few special cases with two pairs of parentheses
		replace new_name_1 = new_name_1 + " (" + new_name_2 if new_name_2 == "USA) Inc" | new_name_2 == "USA) LLC" | new_name_2 == "USA) PLC" | new_name_2 == "USA) Ltd" | new_name_2 == "CNMI) LLC" | new_name_2 == "US) LP" | new_name_2 == "US) Ltd"  | new_name_2 == "US)"  | new_name_2 == "US) Company"  | new_name_2 == "US) Inc"  | new_name_2 == "US) LLC"  | new_name_2 == "US) Ltd."  | new_name_2 == "USA)"  | new_name_2 == "USA) Co Inc"  | new_name_2 == "USA) Corp"  | new_name_2 == "USA) Holdings Co"  |  new_name_2 == "USA), Inc."  |  new_name_2 == "USA), LLC" |  new_name_2 == "USIS) LLC" |  new_name_2 == "USA), LLC" 
		replace new_name_2 = "" if new_name_2 == "USA) Inc" | new_name_2 == "USA) LLC" | new_name_2 == "USA) PLC" | new_name_2 == "USA) Ltd" | new_name_2 == "CNMI) LLC" | new_name_2 == "US) LP" | new_name_2 == "US) Ltd"  | new_name_2 == "US)"  | new_name_2 == "US) Company"  | new_name_2 == "US) Inc"  | new_name_2 == "US) LLC"  | new_name_2 == "US) Ltd."  | new_name_2 == "USA)"  | new_name_2 == "USA) Co Inc"  | new_name_2 == "USA) Corp"  | new_name_2 == "USA) Holdings Co"  |  new_name_2 == "USA), Inc."  |  new_name_2 == "USA), LLC" |  new_name_2 == "USIS) LLC" |  new_name_2 == "USA), LLC" 
		
	replace new_name_2 = subinstr(new_name_2, ")", "",.) 
	
		tab new_name_3
		replace new_name_3 = subinstr(new_name_3, "formerly known as ", "",.) 
		replace new_name_3 = subinstr(new_name_3, "formerly ", "",.) 
	
		replace new_name_2 = new_name_2 + " (" + new_name_3 if new_name_3 == "USA))" | new_name_3 == "USA) Inc)" | new_name_3 == "Illinois) LLC)" 
		replace new_name_3 = "" if new_name_3 == "USA))" | new_name_3 == "USA) Inc)" | new_name_3 == "Illinois) LLC)" 
		replace new_name_2 = subinstr(new_name_2, "USA))", "USA)",.) 
		replace new_name_2 = subinstr(new_name_2, "USA) Inc)", "USA) Inc",.) 
		replace new_name_2 = subinstr(new_name_2, "Illinois) LLC)", "Illinois) LLC",.) 
			

		tab new_name_4
	
		replace new_name_3 = subinstr(new_name_3, ")", "",.) 
		replace new_name_3 = new_name_3 + " (" + new_name_4 if new_name_4 == "USA)" 
		replace new_name_4 = "" if new_name_4 == "USA)" 
	
	replace new_name_2 = new_name_3 if new_name_2 == ""
	replace new_name_3 = "" if new_name_2 == new_name_3
	
	*separate new_name_2 by ";"
	split new_name_2, gen(new_name_2_) p("; ")
	
	
	
	gen num_name = 0
	foreach v of varlist new_name_1 new_name_2_1 new_name_2_2 new_name_2_3 new_name_2_4 new_name_3 new_name_4 {	
		replace num_name = num_name + 1 if `v' ~= ""
	}
	
	expand num_name
	bys name num_name: gen name_order = _n	
		gen all_name_listed = ""
			replace all_name_listed = new_name_1 if  name_order == 1
			replace all_name_listed = new_name_2_1 if  name_order == 2 
			replace all_name_listed = new_name_2_2 if  name_order == 3 
			replace all_name_listed = new_name_3 if  name_order == 3 & new_name_2_2 == ""
			replace all_name_listed = new_name_2_3 if  name_order == 4 
			replace all_name_listed = new_name_2_4 if  name_order == 5 
	drop name_order new_name*
	rename name original_name
save $bt/pm_identifiers_all_names, replace

	do $NAMDIR/nameonly_main_CSR.do

use $bt/pm_identifiers_all_names_std, clear
	keep standard_name
	duplicates drop
save $bt/pm_identifiers_all_names_std_list, replace
	
use $bi/pm_rri, clear
	merge m:1 reprisk_id using $bt/pm_identifiers_US
		keep if _merge == 3
		drop _merge
save $bt/pm_rri_US, replace

use $bt/pm_rri_US, clear
	drop isin
	duplicates drop
	gen year = year(date)
	gen month = month(date)
	gen ym = ym(year, month)
	format ym %tm
		drop month
	sort reprisk_id ym 
save $bt/pm_rri_US_nodup, replace


use $bt/pm_rri_US_nodup, clear
	rename name original_name_csr
	gen environmental_rri = current_rri * environmental_percentage
	gen social_rri = current_rri * social_percentage 
	gen governance_rri = current_rri * governance_percentage
		foreach v in environmental_rri social_rri governance_rri current_rri{
		bys original_name_csr year: egen avg_`v'_year = mean(`v')
		bys original_name_csr year: egen max_`v'_year = max(`v')
		bys original_name_csr: egen avg_`v' = mean(`v')		
		bys original_name_csr: egen max_`v' = max(`v')		
		}
	gen numerical_reprisk_rating = .
		replace numerical_reprisk_rating = 1 if reprisk_rating == "D"
		replace numerical_reprisk_rating = 2 if reprisk_rating == "C"
		replace numerical_reprisk_rating = 3 if reprisk_rating == "CC"
		replace numerical_reprisk_rating = 4 if reprisk_rating == "CCC"
		replace numerical_reprisk_rating = 5 if reprisk_rating == "B"
		replace numerical_reprisk_rating = 6 if reprisk_rating == "BB"
		replace numerical_reprisk_rating = 7 if reprisk_rating == "BBB"
		replace numerical_reprisk_rating = 8 if reprisk_rating == "A"
		replace numerical_reprisk_rating = 9 if reprisk_rating == "AA"
		replace numerical_reprisk_rating = 10 if reprisk_rating == "AAA"
	bys original_name_csr year: egen max_reprisk_rating_year = max(numerical_reprisk_rating)
	bys original_name_csr year: egen min_reprisk_rating_year = min(numerical_reprisk_rating)
	bys original_name_csr year: egen avg_reprisk_rating_year = mean(numerical_reprisk_rating)
		
	bys original_name_csr: egen max_reprisk_rating = max(numerical_reprisk_rating)
	bys original_name_csr: egen min_reprisk_rating = min(numerical_reprisk_rating)
	
	keep original_name_csr year max_* min_* avg* sectors
	duplicates drop
save $bt/pm_rri_US_year_nodup, replace	

erase $bt/pm_rri_US.dta
