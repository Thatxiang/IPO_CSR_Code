set more off
set matsize 5000

	global root="C:\Users\xzhen\Dropbox\IPO_CSR"


global bi="$root/Build/Input"
global bv="$root/Build/Input/VC_Data"
global bt="$root/Build/Temp"
global bc="$root/Build/Code"
global bo="$root/Build/Output"
global NAMDIR ="$root/Build/Code/std_name"
cap log close
cap log using $bt/0_data_import,t replace	

**import VC data (I download VC data from VentureXpert four times since it restricts the maximum number of variable being download each time.)
*VC Data part 1
     import excel $bv/report_01012002_06302002.xls, sheet("Quick Search") firstrow clear
     save $bi/report_01012002_06302002, replace
     import excel $bv/report_07012002_09302003.xls, sheet("Quick Search") firstrow clear
     save $bi/report_07012002_09302003, replace
     import excel $bv/report_10012003_09302004.xls, sheet("Quick Search") firstrow clear
     save $bi/report_10012003_09302004, replace
     import excel $bv/report_10012004_09302005.xls, sheet("Quick Search") firstrow clear
     save $bi/report_10012004_09302005, replace
     import excel $bv/report_10012005_08312006.xls, sheet("Quick Search") firstrow clear
     save $bi/report_10012005_08312006, replace
     import excel $bv/report_09012006_06302007.xls, sheet("Quick Search") firstrow clear
     save $bi/report_09012006_06302007, replace
     import excel $bv/report_07012007_03312008.xls, sheet("Quick Search") firstrow clear
     save $bi/report_07012007_03312008, replace
     import excel $bv/report_04012008_12312008.xls, sheet("Quick Search") firstrow clear
     save $bi/report_04012008_12312008, replace
     import excel $bv/report_01012009_03312010.xls, sheet("Quick Search") firstrow clear
     save $bi/report_01012009_03312010, replace
     import excel $bv/report_04012010_03312011.xls, sheet("Quick Search") firstrow clear
     save $bi/report_04012010_03312011, replace
     import excel $bv/report_04012011_02292012.xls, sheet("Quick Search") firstrow clear
     save $bi/report_04012011_02292012, replace
     import excel $bv/report_03012012_01312013.xls, sheet("Quick Search") firstrow clear
     save $bi/report_03012012_01312013, replace
     import excel $bv/report_02012013_12312013.xls, sheet("Quick Search") firstrow clear
     save $bi/report_02012013_12312013, replace
     import excel $bv/report_01012014_10312014.xls, sheet("Quick Search") firstrow clear
     save $bi/report_01012014_10312014, replace
     import excel $bv/report_11012014_07312015.xls, sheet("Quick Search") firstrow clear
     save $bi/report_11012014_07312015, replace
     import excel $bv/report_08012015_05312016.xls, sheet("Quick Search") firstrow clear
     save $bi/report_08012015_05312016, replace
     import excel $bv/report_06012016_04302017.xls, sheet("Quick Search") firstrow clear
     save $bi/report_06012016_04302017, replace
     import excel $bv/report_05012017_01312018.xls, sheet("Quick Search") firstrow clear
     save $bi/report_05012017_01312018, replace
     import excel $bv/report_02012018_10312018.xls, sheet("Quick Search") firstrow clear
     save $bi/report_02012018_10312018, replace
     import excel $bv/report_11012018_06302019.xls, sheet("Quick Search") firstrow clear
     save $bi/report_11012018_06302019, replace
     import excel $bv/report_07012019_03012020.xls, sheet("Quick Search") firstrow clear
     save $bi/report_07012019_03012020, replace
		
use $bi/report_01012002_06302002, clear
     append using $bi/report_07012002_09302003
     append using $bi/report_10012003_09302004
     append using $bi/report_10012004_09302005
     append using $bi/report_10012005_08312006
     append using $bi/report_09012006_06302007
     append using $bi/report_07012007_03312008
     append using $bi/report_04012008_12312008
     append using $bi/report_01012009_03312010
     append using $bi/report_04012010_03312011
     append using $bi/report_04012011_02292012
     append using $bi/report_03012012_01312013
     append using $bi/report_02012013_12312013
     append using $bi/report_01012014_10312014
     append using $bi/report_11012014_07312015
     append using $bi/report_08012015_05312016
     append using $bi/report_06012016_04302017
     append using $bi/report_05012017_01312018
     append using $bi/report_02012018_10312018
     append using $bi/report_11012018_06302019
     append using $bi/report_07012019_03012020
