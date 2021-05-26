set more off
set matsize 5000

global root="C:\Users\xzhen\Dropbox\IPO_CSR"


global bi="$root/Build/Input"
global bt="$root/Build/Temp"
global bc="$root/Build/Code"
global bo="$root/Build/Output"
global NAMDIR ="$root/Build/Code/std_name"
cap log close
cap log using $bt/2_VentureXpert_data_cleaning,t replace	

*step 0: import vc data
	do $bc/0_import_vc_data

*step 1: clean vc data
	use $bi/report1_01012002_03012020, clear
		foreach v of varlist TotalFundingToDateUSDMil EquityAmountDisclosedUSDMil EquityAmountEstimatedUSDMil SICCode CompanyIPODate{
			replace `v' = "" if `v' == "-"
			destring `v', replace
		}	
	save $bt/report1_01012002_03012020_inv1, replace 
		
	use $bi/report_01012002_03012020, clear
		foreach v of varlist FundSizeUSDMil DealValueUSDMil EquityAmountDisclosedUSDMil SICCode CompanyFoundedDate CompanyIPODate TotalFundingToDateUSDMil ValuationatTransactionDateU{
			replace `v' = "" if `v' == "-"
			destring `v', replace
		}	
		keep CompanyName InvestmentDate FundName NoofFundsManagedbyFirm FundSizeUSDMil   
		duplicates drop
	bys CompanyName InvestmentDate FundName: gen n = _N
		drop if FundName == "Undisclosed Fund" & n ~= 1
		drop n
		save $bt/report_01012002_03012020_fund1, replace 
		

	use $bi/report2_01012002_03012020, clear

		foreach v of varlist EquityAmountEstimatedUSDMil DebtAmountUSDMil NAICCode FirmStateRegion FundStateRegion{
			replace `v' = "" if `v' == "-"
			destring `v', replace
		}
		keep CompanyName InvestmentDate FundName FundStateRegion H   NoofFundsinTotal  NoofFirmsinTotal
		duplicates drop
		bys CompanyName InvestmentDate FundName: gen n = _N
		drop if FundName == "Undisclosed Fund" & n ~= 1
		drop n
		bys CompanyName InvestmentDate FundName: gen n = _N
		drop if n ~= 1
		drop n	
	save $bt/report2_01012002_03012020_fund1, replace 	
		
	use $bi/report2_01012002_03012020, clear

		foreach v of varlist EquityAmountEstimatedUSDMil DebtAmountUSDMil NAICCode FirmStateRegion FundStateRegion{
			replace `v' = "" if `v' == "-"
			destring `v', replace
		}
		keep CompanyName InvestmentDate FirmName TotalNumberofCompaniesInvest FirmStateRegion
		duplicates drop
		bys CompanyName InvestmentDate FirmName: gen n = _N
		drop if FirmName == "Undisclosed Firm" & n ~= 1
		drop n
		bys CompanyName InvestmentDate FirmName: gen n = _N
		drop if n ~= 1
		drop n	
	save $bt/report2_01012002_03012020_firm1, replace 	
			
		
	use $bt/report1_01012002_03012020_inv1, clear
		merge m:1 CompanyName InvestmentDate FundName using $bt/report_01012002_03012020_fund1
			drop if _merge == 2
			drop _merge
		merge m:1 CompanyName InvestmentDate FundName using $bt/report2_01012002_03012020_fund1
			drop if _merge == 2
			drop _merge	
		merge m:1 CompanyName InvestmentDate FirmName using $bt/report2_01012002_03012020_firm1
			drop if _merge == 2
			drop _merge
	save $bt/vc_investment_2002_2020, replace

	erase $bt/report1_01012002_03012020_inv1.dta
	erase $bt/report_01012002_03012020_fund1.dta
	erase $bt/report2_01012002_03012020_fund1.dta
	erase $bt/report2_01012002_03012020_firm1.dta
	
	
	use $bt/vc_investment_2002_2020, clear	
		drop InvestmentSecurityTypes  FirmName FundName FundSizeUSDMil FundStateRegion H  TotalNumberofCompaniesInvest FirmStateRegion NoofFundsManagedbyFirm CompanyIPODate CompanyStatus
		duplicates drop
		bys CompanyName InvestmentDate: egen m_NoofFundsinTotal = max(NoofFundsinTotal)
			keep if m_NoofFundsinTotal == NoofFundsinTotal //drop 1 duplicated obs
			drop m_NoofFundsinTotal	
		gen CompanyFoundedYear = substr(CompanyFoundedDate, 6, 4)
			destring CompanyFoundedYear, replace
		gen InvestmentYear = year(InvestmentDate)
		gen AgeAtFinance = InvestmentYear - CompanyFoundedYear + 1
		order CompanyName CompanyFoundedDate InvestmentYear
		bys CompanyName CompanyFoundedDate InvestmentYear: egen sum_EquityAmountEstimated = sum(EquityAmountEstimatedUSDMil)
		bys CompanyName CompanyFoundedDate InvestmentYear: egen avg_EquityAmountEstimated = mean(EquityAmountEstimatedUSDMil)
		bys CompanyName CompanyFoundedDate InvestmentYear: egen sum_EquityAmountDisclosed = sum(EquityAmountDisclosedUSDMil)
		bys CompanyName CompanyFoundedDate InvestmentYear: egen avg_EquityAmountDisclosed = mean(EquityAmountDisclosedUSDMil)
		bys CompanyName CompanyFoundedDate InvestmentYear: egen max_RoundNumber = max(RoundNumber)
		bys CompanyName CompanyFoundedDate InvestmentYear: egen min_RoundNumber = min(RoundNumber)
			gen num_Round = max_RoundNumber - min_RoundNumber + 1
		bys CompanyName CompanyFoundedDate InvestmentYear: egen max_NoofFunds = max(NoofFundsinTotal)
		bys CompanyName CompanyFoundedDate InvestmentYear: egen avg_NoofFunds = mean(NoofFundsinTotal)
		bys CompanyName CompanyFoundedDate InvestmentYear: egen max_NoofFirms = max(NoofFirmsinTotal)
		bys CompanyName CompanyFoundedDate InvestmentYear: egen avg_NoofFirms = mean(NoofFirmsinTotal)
		keep CompanyName CompanyFoundedDate InvestmentYear sum_* max_* avg_* min_*            
		duplicates drop
		sort CompanyName InvestmentYear CompanyFoundedDate
			bys CompanyName InvestmentYear: keep if _n == 1 //keep only the earliest founded obs for firms with the same name
		drop CompanyFoundedDate
		gen year = InvestmentYear 
	save $bt/vc_investment_2002_2020_nodup, replace
	
*an alternative way to construct vc investment data
	use $bt/vc_investment_2002_2020, clear	
		drop InvestmentSecurityTypes  FirmName FundName FundSizeUSDMil FundStateRegion H  TotalNumberofCompaniesInvest FirmStateRegion NoofFundsManagedbyFirm CompanyIPODate CompanyStatus
		duplicates drop
		bys CompanyName InvestmentDate: egen m_NoofFundsinTotal = max(NoofFundsinTotal)
			keep if m_NoofFundsinTotal == NoofFundsinTotal //drop 1 duplicated obs
			drop m_NoofFundsinTotal	
		gen CompanyFoundedYear = substr(CompanyFoundedDate, 6, 4)
			destring CompanyFoundedYear, replace
		gen InvestmentYear = year(InvestmentDate)
		gen AgeAtFinance = InvestmentYear - CompanyFoundedYear + 1
		order CompanyName CompanyFoundedDate InvestmentYear
		bys CompanyName CompanyFoundedDate InvestmentYear: egen sum_EquityAmountEstimated = sum(EquityAmountEstimatedUSDMil)
			replace sum_EquityAmountEstimated = . if sum_EquityAmountEstimated == 0
		bys CompanyName CompanyFoundedDate InvestmentYear: egen avg_EquityAmountEstimated = mean(EquityAmountEstimatedUSDMil)
		bys CompanyName CompanyFoundedDate InvestmentYear: egen sum_EquityAmountDisclosed = sum(EquityAmountDisclosedUSDMil)
			replace sum_EquityAmountDisclosed = . if sum_EquityAmountDisclosed == 0
		bys CompanyName CompanyFoundedDate InvestmentYear: egen avg_EquityAmountDisclosed = mean(EquityAmountDisclosedUSDMil)
		bys CompanyName CompanyFoundedDate InvestmentYear: egen max_RoundNumber = max(RoundNumber)
		bys CompanyName CompanyFoundedDate InvestmentYear: egen min_RoundNumber = min(RoundNumber)
			gen num_Round = max_RoundNumber - min_RoundNumber + 1
		bys CompanyName CompanyFoundedDate InvestmentYear: egen avg_NoofFunds = mean(NoofFundsinTotal)
		bys CompanyName CompanyFoundedDate InvestmentYear: egen avg_NoofFirms = mean(NoofFirmsinTotal)
		keep CompanyName CompanyFoundedDate InvestmentYear sum_* max_* avg_* min_* num_Round AgeAtFinance   
		duplicates drop
		sort CompanyName InvestmentYear CompanyFoundedDate
			bys CompanyName InvestmentYear: keep if _n == 1 //keep only the earliest founded obs for firms with the same name
		drop CompanyFoundedDate
			bys CompanyName: gen n =_n
	save $bt/vc_investment_2002_2020_nodup1, replace	
	
	forvalue i = 1/16{
		use $bt/vc_investment_2002_2020_nodup1, clear
		keep if n == `i'
		drop n
			rename * *`i'
			rename CompanyName`i' CompanyName
		save $bt/vc_investment_2002_2020_nodup1_`i', replace
	}
	

	
	use $bt/vc_investment_2002_2020_nodup1, clear
		keep CompanyName
		duplicates drop
	forvalue i = 1/16{
		merge 1:1 CompanyName using $bt/vc_investment_2002_2020_nodup1_`i'
			drop _merge
		}
	save $bt/vc_investment_2002_2020_nodup_by_investment_year_order, replace
	
		forvalue i = 1/16{
	erase $bt/vc_investment_2002_2020_nodup1_`i'.dta
	}
*step 2: merge with IPO and MA data to get company level IPO and MA info	
	do $NAMDIR/nameonly_main_VC.do

	use $bt/vc_investment_2002_2020_std, clear
		keep CompanyName CompanyStatus CompanyIPODate  CompanyStateRegion  standard_name stem_name CompanyFoundedDate
		rename stem_name vc_comp_stem
		rename standard_name vc_comp_std
		duplicates drop
		sort CompanyName CompanyFoundedDate CompanyStatus
		bys CompanyName CompanyFoundedDate : keep if _n == _N
		replace CompanyIPODate = "" if CompanyIPODate == "-"
		gen CompanyIPODate1 = date(CompanyIPODate, "DMY")
			format CompanyIPODate1 %td
			drop CompanyIPODate
			rename CompanyIPODate1 CompanyIPODate	
			egen vc_comp_id = group(CompanyName CompanyFoundedDate)
	save $bt/report_comp_status_2002_2020, replace

	do $bc/2a_IPO_data_cleaning_v1.do
	
	do $bc/2b_MA_data_cleaning_v1.do

	use $bt/report_comp_status_2002_2020, clear
			merge 1:1 vc_comp_id using $bt/vc_matched_ipo_CRSPD_matched
				drop _merge
			merge 1:1 vc_comp_id using $bt/vc_matched_ma
				drop _merge
			gen acquisition_date =  DA if CompanyStatus == "Acquisition" | CompanyStatus == "Pending Acquisition"
				format acquisition_date %td
		sort CompanyName CompanyFoundedDate
			bys CompanyName: keep if _n == 1 //keep only the earliest founded obs for firms with the same name
	save $bt/vc_company_2002_2020_nodup, replace

