/*********************************************************************************************/
title1 'Annual Well Visit Analysis';

* Author: PF;
* Purpose: Set up analytical data set for modelling;
* Input: awv.analytical, awv.bene_characteristics;
* Output: ;

options compress=yes nocenter ls=150 ps=200 errors=5 errorabend errorcheck=strict mprint merror
	mergenoby=warn varlenchk=warn dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

%include "../../../../51866/PROGRAMS/setup.inc";
%partABlib(types=bsf);
libname awv "../../data/awv/";
libname extracts cvp ("&datalib.Claim_Extracts/ProcedureCodes");
libname addrugs "../../data/ad_drug_use";
libname demdx "../../data/dementiadx";
libname exp "../../data/adrd_inc_explore";
libname bene "&datalib.Clean_Data/BeneStatus/";
libname repbase "../../data/aht/base";
libname hcc "&datalib.Clean_Data/HealthStatus/HCCscores";

%let maxyr=2016;

***** First identifying sample for wash out period;
		* sample requires Pt D, and FFS for 12 months in years t-2 and t-1;
		* sample requires FFS, Pt D and 67+ in year t;
data samp;
	set exp.ffsptd_samp_0416 (keep=bene_id birth_date death_date ptD: enrFFS: enrAB: age_beg: sex race_bg);
	by bene_id;

	array insamp [2008:&maxyr.] insamp2008-insamp&maxyr.;
	array ptD [2006:&maxyr.] ptD_allyr2006-ptD_allyr&maxyr.;
	array FFS [2006:&maxyr.] enrffs_allyr2006-enrffs_allyr&maxyr.;
	array ABmo [2006:&maxyr.] enrAB_mo_yr2006-enrAB_mo_yr&maxyr.;
	array age_beg [2008:&maxyr.] age_beg2008-age_beg&maxyr.;
	
	do yr=2008 to &maxyr.;
		insamp[yr]=0;
	end;
	
	* 2008 - don't use 2006 for Part D;
	if ptD[2007]="Y" and ptD[2008]="Y"
	and FFS[2006]="Y" and FFS[2007]="Y" and FFS[2008]="Y"
	and ABmo[2006]=12 and ABmo[2007]=12 
	and age_beg[2008]>=67
	then insamp[2008]=1;
	
	do yr=2009 to &maxyr.; 
		if ptD[yr-2]="Y" and ptD[yr-1]="Y" and ptD[yr]="Y"
		and FFS[yr-2]="Y" and FFS[yr-1]="Y" and FFS[yr]="Y"
		and ABmo[yr-2]=12 and ABmo[yr-1]=12
		and age_beg[yr]>=67
		then insamp[yr]=1; 
	end;
	
	anysamp=max(of insamp2008-insamp&maxyr.);
	
	if anysamp;

run;
	
data analytical;
	merge awv.analytical&maxyr. (in=a) samp (in=b);
	by bene_id;
	if b; * only keeping those in sample;
run;

proc sort data=analytical; by bene_id year month date; run;
	
***** Second finding incident dx, require 2 year washout;
data incidentdx;
	set analytical;
	by bene_id;
	
	if first.bene_id then do;
		firstADRD=.;
		firstmci=.;
		firstsymp=.;
		firstADRDplus=.;
	end;
	format birth_date death_date firstADRD firstADRDplus firstmci firstsymp ADRD_inc mci_inc symp_inc ADRDplus_inc mmddyy10.;
	retain firstADRD firstADRDplus firstmci firstsymp ;
	
	array insamp [2008:&maxyr.] insamp2008-insamp&maxyr.;
	
	if firstADRD=. and anyupper(dxtypes) then firstADRD=date;
	if firstmci=. and find(dxtypes,'m') then firstmci=date;
	if firstsymp=. and symptom then firstsymp=date;
	if firstADRDplus=. and (anyupper(dxtypes) or find(dxtypes,'m') or symptom) then firstadrdplus=date;
	
	if last.bene_id;
	
	* Keeping only incident dates where they are insamp and year is >=2008;
	
	if year(firstADRD)>=2008 then do; 
		if insamp[year(firstADRD)] then ADRD_inc=firstADRD;
	end;
	if year(firstmci)>=2008 then do;
		if insamp[year(firstmci)] then mci_inc=firstmci;
	end;
	if year(firstsymp)>=2008 then do;
		if insamp[year(firstsymp)] then symp_inc=firstsymp;
	end;
	if year(firstadrdplus)>=2008 then do;
		if insamp[year(firstadrdplus)] then ADRDplus_inc=firstadrdplus;
	end;
	
	keep bene_id first: ADRD_inc mci_inc symp_inc ADRDplus_inc birth_date death_date insamp:;
run;

proc print data=analytical (obs=200); run;
proc print data=incidentdx (obs=100); run;