save $bi/report_01012002_03012020, replace		
	
	
     erase $bi/report_01012002_06302002.dta
     erase $bi/report_07012002_09302003.dta
     erase $bi/report_10012003_09302004.dta
     erase $bi/report_10012004_09302005.dta
     erase $bi/report_10012005_08312006.dta
     erase $bi/report_09012006_06302007.dta
     erase $bi/report_07012007_03312008.dta
     erase $bi/report_04012008_12312008.dta
     erase $bi/report_01012009_03312010.dta
     erase $bi/report_04012010_03312011.dta
     erase $bi/report_04012011_02292012.dta
     erase $bi/report_03012012_01312013.dta
     erase $bi/report_02012013_12312013.dta
     erase $bi/report_01012014_10312014.dta
     erase $bi/report_11012014_07312015.dta
     erase $bi/report_08012015_05312016.dta
     erase $bi/report_06012016_04302017.dta
     erase $bi/report_05012017_01312018.dta
     erase $bi/report_02012018_10312018.dta
     erase $bi/report_11012018_06302019.dta
     erase $bi/report_07012019_03012020.dta	

*VC Data part 2	 
     import excel $bv/report1_01012002_06302002.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_01012002_06302002, replace
     import excel $bv/report1_07012002_09302003.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_07012002_09302003, replace
     import excel $bv/report1_10012003_09302004.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_10012003_09302004, replace
     import excel $bv/report1_10012004_09302005.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_10012004_09302005, replace
     import excel $bv/report1_10012005_08312006.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_10012005_08312006, replace
     import excel $bv/report1_09012006_06302007.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_09012006_06302007, replace
     import excel $bv/report1_07012007_03312008.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_07012007_03312008, replace
     import excel $bv/report1_04012008_12312008.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_04012008_12312008, replace
     import excel $bv/report1_01012009_03312010.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_01012009_03312010, replace
     import excel $bv/report1_04012010_03312011.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_04012010_03312011, replace
     import excel $bv/report1_04012011_02292012.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_04012011_02292012, replace
     import excel $bv/report1_03012012_01312013.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_03012012_01312013, replace
     import excel $bv/report1_02012013_12312013.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_02012013_12312013, replace
     import excel $bv/report1_01012014_10312014.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_01012014_10312014, replace
     import excel $bv/report1_11012014_07312015.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_11012014_07312015, replace
     import excel $bv/report1_08012015_05312016.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_08012015_05312016, replace
     import excel $bv/report1_06012016_04302017.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_06012016_04302017, replace
     import excel $bv/report1_05012017_01312018.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_05012017_01312018, replace
     import excel $bv/report1_02012018_10312018.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_02012018_10312018, replace
     import excel $bv/report1_11012018_06302019.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_11012018_06302019, replace
     import excel $bv/report1_07012019_03012020.xls, sheet("Quick Search") firstrow clear
     save $bi/report1_07012019_03012020, replace
		
use $bi/report1_01012002_06302002, clear
     append using $bi/report1_07012002_09302003
     append using $bi/report1_10012003_09302004
     append using $bi/report1_10012004_09302005
     append using $bi/report1_10012005_08312006
     append using $bi/report1_09012006_06302007
     append using $bi/report1_07012007_03312008
     append using $bi/report1_04012008_12312008
     append using $bi/report1_01012009_03312010
     append using $bi/report1_04012010_03312011
     append using $bi/report1_04012011_02292012
     append using $bi/report1_03012012_01312013
     append using $bi/report1_02012013_12312013
     append using $bi/report1_01012014_10312014
     append using $bi/report1_11012014_07312015
     append using $bi/report1_08012015_05312016
     append using $bi/report1_06012016_04302017
     append using $bi/report1_05012017_01312018
     append using $bi/report1_02012018_10312018
     append using $bi/report1_11012018_06302019
     append using $bi/report1_07012019_03012020
