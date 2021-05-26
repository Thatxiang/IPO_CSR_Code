set more off
set matsize 5000


global root="C:\Users\xzhen\Dropbox\IPO_CSR"

global bi="$root/Build/Input"
global bt="$root/Build/Temp"
global bc="$root/Build/Code"
global bo="$root/Build/Output"
global NAMDIR ="$root/Build/Code/std_name"

*step 1: clean CSR DATA
	do $bc/1_CSR_data_cleaning_v1
	
*step 2: clean VC DATA
	do $bc/2_VC_data_cleaning_v1
	
*step 3: Merge CSR DATA with VC DATA
	do $bc/3_CSR_VC_v1
	
*step 4: Merge NETS DATA with CSR_VC DATA
	do $bc/4_CSR_VC_NETS_v1

