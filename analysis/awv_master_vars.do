
set more off
clear all
capture log, close

***Merge in verified dx dates
use "/disk/agedisk3/medicare.work/goldman-DUA51866/ferido-dua51866/AD/data/adrd_inc_explore/adrdinc_verified0216.dta"
sort bene_id
save "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/inc_sorted", replace

clear

use "/disk/agedisk3/medicare.work/goldman-DUA51866/ferido-dua51866/AD/data/awv/analytical_benemo_inc_20191216.dta", clear
gen time=month+(year-2008)*12
sort bene_id time
merge m:1 bene_id using "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/inc_sorted"
drop if _merge==2

save "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/awv_main.dta", replace


///create new variables,age weights and flags

use "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/awv_main.dta", clear
drop time _merge

keep if year>2007
gen time = month+(year-2008)*12

//Age weights
bysort time: gen tot = _N if time==1
egen freq = count(1), by(time age)
gen pct = .
replace pct=freq/tot if time==1
bysort age (time): replace pct=pct[_n-1] if age==age[_n-1]
gen agew=pct/freq
bysort age (time): replace agew=agew[_n-1] if agew==.


//AWV flag for 12 months
bysort bene_id (time): gen spell = sum(awv)
bysort bene_id spell (time): gen length = _n
gen awv_12 = 0 
replace awv_12 = 1 if (length<=12 & bene_id==bene_id[_n-1] & spell>0)
replace awv_12 = 1 if (length==1 & spell>0 & awv==1)



//Generate ADRD dx dummy then drop after incident dx
	gen all_scen_inc_m = month(all_scen_inc)
	gen all_scen_inc_y = year(all_scen_inc)
	gen all_scen_inc_time = all_scen_inc_m+(all_scen_inc_y-2008)*12
	gen all_scen_inc_f = 0
	replace all_scen_inc_f = . if all_scen_inc_time<0
	bysort bene_id (time): replace all_scen_inc_f = 1 if all_scen_inc_time==time


    gen all_scen_inc_2 = 1 if all_scen_inc_f==1
    bysort bene_id (time): gen spell_all_scen_inc_f = sum(all_scen_inc_f)
    replace all_scen_inc_2 = 0 if spell_all_scen_inc_f==0
    replace awv_12 = . if all_scen_inc_2==.


//Dummy indicators of condition, starting at dx date
foreach var in hypert_ever hyperl_ever amie atrialfe diabtese strktiae deprssne {
	gen `var'_m = month(`var')
	gen `var'_y = year(`var')
	gen `var'_time = `var'_m+(`var'_y-2008)*12
	gen `var'_f = 0
	bysort bene_id (time): replace `var'_f = 1 if `var'_time<0
	bysort bene_id (time): replace `var'_f = 1 if `var'_time==time
	bysort bene_id (time): replace `var'_f = `var'_f[_n-1] if (`var'_f[_n-1]==1 & bene_id==bene_id[_n-1])
}

destring sex race_bg zip3 fips_county fips_state, replace
replace sex = 0 if sex==1
replace sex = 1 if sex==2
gen age2 = age^2


tab time awv_12, row
tab year awv, row

keep if year>=2011

#d;
keep all_scen_inc_2 awv awv_12 hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f lis dual sex race_bg zip3 zip5 zcta5 fips_state countynm fips_county age age2 pct_hsgrads medinc agew bene_id year
;
#d cr

save "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/awv_main.dta", replace

//collapsing to bene-year observations
use "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/awv_main.dta", clear
bysort bene_id: gen tag = 1 if _n==1
tab year tag

gen state = real(fips_state)
drop fips_state
describe

#d;
collapse (max) all_scen_inc_2 awv awv_12 hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f lis dual sex race_bg zip3 zip5 zcta5 state fips_county (mean) age age2 pct_hsgrads medinc agew, by (bene_id year)  
;
#d cr

save "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/awv_yrly.dta", replace

//Merging in urban and rural data at county level
use "/disk/agedisk3/medicare.work/goldman-DUA51866/ferido-dua51866/Original_Data/Area_Resource_File/processed_data/urbanruralcont.dta", clear

drop urbanrural03 urbanrural13
gen urbanrural2015 = urbanrural2014
gen urbanrural2016 = urbanrural2014

keep fips_county urbanrural*
reshape long urbanrural, i(fips_county) j(year)

save "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/urbrural.dta", replace

use "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/urbrural.dta", clear
destring fips_county, replace
tab urbanrural year
sort fips_county year

save "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/urbrural.dta", replace

use "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/awv_yrly.dta", clear
sort fips_county year
merge m:1 fips_county year using "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/urbrural.dta", sorted

tab _m

tab urbanrural year, m
describe
drop _m

save "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/awv_yrly.dta", replace


///Create county-level data set with AWV and change vars
use "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/awv_yrly.dta", clear

bysort fips_county year: egen awv_county = mean(awv)

collapse (max) awv awv_county, by (fips_county year)

sort fips_county year 
gen awv_chg_county = .
replace awv_chg_county = awv_county-awv_county[_n-1] if (fips_county==fips_county[_n-1])
mean(awv_chg_county), over(year)
bysort year: sum awv_chg_county, detail

sort fips_county year
save "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/county.dta", replace 

///Merge county-level awv and awv change into main dataset

use "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/county.dta", clear
sort fips_county year

use "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/awv_yrly.dta", clear
sort fips_county year
merge m:1 fips_county year using "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/county.dta", sorted

mean(awv_chg_county), over(year)
bysort year: sum awv_chg_county, detail
tab _m
save "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/awv_yrly.dta", replace


use "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/awv_yrly.dta", clear

///Create age groups 

gen ageg = .
replace ageg=1 if (age>=65 & age<70)
replace ageg=2 if (age>=70 & age<75)
replace ageg=3 if (age>=75 & age<80)
replace ageg=4 if (age>=80 & age<85)
replace ageg=5 if (age>=85 & age<90)
replace ageg=6 if (age>=90)

///replace missing values

replace race_bg = 99 if race_bg==.
tab race_bg

bysort year: egen medinc_m = mean(medinc)
replace medinc = medinc_m if medinc==.
bysort year: egen hsgrad_m = mean(pct_hsgrads)
replace pct_hsgrads = hsgrad_m if pct_hsgrads==.
drop medinc_m hsgrad_m

tab awv_12, m
tab all_scen_inc_2, m
save "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/awv_yrly.dta", replace



