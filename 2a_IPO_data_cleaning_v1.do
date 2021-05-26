set more off
set matsize 5000

global root="C:\Users\xzhen\Dropbox\IPO_CSR"

global bi="$root/Build/Input"
global bt="$root/Build/Temp"
global bc="$root/Build/Code"
global bo="$root/Build/Output"
global NAMDIR ="$root/Build/Code/std_name"
cap log close
cap log using $bt/2_ipo_cleaning,t replace	

*step 0: import SDC IPO data
	import excel $bi/ipo_05_20_us.xls, sheet("aa4") firstrow clear
	save $bi/ipo_05_20_us, replace

*step 1: clean SDC IPO data
	use $bi/ipo_05_20_us, clear
		label var I "Issuer/Borrower Name"
		label var TIC "Issuer/Borrower Ticker Symbol"
		label var SICP "Issuer/Borrower Primary SIC (Code)"
		label var CU "Issuer/Borrower 6-digit CUSIP"
		label var CUSIP9 "Issuer/Borrower 9-digit CUSIP"
		label var D "Dates: Issue Date"
		label var FILED "Dates: Filing Date"
		label var SECUR "Security Type (Name)"
		label var RANK1_OVERALLOT_TOTDOLAMTPRO "Proceeds Amount Overallotment Sold All Markets (US$ Mil)"
		label var TOTDOLAMT "Principal Amount All Markets (US$ mil)"
		label var OFFERPRICE "Offer Price (Host)"
		label var TOT "Shares Offered All Markets"
		label var MFILE "File Price, Mid (US $)"
		label var TOTPROSAMTUSD "Amount Total on Prospectus All Markets ($ mil)"
		label var RANK1_OVERALLOT_TOTDOLAMT "Principal Amount Overallotment Sold All Markets (US$ Mil)"
		label var R_TOTDOLAMTPRO "Proceeds Amount All Markets (US$ Mil)"
		label var PRSDAY "Stock Price at Close of Offer/First Trade"
		label var PUB "Issuer/Borrower Public Status (Description)"
		label var PR1DAY "Stock Price 1 Day After Offer"
		label var PR1WK "Stock Price 1 Week After Offer"
		label var PR2WK "Stock Price 2 Weeks After Offer"
		label var PR4WK "Stock Price 4 Weeks After Offer"
		label var PR60DAYS "Stock Price 60 Days After Offer"
		label var PRCUR "Stock Price Yesterday"
		label var GPCT "Fees: Gross Spread as % of Principal Amount This Market"
		label var TOTGMIL "Fees: Gross Spread (US$ mil)"
		label var G "Fees: Gross Spread (US $ per Share or Bond)"
		label var BOOK "Book Runner (Code)"
		label var LEADMANAGERS_PRINT "Lead Managers (Codes)"
		label var COMANAGERS "Co-Managers (Co-Leads on Non-US Issues)(Codes)"
		label var NUMBOOKS "Number of Bookrunners by Unique Parents"
		label var FIRSTRADEDATE "First Trade Date"
		label var TRADE_DATE "Dates: Trading Date"
		label var EXCH "Listing: Primary Exchange of Issuer's/Borrower's Stock"
		label var CUR "Tranche Currency (Code)"
		label var PRICEOPENSAMEDAY "Stock Price at Open of Offer/First Trade"
		label var PR90DAYS "Stock Price 90 Days After Offer"
		label var PR180DAYS "Stock Price 180 Days After Offer"
		label var NAT "Issuer/Borrower Nation (Name)"
		label var ST "Issuer/Borrower State (Name)"
		label var STI "Issuer/Borrower State of Incorporation (Name)"


		foreach x of varlist  I TIC SICP CU CUSIP9  FILED SECUR RANK1_OVERALLOT_TOTDOLAMTPRO    MFILE  RANK1_OVERALLOT_TOTDOLAMT  PRSDAY PUB PR1DAY PR1WK PR2WK PR4WK PR60DAYS PRCUR GPCT TOTGMIL G BOOK LEADMANAGERS_PRINT COMANAGERS FIRSTRADEDATE TRADE_DATE EXCH CUR PRICEOPENSAMEDAY PR90DAYS PR180DAYS  NAT STI  MasterDealType{
			replace `x' = "" if `x' == "-"
			replace `x' = "" if `x' == "na" 
			replace `x' = "" if `x' == "Comb." | `x' == "Comp." 
			replace `x' = "" if `x' == "IPO" 
			destring `x', replace
	}

		bys I D: egen S_TOTGMIL = sum(TOTGMIL)
			replace S_TOTGMIL = . if S_TOTGMIL == 0
		bys I D: egen S_G = sum(G)
			replace S_G = . if S_G == 0
		drop TOTGMIL G 
		duplicates drop
		keep if CUR == "US"
		keep if NAT == "United States"
		*drop if PUB == "Public"
	*	keep if EXCH == "American" | EXCH == "Nasdaq" | EXCH == "New York"
		bys I D: gen n1 = _N
		sort n1 I D
		drop if n1 == 2 & BOOK == "NOTAPP" //drop 2 duplicated obs
		drop n1		
	save $bt/ipo_05_20_us, replace
	
	
*step 2: merge with vc data	
	do $NAMDIR/nameonly_main_IPO.do

	use $bt/report_comp_status_2002_2020, clear
		keep if CompanyStatus == "Went Public"
	save $bt/report_comp_status_ipo_1980_2020, replace
		
	use $bt/ipo_05_20_us_std, clear
		drop PackageID MasterDealType file asstype
		rename standard_name issuer_std
		rename stem_name issuer_stem
		gen ipo_deal_id = _n	
	save $bt/ipo_05_20_deal_id, replace
		
		
	use $bt/ipo_05_20_deal_id, clear
		matchit ipo_deal_id issuer_stem using $bt/report_comp_status_ipo_1980_2020.dta, idu(vc_comp_id) txtu(vc_comp_stem) override di sim(token) weights(root)  threshold(0.7)
	save $bt/vc_ipo_matchit, replace

	use $bt/vc_ipo_matchit, clear
		joinby ipo_deal_id using $bt/ipo_05_20_deal_id
		joinby vc_comp_id using $bt/report_comp_status_ipo_1980_2020
			keep if ST == CompanyStateRegion
		gsort -similscore	
		//set cutoff to be 0.98 after manually check the match quality	
			keep if similscore >= 0.98
		gen date_diff = CompanyIPODate - D	
			keep if date_diff <=2 & date_diff >=-1
		sort vc_comp_id NUMBOOKS
			bys vc_comp_id: keep if _n == _N // drop 1 duplicated observation
		drop Company* ipo_deal_id vc_comp_stem similscore vc_comp_std date_diff		
	save $bt/vc_matched_ipo, replace	
	
*step 3: clean crsp daily data to get stock price info
	use $bi/CRSPD, clear
		sort PERMNO date
		bys PERMNO: gen  n = _n
		keep if n == 1
		drop n
	save $bt/CRSPD_first_date, replace
	
*step 4: merge with crsp data	
	use $bt/vc_matched_ipo, clear
		gen NCUSIP = substr(CUSIP9, 1, 8)
			replace NCUSIP = CU + "10" if NCUSIP == ""
		merge 1:m NCUSIP using $bt/CRSPD_first_date
			keep if _merge == 3
			drop _merge
	save $bt/vc_matched_ipo_CRSPD_NCUSIP_matched, replace
		
do $NAMDIR/nameonly_main_CRSPD.do	
	use $bt/vc_matched_ipo, clear
		gen NCUSIP = substr(CUSIP9, 1, 8)
			replace NCUSIP = CU + "10" if NCUSIP == ""
		merge 1:m NCUSIP using $bt/CRSPD_first_date
			keep if _merge == 1
			drop _merge  PERMNO date NAMEENDT SHRCD EXCHCD SICCD TICKER COMNAM SHRCLS TSYMBOL NAICS PRIMEXCH PERMCO ISSUNO HEXCD CUSIP NWPERM PRC VOL SHROUT NUMTRD vwretx	
			rename issuer_stem stem_name
		merge 1:m stem_name using $bt/CRSPD_first_date_std
				keep if _merge == 3
			drop _merge
			drop file asstype standard_name
	save $bt/vc_matched_ipo_CRSPD_NCUSIP_unmatched_name_matched, replace

	use $bt/vc_matched_ipo_CRSPD_NCUSIP_matched, clear
		append using $bt/vc_matched_ipo_CRSPD_NCUSIP_unmatched_name_matched
		gen date_diff = date - D
		keep if date_diff == 0 | date_diff == 1
	save $bt/vc_matched_ipo_CRSPD_matched, replace

