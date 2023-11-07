
set more off
clear all
capture log, close


use "/disk/agedisk3/medicare.work/goldman-DUA51866/jthunell-dua51866/awv_yrly.dta"

//Descriptives

drop if year<2011
drop if year==2016
drop if missing(bene_id)
replace awv = . if awv_12==.


bysort bene_id (year): gen tag = 1 if _n==1
tab race_bg tag
tab year tag

tab year awv, row
bysort year: tab awv race_bg, co
bysort year: tab awv ageg, co
bysort year: tab all_scen_inc_2 race_bg  if (awv==1 & awv_12!=.) [aw=agew], co
bysort year: tab all_scen_inc_2 race_bg if (awv==0 & awv_12!=.) [aw=agew], co

tabstat all_scen_inc_2 [aw=agew], statistics(mean) by(year)
tab ageg awv if awv_12!=., co
bysort ageg: tab all_scen_inc_2 awv if awv_12!=., co 
bysort ageg: tab all_scen_inc_2 awv if awv_12!=. [aw=agew], co 

//by AWV - 2011 to 2015
tab all_scen_inc_2 awv if awv_12!=. [aw=agew], co 
tab sex awv if awv_12!=., co chi2 m
ttest all_scen_inc_2 if awv_12!=., by(awv)
tab all_scen_inc_2 awv if (urban==1 & awv_12!=.) [aw=agew], co

foreach var in hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f lis dual sex age pct_hsgrads medinc {
	ttest `var' if awv_12!=., by(awv)
	}

tab sex awv if awv_12!=., co chi2

tab race_bg awv, co chi2 
bysort race_bg: tab all_scen_inc_2 awv [aw=agew], co 


bysort year: sum awv_county, detail
bysort year: sum awv_chg_county, detail

bysort year: sum awv_county if (urbanrural>=1 & urbanrural<=3), detail
bysort year: sum awv_chg_county if (urbanrural>=1 & urbanrural<=3), detail


///Descriptives by AWV and year
bysort year: tab all_scen_inc_2 awv [aw=agew], co
bysort year: ttest all_scen_inc_2, by(awv)

foreach var in hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f lis dual sex age pct_hsgrads medinc {
	bysort year: ttest `var' if awv_12!=., by(awv)
	}

bysort year: tab sex awv if awv_12 !=., co chi2

bysort year: tab race_bg awv if awv_12!=., co chi2 


///OLS models  
#d;
regress all_scen_inc_2 awv_12 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2011.year, cluster(bene_id) 
;
#d cr

#d;
bysort race_bg: regress all_scen_inc_2 awv_12 i.sex lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2011.year, cluster(bene_id) 
;
#d cr

*/
///IVE Models
#d;
 ivregress 2sls all_scen_inc_2 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2012.year (awv_12=awv_chg_county), first
;
#d cr


#d;
bysort race_bg: ivregress 2sls all_scen_inc_2 i.sex lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2012.year (awv_12=awv_chg_county), first
;
#d cr


#d;
 ivregress 2sls all_scen_inc_2 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f (awv_12=awv_chg_county) if year==2015, first
;
#d cr

///Robustness Checks

#d;
logit all_scen_inc_2 awv_12 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2011.year, cluster(bene_id) or
;
#d cr


#d;
logit all_scen_inc_2 awv_12 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2011.year, or
;
#d cr

#d;
areg all_scen_inc_2 awv_12 lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2011.year, absorb(bene_id) vce(robust)
;
#d cr



//OLS and IVE urban areas with 250,000+ only  

#d;
regress all_scen_inc_2 awv_12 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2011.year if (urbanrural==1 | urbanrural==2), cluster(bene_id) 
;
#d cr

#d;
 ivregress 2sls all_scen_inc_2 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2012.year (awv_12=awv_chg_county) if (urbanrural==1 | urbanrural==2), first
;
#d cr

#d;
bysort urbanrural: ivregress 2sls all_scen_inc_2 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2012.year (awv_12=awv_chg_county), first
;
#d cr

#d;
ivregress 2sls all_scen_inc_2 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2012.year (awv_12=awv_chg_county) if urbanrural<=3, first
;
#d cr

#d;
ivregress 2sls all_scen_inc_2 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2012.year (awv_12=awv_chg_county) if (urbanrural>=4), first
;
#d cr


///OLS and IVE - urban counties with <250k only
#d;
regress all_scen_inc_2 awv_12 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2011.year if (urbanrural==3), cluster(bene_id) 
;
#d cr

#d;
 ivregress 2sls all_scen_inc_2 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2012.year (awv_12=awv_chg_county) if (urbanrural==3), first
;
#d cr

///OLS and IVE with all USDA urban counties
#d;
regress all_scen_inc_2 awv_12 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2011.year if (urbanrural<=3), cluster(bene_id) 
;
#d cr

#d;
bysort urbanrural: ivregress 2sls all_scen_inc_2 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2012.year (awv_12=awv_chg_county), first
;
#d cr

//2 largest county groups
#d;
bysort urbanrural: ivregress 2sls all_scen_inc_2 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2012.year (awv_12=awv_chg_county) if (urbanrural==1 | urbanrural==2), first
;
#d cr

*2 largest groups on non-urban counties
#d;
 ivregress 2sls all_scen_inc_2 i.sex i.race_bg lis dual age age2 pct_hsgrads medinc hypert_ever_f hyperl_ever_f amie_f atrialfe_f diabtese_f strktiae_f deprssne_f ib2012.year (awv_12=awv_chg_county) if (urbanrural==3 | urbanrural==4), first
;
#d cr