***** Create monthly flags for preventive care;
proc means data=analytical noprint nway;
	class bene_id year month;
	output out=preventive_mo (drop=_type_ _Freq_) max(flushot_admin colonoscopy
	pelvic_breast PSA mammography awv)=;
run;

***** Creating long beneficiary-month from bene_status_month if they were AB and Part D in that month;
data benemo;
	set bene.bene_status_month2008 (drop=dual)
			bene.bene_status_month2009 (drop=dual)
			bene.bene_status_month2010 (drop=dual)
			bene.bene_status_month2011 (drop=dual)
			bene.bene_status_month2012 (drop=dual)
			bene.bene_status_month2013 (drop=dual)
			bene.bene_status_month2014 (drop=dual)
			bene.bene_status_month2015 (drop=dual)
			bene.bene_status_month&maxyr. (drop=dual);
	by bene_id year month;
	if enrAB="Y" and enrHMO ne "Y" and ptDtype in("H","E","R","S");
	if cstshr in("04","05","06","07","08") then lis=1; else lis=0;
	if dual_cstshr="Y" then dual=1; else dual=0;
	keep bene_id year month age_inmo sex race_bg dual lis;
run;

* Merging to bene_characteristics to keep sample;
data benemo1;
	merge benemo (in=a) samp (in=b keep=bene_id birth_date death_date enrFFS: enrAB: ptD: insamp:);
	by bene_id;
	array insamp [2008:&maxyr.] insamp2008-insamp&maxyr.;
	if a and insamp[year]=1; * keeps people who are in samp and months in samp;
	format birth_date death_date mmddyy10.;
run;

proc print data=benemo1 (obs=100); run;
	
proc sort data=repbase.geoses_long0716_zipupdate out=geoses_long0716; by bene_id year; run;

* Create an hcc yearly data set;
data hccyear;
	set hcc.bene_hccscores2008 (in=_2008) 
			hcc.bene_hccscores2009 (in=_2009)
			hcc.bene_hccscores2010 (in=_2010)
			hcc.bene_hccscores2011 (in=_2011)
			hcc.bene_hccscores2012 (in=_2012)
			hcc.bene_hccscores2013 (in=_2013)
			hcc.bene_hccscores2014 (in=_2014)
			hcc.bene_hccscores2015 (in=_2015)
			hcc.bene_hccscores&maxyr. (in=_&maxyr.);
	if _2008 then year=2008;
	if _2009 then year=2009;
	if _2010 then year=2010;
	if _2011 then year=2011;
	if _2012 then year=2012;
	if _2013 then year=2013;
	if _2014 then year=2014;
	if _2015 then year=2015;
	if _&maxyr. then year=&maxyr.;
	keep bene_id year resolved_hcc01-resolved_hcc12;
run;

proc sort data=hccyear; by bene_id year; run;
	
* Merge to bene_id and geoses information;
data benemo2;
	merge benemo1 (in=a) geoses_long0716(in=b keep=bene_id year pct_hsgrads medinc zip: zcta:)
	hccyear (in=c);
	by bene_id year;
	if a;
	array hccmo [*] resolved_hcc01-resolved_hcc12;
	hcc=hccmo[month];
run;

proc print data=benemo2 (obs=100);
	where resolved_hcc01 ne .;
	var bene_id month year hcc resolved_hcc:;
run;

* Merge to preventive by month;
data benemo3;
	merge benemo2 (in=a) preventive_mo (in=b);
	by bene_id year month;
	if a;
run;

* Finally, merging to incident dx and flagging months for incident;
data benemo4;
	merge benemo3 (in=a) incidentdx (in=b);
	by bene_id;
	if a;
	
	* Making sure all other dummies are 0 in the month if they aren't 1;
	array prev [*] flushot_admin colonoscopy pelvic_breast PSA mammography awv;
	do i=1 to dim(prev);
		if prev[i]=. then prev[i]=0;
	end;
	
	rename age_inmo=age;
	drop enr: ptD: i resolved:;
run;

* Getting quartlies on HCC;
proc means data=benemo4 noprint;
	var hcc;
	output out=stats min= p25= p50= p75= / autoname;
run;

proc sql;
	create table awv.analytical_benemo_prev&maxyr. as
	select x.*,
	case when y.hcc_min<=x.hcc<y.hcc_p25 then 1
			 when y.hcc_p25<=x.hcc<y.hcc_p50 then 2
			 when y.hcc_p50<=x.hcc<y.hcc_p75 then 3
			 when y.hcc_p75<=x.hcc then 4
	end as hcc4
	from benemo4 as x, stats as y
	order by bene_id, year, month;
quit;

