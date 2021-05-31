**** match csr-NETS File with VentureXpert data and later with existing NETS DATA


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

**** match csr-NETS File with existing NETS DATA
use  $bt/crs_nets_matched, clear

duplicates drop reprisk_id  dunsnumber, force

merge m:1 dunsnumber using $bt\NETS_1990_2017_std
drop if _merge==2
preserve
keep if _merge==3
drop _merge
save crs_finx, replace
restore
keep if _merge==1
drop _merge 
keep all_name_listed company score similscore dunsnumber name_st id name_st1 state name_merge reprisk_id original_name headquarter_country_code headquarter_country sectors url all_isins primary_isin num_name file asstype standard_name stem_name name_std
save crs_rem, replace

**** matching
use  $bt/crs_nets_matched, clear

duplicates drop reprisk_id  dunsnumber, force

rename all_name_listed all_name_listed_UPCASE

joinby all_name_listed_UPCASE using $bt/vc_csr_list

duplicates drop all_name_listed_UPCASE  dunsnumber, force

merge m:1 dunsnumber using $bt\NETS_1990_2017_std
drop if _merge==2
preserve
keep if _merge==3
duplicates drop all_name_listed_UPCASE  dunsnumber, force
save $bt/csr_vc_nets_matched, replace
restore
keep if _merge==1
drop _merge 
duplicates drop all_name_listed_UPCASE  dunsnumber, force
keep all_name_listed company dunsnumber name_st id name_st1 state name_merge reprisk_id original_name headquarter_country_code headquarter_country sectors url all_isins primary_isin num_name file asstype standard_name stem_name name_std
save $bt/csr_vc_rem, replace


*** match unmatched firms with public compustat firms

**** final list of unmatched firms
use $bt/csr_vc_rem, clear
keep dunsnumber company
duplicates drop dunsnumber, force
sort company dunsnumber
save $bt/dunsnumber_list_vc, replace