save $bi/report1_01012002_03012020, replace		
	
	
     erase $bi/report1_01012002_06302002.dta
     erase $bi/report1_07012002_09302003.dta
     erase $bi/report1_10012003_09302004.dta
     erase $bi/report1_10012004_09302005.dta
     erase $bi/report1_10012005_08312006.dta
     erase $bi/report1_09012006_06302007.dta
     erase $bi/report1_07012007_03312008.dta
     erase $bi/report1_04012008_12312008.dta
     erase $bi/report1_01012009_03312010.dta
     erase $bi/report1_04012010_03312011.dta
     erase $bi/report1_04012011_02292012.dta
     erase $bi/report1_03012012_01312013.dta
     erase $bi/report1_02012013_12312013.dta
     erase $bi/report1_01012014_10312014.dta
     erase $bi/report1_11012014_07312015.dta
     erase $bi/report1_08012015_05312016.dta
     erase $bi/report1_06012016_04302017.dta
     erase $bi/report1_05012017_01312018.dta
     erase $bi/report1_02012018_10312018.dta
     erase $bi/report1_11012018_06302019.dta
     erase $bi/report1_07012019_03012020.dta	
     
*VC Data part 3
	 import excel $bv/report2_01012002_06302002.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_01012002_06302002, replace
     import excel $bv/report2_07012002_09302003.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_07012002_09302003, replace
     import excel $bv/report2_10012003_09302004.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_10012003_09302004, replace
     import excel $bv/report2_10012004_09302005.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_10012004_09302005, replace
     import excel $bv/report2_10012005_08312006.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_10012005_08312006, replace
     import excel $bv/report2_09012006_06302007.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_09012006_06302007, replace
     import excel $bv/report2_07012007_03312008.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_07012007_03312008, replace
     import excel $bv/report2_04012008_12312008.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_04012008_12312008, replace
     import excel $bv/report2_01012009_03312010.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_01012009_03312010, replace
     import excel $bv/report2_04012010_03312011.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_04012010_03312011, replace
     import excel $bv/report2_04012011_02292012.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_04012011_02292012, replace
     import excel $bv/report2_03012012_01312013.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_03012012_01312013, replace
     import excel $bv/report2_02012013_12312013.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_02012013_12312013, replace
     import excel $bv/report2_01012014_10312014.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_01012014_10312014, replace
     import excel $bv/report2_11012014_07312015.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_11012014_07312015, replace
     import excel $bv/report2_08012015_05312016.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_08012015_05312016, replace
     import excel $bv/report2_06012016_04302017.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_06012016_04302017, replace
     import excel $bv/report2_05012017_01312018.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_05012017_01312018, replace
     import excel $bv/report2_02012018_10312018.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_02012018_10312018, replace
     import excel $bv/report2_11012018_06302019.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_11012018_06302019, replace
     import excel $bv/report2_07012019_03012020.xls, sheet("Quick Search") firstrow clear
     save $bi/report2_07012019_03012020, replace
          
use $bi/report2_01012002_06302002, clear
     append using $bi/report2_07012002_09302003
     append using $bi/report2_10012003_09302004
     append using $bi/report2_10012004_09302005
     append using $bi/report2_10012005_08312006
     append using $bi/report2_09012006_06302007
     append using $bi/report2_07012007_03312008
     append using $bi/report2_04012008_12312008
     append using $bi/report2_01012009_03312010
     append using $bi/report2_04012010_03312011
     append using $bi/report2_04012011_02292012
     append using $bi/report2_03012012_01312013
     append using $bi/report2_02012013_12312013
     append using $bi/report2_01012014_10312014
     append using $bi/report2_11012014_07312015
     append using $bi/report2_08012015_05312016
     append using $bi/report2_06012016_04302017
     append using $bi/report2_05012017_01312018
     append using $bi/report2_02012018_10312018
     append using $bi/report2_11012018_06302019
     append using $bi/report2_07012019_03012020
save $bi/report2_01012002_03012020, replace       
     
     
     erase $bi/report2_01012002_06302002.dta
     erase $bi/report2_07012002_09302003.dta
     erase $bi/report2_10012003_09302004.dta
     erase $bi/report2_10012004_09302005.dta
     erase $bi/report2_10012005_08312006.dta
     erase $bi/report2_09012006_06302007.dta
     erase $bi/report2_07012007_03312008.dta
     erase $bi/report2_04012008_12312008.dta
     erase $bi/report2_01012009_03312010.dta
     erase $bi/report2_04012010_03312011.dta
     erase $bi/report2_04012011_02292012.dta
     erase $bi/report2_03012012_01312013.dta
     erase $bi/report2_02012013_12312013.dta
     erase $bi/report2_01012014_10312014.dta
     erase $bi/report2_11012014_07312015.dta
     erase $bi/report2_08012015_05312016.dta
     erase $bi/report2_06012016_04302017.dta
     erase $bi/report2_05012017_01312018.dta
     erase $bi/report2_02012018_10312018.dta
     erase $bi/report2_11012018_06302019.dta
     erase $bi/report2_07012019_03012020.dta 

