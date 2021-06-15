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

*testing
*CSR news data
use $bi/pm_news_200701_201708, clear
	rename REPRISK_ID reprisk_id
	merge m:1 reprisk_id using $bo/vc_csr_reg_sample
		keep if _merge == 3
		drop _merge
		format NEWS_DATE %td
	drop ISIN
	duplicates drop
	gen year_news = year(NEWS_DATE)
save $bt/pm_news_csr_vc, replace



use $bt/pm_news_csr_vc, clear


		sort reprisk_id year_news
		by reprisk_id year_news: gen news_count=_N
		by reprisk_id year_news: gen log_news_count=ln(news_count)
		by reprisk_id year_news: egen sev_tot= total( SEVERITY)
		by reprisk_id year_news: gen avg_sev_news = sev_tot/news_count
		by reprisk_id year_news: egen nov_tot= total( NOVELTY )
		by reprisk_id year_news: gen avg_nov_news = nov_tot/news_count
		by reprisk_id year_news: egen reach_tot= total( REACH )
		by reprisk_id year_news: gen avg_reach_news = reach_tot/news_count
	
	*** keep year of first CSR rating

by reprisk_id: keep if _n==1

keep if year_news <first_InvestmentYear

keep if year_news <exit_year
		
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
			

	    reghdfe vc_backed news_count, absorb (year ind) cluster(ind)
		est store e1
		reghdfe vc_backed avg_sev_news, absorb (year ind) cluster(ind)
		est store e2
		reghdfe vc_backed avg_nov_news, absorb (year ind) cluster(ind)
		est store e3
		reghdfe vc_backed avg_reach_news, absorb (year ind) cluster(ind)
		est store e4
			outreg2 [e1 e2 e3 e4] using $br/VC_funding_news.xls, keep (news_count avg_sev_news avg_nov_news avg_reach_news) adjr2 dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace
	
		reghdfe exit news_count, absorb (year ind) cluster(ind)
		est store e1
		reghdfe exit avg_sev_news, absorb (year ind) cluster(ind)
		est store e2
		reghdfe exit avg_nov_news, absorb (year ind) cluster(ind)
		est store e3
		reghdfe exit avg_reach_news, absorb (year ind) cluster(ind)
		est store e4
			outreg2 [e1 e2 e3 e4] using $br/IPO_funding_news.xls, keep (news_count avg_sev_news avg_nov_news avg_reach_news) adjr2 dec(3) addtext(Industry FE, Yes, Year FE, Yes) word seeout label excel replace

