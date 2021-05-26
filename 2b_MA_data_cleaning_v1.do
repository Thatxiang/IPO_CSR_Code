set more off
set matsize 5000

global root="C:\Users\xzhen\Dropbox\IPO_CSR"

global bi="$root/Build/Input"
global bt="$root/Build/Temp"
global bc="$root/Build/Code"
global bo="$root/Build/Output"
global NAMDIR ="$root/Build/Code/std_name"
cap log close
cap log using $bt/2_ma_data_cleaning,t replace	

*step 0: import SDC ma data
	import excel $bi/ma_05_13.xls, sheet("aa6") firstrow clear
	save $bi/ma_05_13, replace

	import excel $bi/ma_14_20.xls, sheet("aa6") firstrow clear
	save $bi/ma_14_20, replace

	use $bi/ma_05_13, clear
		append using $bi/ma_14_20
	save $bi/ma_05_20, replace

*step 1: clean ma data
	use $bi/ma_05_20, clear
		*Label all variables
			label var ANL "Acquiror Name (Full)"
			label var AN "Acquiror Name (Short)"
			label var ANATION "Acquiror Nation (Name)"
			label var AEXCH "Acquiror Primary Stock Exchange (Name)"
			label var AST "Acquiror State (Name)"
			label var TN "Target Name"
			label var TNL "Target Name (Full)"
			label var TST "Target State (Name)"
			label var ENTVALANN "Enterprise Value at Announcement ($ mil)"
			label var EQVALANN "Equity Value at Announcement ($ mil)"
			label var PR "Share Price Paid by Acquiror for Target Shares ($)"
			label var RANKVAL "Ranking Value inc. Net Debt of Target ($Mil)"
			label var VAL "Deal Value ($ Mil)"
			label var DA "Date Announced"
			label var DE "Date Effective"
			label var DUNCON "Date Effective/Unconditional"
			label var DW "Date Withdrawn"
			label var DFIN "Date of Target Financials"
			label var ACU "Acquiror 6-digit CUSIP"
			label var ASICP "Acquiror Primary SIC (Code)"
			label var TSICP "Target Primary SIC (Code)"
			label var TCU "Target 6-digit CUSIP"
			label var BV "Book Value per Share Last Twelve Months ($)"
			label var COMEQ "Common Equity Last Twelve Months ($ Mil)"
			label var EPS "EPS Last Twelve Months ($)"
			label var NI "Net Income Last Twelve Months ($ Mil)"
			label var PTINC "Pre-tax Income Last Twelve Months ($ Mil)"
			label var CF "EBITDA Last Twelve Months ($ Mil)"
			label var EBIT "EBIT Last Twelve Months ($ Mil)"
			label var NETASS "Net Assets Last Twelve Months ($ Mil)"
			label var PE "Ratio of Offer Price to EPS"
			label var SALES "Net Sales Last Twelve Months ($ Mil)"
			label var TASS "Total Assets Last Twelve Months ($ Mil)"
			label var CFMULT "Ratio of Deal Value to EBITDA"
			label var EBITMULT "Ratio of Deal Value to EBIT"
			label var VALNI "Ratio of Deal Value to Net Income"
			label var VALSALES "Ratio of Deal Value to Sales"
			label var PPMDAY "Offer Price to Target Stock Price Premium 1 Day Prior to Announcement"
			label var PPMWK "Offer Price to Target Stock Price Premium 1 Week Prior to Announcement"
			label var PPM4WK "Offer Price to Target Stock Price Premium 4 Weeks Prior to Announcement"
			label var PCTACQ "Percent of Shares Acquired in Transaction"
			label var PCTOWN "Percent of Shares Owned after Transaction"
			label var PSOUGHT "Percent of Shares Acquiror is Seeking to Purchase in Transaction"
			label var STAT "Deal Status (Description)"
			label var REVERSE "Reverse Takeover Flag (Y/N)"
			label var IPO "Reverse LBO Flag (Y/N)"


		foreach x of varlist  ENTVALANN EQVALANN PR RANKVAL VAL BV COMEQ EPS NI PTINC CF EBIT NETASS PE SALES TASS CFMULT EBITMULT VALNI VALSALES PPMDAY PPMWK PPM4WK PCTACQ PCTOWN PSOUGHT{
			replace `x' = "" if `x' == "-"
			replace `x' = "" if `x' == "na" 
			replace `x' = "" if `x' == "nm" 
			replace `x' = "" if `x' == "np" 
			replace `x' = "" if `x' == "Comb." | `x' == "Comp." 
			destring `x', replace
	}	
	/*	sort SICP
			replace SICP = "6190" if SICP == "619A" | SICP == "619B"
			replace SICP = "4990" if SICP == "499A" 
			destring SICP, replace*/
			keep if REVERSE == "N"
			keep if IPO == "N"
			drop STAT REVERSE IPO MasterDealType
			duplicates drop
	save $bt/ma_05_20, replace

*step 2: merge with vc data
	do $NAMDIR/nameonly_main_MA.do

	use $bt/ma_05_20_std, clear
		sort TN  DA 
		bys TN: keep if _n == 1 // keep only the earliest acquired deal
		rename standard_name target_std
		rename stem_name target_stem
		gen ma_deal_id = _n
	save $bt/ma_05_20_deal_id, replace

	use $bt/ma_05_20_deal_id, clear
		matchit ma_deal_id target_stem using $bt/report_comp_status_2002_2020.dta, idu(vc_comp_id) txtu(vc_comp_stem) override di sim(token) weights(root)  threshold(0.7)
	save $bt/vc_ma_matchit, replace

	use $bt/vc_ma_matchit, clear
		joinby ma_deal_id using $bt/ma_05_20_deal_id
		joinby vc_comp_id using $bt/report_comp_status_2002_2020
			keep if TST == CompanyStateRegion
			drop if CompanyStatus == "Went Public"
		gsort -similscore	
		gen  CompanyName_UPCASE=trim(upper(CompanyName))
		gen  TN_UPCASE=trim(upper(TN))
		matchit TN_UPCASE CompanyName_UPCASE , gen (vc_ma_score)
		gsort -vc_ma_score	
		keep if similscore == 1 | vc_ma_score >= 0.7
			bys vc_comp_id: egen double max_vc_ma_score = max(vc_ma_score)
			keep if max_vc_ma_score == vc_ma_score //keep only one matched pair with the highest score among multiple matched pairs	
		sort vc_comp_id TSICP
		bys vc_comp_id: keep if _n == _N //drop 3 duplicated obs
		drop ma_deal_id  vc_comp_stem similscore file asstype vc_comp_std TN_UPCASE vc_ma_score max_vc_ma_score Company*
	save $bt/vc_matched_ma, replace		