/*********************************************************************************************
Adding new variables for ADRD+, ADRD, symp, mci that now don't require mutual exclusivitiy 
between ADRD, symp and MCI. For ADRD, symp and mci, will flag the first occurrence clearning
out any diagnoses in a prior year. Can potentially have all three in one year. ADRD+ will be
flagged anytime an ADRD, symp or MCI are flagged
*********************************************************************************************/

data analytical_benemo_inc&maxyr. dropped_nonatrisk;
	set awv.analytical_benemo_prev&maxyr.;
	by bene_id;

	* First creating data true incident variables;
		ADRDplus=0;
		mci=0;
		symp=0;
		adrd=0;
		if year(adrdplus_inc)=year and month(adrdplus_inc)=month then do;
			ADRDplus=1;
			if year(adrd_inc)=year and month(adrd_inc)=month then ADRD=1;
			else if year(mci_inc)=year and month(mci_inc)=month then mci=1;
			else if year(symp_inc)=year and month(symp_inc)=month then symp=1;
		end;
	
		if .<firstadrdplus<mdy(month,1,year) then do;
			ADRDplus=.;
			mci=.;
			symp=.;
			adrd=.;
		end;
		
		* Second creating data set with new variables;
		adrd_b=0;
		mci_b=0;
		symp_b=0;
		ADRDplus_b=0;
		
		 if year(adrd_inc)=year and month(adrd_inc)=month and year(adrdplus_inc)>=year(adrd_inc) then adrd_b=1;
		 if year(mci_inc)=year and month(mci_inc)=month and year(adrdplus_inc)>=year(mci_inc) then mci_b=1;
		 if year(symp_inc)=year and month(symp_inc)=month and year(adrdplus_inc)>=year(symp_inc) then symp_b=1;
		 
		 if max(adrd_b,mci_b,symp_b)=1 then ADRDplus_b=1;
		 
		 if adrd_b=1 then ageatdx_b=(adrd_inc-birth_date)/365;
		 if mci_b=1 then ageatdx_b=(mci_inc-birth_date)/365;
		 if symp_b=1 then ageatdx_b=(symp_inc-birth_date)/365;
		 format ageatdx_b mmddyy10.;
		 
		 label
			 adrd_b="Incident ADRD dx in this month, no diagnosis in prior calendar years"
			 mci_b="Incidence MCI dx in this month, no diagnosis in prior calendar years"
			 symp_b="Incidence symp dx in this month, no diagnosis in prior calendar years"
			 ADRDplus_b="Incident ADRD, MCI or symp in this month, no diagnosis in prior calendar years"
			 adrd="Incident ADRD dx in this month, no prior diagnoses"
			 mci="Incidence MCI dx in this month, no prior diagnoses"
			 symp="Incidence symp dx in this month, no prior diagnoses"
			 ADRDplus="Incident ADRD in this month, no prior diagnoses";
		 
		 if .<year(firstadrdplus)<year then output dropped_nonatrisk;
		 else output analytical_benemo_inc_&maxyr.;
	
run;

* Merge chronic conditions covariates and verified dementia diagnoses;
data awv.analytical_benemo_inc_20191216;
	merge analytical_benemo_inc_&maxyr. (in=a) demdx.cc_0216 (in=b) exp.adrdinc_verified0216 (in=c keep=bene_id all_scen_inc dxrx_scen_inc dx_scen_inc);
    by bene_id; 
	if a;
	keep ADRDplus_inc ADRD_inc all_scen_inc dxrx_scen_inc bene_id year month birth_date death_date race_bg sex dual lis age hcc4 zip5 zip3 zcta5 pct_hsgrads medinc
	awv psa colonoscopy pelvic_breast flushot_admin mammography amie atrialfe deprssne diabtese hyperl_ever hypert_ever strktiae
	fips_state fips_county ssa_county ssa_state statenm countynm;
run;

* The only people and months remaining should be the people who have never gotten an ADRD until their last month in the data;
proc print data=awv.analytical_benemo_inc_20191216 (obs=500);
	where ADRDplus_inc ne .;
	var bene_id year month first: ADRD: mci_inc symp_inc mci symp ageatdx birth_date insamp:;
run;

proc print data=dropped_nonatrisk (obs=100); run;

proc contents data=awv.analytical_benemo_inc_20191216; run;
proc contents data=awv.analytical_benemo_prev&maxyr.; run;
proc univariate data=awv.analytical_benemo_inc_20191216 noprint outtable=benemo_inc; run;
proc univariate data=awv.analytical_benemo_prev&maxyr. noprint outtable=benemo_prev; run;
proc print data=benemo_inc; 
proc print data=benemo_prev; run;

/*
proc compare base=awv.analytical_benemo_inc_20191216 compare=awv.analytical_benemo_inc; by bene_id year month; run;
proc compare base=awv.analytical_benemo_prev compare=awv.analytical_benemo_prev; by bene_id year month; run;
*/	
	
	
	
	
	
	