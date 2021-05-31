ssc install matchit

ssc install freqindex

**** prepare CSR file for matching

 use "/gsfs0/data/rajaiya/Research/CSR/data/temp/pm_identifiers_all_names_std.dta" 

 gen name_std= standard_name

 gen name_st= stem_name

gen id=_n

save "/gsfs0/data/rajaiya/Research/CSR/data/temp/CRS_firm_std.dta"


***************Merging all the data together*************
**/// Match names of  *NETS* and *Venture Scanner* by state

foreach i of num 1/52 {


	use /gsfs0/data/rajaiya/Research/CSR/NETS_std/state`i'_std.dta,replace
	matchit dunsnumber name_st using /gsfs0/data/rajaiya/Research/CSR/data/temp/CRS_firm_std.dta, idu(id) txtu(name_st) override di sim(token) weights(root)  threshold(0.9)
	joinby dunsnumber using /gsfs0/data/rajaiya/Research/CSR/NETS_std/state`i'_std.dta
        joinby id using /gsfs0/data/rajaiya/Research/CSR/data/temp/CRS_firm_std.dta
	save /gsfs0/data/rajaiya/Research/CSR/NETS_mat/state`i'_nets_csr.dta,replace
	}

***** state 53

	use /gsfs0/data/rajaiya/Research/CSR/state53_std.dta,replace
	matchit dunsnumber name_st using /gsfs0/data/rajaiya/Research/CSR/data/temp/CRS_firm_std.dta, idu(id) txtu(name_st) override di sim(token) weights(root)  threshold(0.9)
	joinby dunsnumber using /gsfs0/data/rajaiya/Research/CSR/state53_std.dta
        joinby id using /gsfs0/data/rajaiya/Research/CSR/data/temp/CRS_firm_std.dta
	save /gsfs0/data/rajaiya/Research/CSR/NETS_mat/state53_nets_csr.dta,replace



**/// Append all the matched files (by state) together
	use /gsfs0/data/rajaiya/Research/CSR/NETS_mat/state1_nets_csr.dta,replace
	foreach i of num 2/53 {
	append using /gsfs0/data/rajaiya/Research/CSR/NETS_mat/state`i'_nets_csr.dta
	}

	save /gsfs0/data/rajaiya/Research/CSR/mat_netshq_csr.dta,replace


use /gsfs0/data/rajaiya/Research/CSR/mat_netshq_csr, clear

bysort id: egen maxsimi=max(simi)
keep if abs(maxsimi-simi)<0.00001

save nets_csr_final, replace

***** List of NETS firms with sales info
use nets2015_add, clear
append using nets2015_add
save nets2015_all, replace


*** manuall check for accuracy of matches
use nets_csr_final, clear

replace all_name_listed = trim(upper(all_name_listed))

replace company=trim(upper(company))

matchit all_name_listed company , gen (score)

order all_name_listed company score similscore

gsort  all_name_listed company -score -similscore

*** cutoff score of 0.6 obrained after manual observation
keep if score>0.6

save crs_nets_matched, replace

**** match csr-NETS File with existing NETS DATA
use  $bt/crs_nets_matched, clear

duplicates drop reprisk_id  dunsnumber, force

merge m:1 dunsnumber using $bt\NETS_1990_2017_std
drop if _merge==2
preserve
keep if _merge==3
drop _merge
save $bt/crs_finx, replace
restore
keep if _merge==1
drop _merge 
keep all_name_listed company score similscore dunsnumber name_st id name_st1 state name_merge reprisk_id original_name headquarter_country_code headquarter_country sectors url all_isins primary_isin num_name file asstype standard_name stem_name name_std

sort all_name_listed dunsnumber
save $bt/crs_rem, replace


*** match unmatched firms with public compustat firms

use $bt/comp_50_16_uniqstem, clear
gen name_st=trim(stem_name)

replace name_st = subinstr(name_st, "U S", "US", .)
gen gvk=real(gvkey)
save $bt/comp_stem, replace

 use $bt/crsp_comp_std, clear
 gen upper_name = upper(conm)
 duplicates drop standard_name, force
 *drop standard_name stem_name
 gen gvk=real(GVKEY)
 drop GVKEY
 save $bt/crsp_comp_stem, replace

use $bt/crs_rem, clear 
keep all_name_listed company name_st id
duplicates drop name_st, force
replace name_st = subinstr(name_st, "U S", "US", .)

matchit id name_st using $bt/crsp_comp_stem.dta, idu(gvk) txtu(name_st) override di sim(token) weights(root)  threshold(0.9)

	joinby gvk using $bt/crsp_comp_stem.dta
        joinby id using $bt/crs_rem.dta

save $bt/csr_compst, replace


*** manually verify the match
use $bt/csr_compst, clear

	bysort id: egen maxsimi=max(similscore)
keep if abs(maxsimi-similscore)<0.00001
	drop maxsimi
	
drop score
duplicates drop reprisk_id dunsnumber, force
matchit all_name_listed conm , gen (score)

order all_name_listed conm  score similscore
sort score

save $bt/csr_compst_temp, replace

use $bt/csr_compst_temp, clear

*** cutoff score of 0.7 obrained after manual observation
keep if (score>0.65 & sim>0.97)  | (score>0.7)  | (sim>=0.995) |  (score>0.625 & sim>0.98)

keep all_name_listed conm score similscore id name_st gvk company dunsnumber state reprisk_id standard_name stem_name name_merge original_name headquarter_country_code headquarter_country ipo_year

save $bt/csr_comp_duns, replace

***** list of CSR firms linked to compustat using gvkey
use $bt/csr_comp_duns, clear
duplicates drop gvk original_name, force
save $bt/csr_gvk, replace


**** final list of unmatched firms
use $bt/crs_rem, clear

joinby reprisk_id using  $bt/csr_gvk, unmatched(master)
keep if _merge==1
drop _merge
duplicates drop reprisk_id dunsnumber, force
keep all_name_listed company score similscore dunsnumber state reprisk_id original_name headquarter_country_code headquarter_country sectors url all_isins primary_isin num_name stem_name name_std
save $bt/csr_unmatched, replace

**** list of establishment needed
use $bt/csr_unmatched, clear

keep dunsnumber company
duplicates drop dunsnumber, force
sort company dunsnumber
save $bt/dunsnumber_csr, replace