*VC Data part 4     
    import excel $bv/report3_01012002_06302002.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_01012002_06302002, replace
     import excel $bv/report3_07012002_09302003.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_07012002_09302003, replace
     import excel $bv/report3_10012003_09302004.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_10012003_09302004, replace
     import excel $bv/report3_10012004_09302005.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_10012004_09302005, replace
     import excel $bv/report3_10012005_08312006.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_10012005_08312006, replace
     import excel $bv/report3_09012006_06302007.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_09012006_06302007, replace
     import excel $bv/report3_07012007_03312008.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_07012007_03312008, replace
     import excel $bv/report3_04012008_12312008.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_04012008_12312008, replace
     import excel $bv/report3_01012009_03312010.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_01012009_03312010, replace
     import excel $bv/report3_04012010_03312011.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_04012010_03312011, replace
     import excel $bv/report3_04012011_02292012.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_04012011_02292012, replace
     import excel $bv/report3_03012012_01312013.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_03012012_01312013, replace
     import excel $bv/report3_02012013_12312013.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_02012013_12312013, replace
     import excel $bv/report3_01012014_10312014.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_01012014_10312014, replace
     import excel $bv/report3_11012014_07312015.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_11012014_07312015, replace
     import excel $bv/report3_08012015_05312016.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_08012015_05312016, replace
     import excel $bv/report3_06012016_04302017.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_06012016_04302017, replace
     import excel $bv/report3_05012017_01312018.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_05012017_01312018, replace
     import excel $bv/report3_02012018_10312018.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_02012018_10312018, replace
     import excel $bv/report3_11012018_06302019.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_11012018_06302019, replace
     import excel $bv/report3_07012019_03012020.xls, sheet("Quick Search") firstrow clear
     save $bi/report3_07012019_03012020, replace
          
use $bi/report3_01012002_06302002, clear
     append using $bi/report3_07012002_09302003
     append using $bi/report3_10012003_09302004
     append using $bi/report3_10012004_09302005
     append using $bi/report3_10012005_08312006
     append using $bi/report3_09012006_06302007
     append using $bi/report3_07012007_03312008
     append using $bi/report3_04012008_12312008
     append using $bi/report3_01012009_03312010
     append using $bi/report3_04012010_03312011
     append using $bi/report3_04012011_02292012
     append using $bi/report3_03012012_01312013
     append using $bi/report3_02012013_12312013
     append using $bi/report3_01012014_10312014
     append using $bi/report3_11012014_07312015
     append using $bi/report3_08012015_05312016
     append using $bi/report3_06012016_04302017
     append using $bi/report3_05012017_01312018
     append using $bi/report3_02012018_10312018
     append using $bi/report3_11012018_06302019
     append using $bi/report3_07012019_03012020
save $bi/report3_01012002_03012020, replace       
     
     
     erase $bi/report3_01012002_06302002.dta
     erase $bi/report3_07012002_09302003.dta
     erase $bi/report3_10012003_09302004.dta
     erase $bi/report3_10012004_09302005.dta
     erase $bi/report3_10012005_08312006.dta
     erase $bi/report3_09012006_06302007.dta
     erase $bi/report3_07012007_03312008.dta
     erase $bi/report3_04012008_12312008.dta
     erase $bi/report3_01012009_03312010.dta
     erase $bi/report3_04012010_03312011.dta
     erase $bi/report3_04012011_02292012.dta
     erase $bi/report3_03012012_01312013.dta
     erase $bi/report3_02012013_12312013.dta
     erase $bi/report3_01012014_10312014.dta
     erase $bi/report3_11012014_07312015.dta
     erase $bi/report3_08012015_05312016.dta
     erase $bi/report3_06012016_04302017.dta
     erase $bi/report3_05012017_01312018.dta
     erase $bi/report3_02012018_10312018.dta
     erase $bi/report3_11012018_06302019.dta
     erase $bi/report3_07012019_03012020.dta      
     


