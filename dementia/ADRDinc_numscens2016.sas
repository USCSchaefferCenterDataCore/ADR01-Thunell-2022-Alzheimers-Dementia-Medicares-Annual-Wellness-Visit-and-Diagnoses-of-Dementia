/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: 	Verified ADRD Valid Verified Scenarios - skipping numbers to line up with other analysis
		- 1) ADRD + RX drug
		- 2) ADRD + ADRD 
		- 3) ADRD + Dementia Symptoms
		- 4) ADRD + Death	
		Merging together AD drugs, Dementia claims, dementia symptoms, specialists,
		& relevant CPT codes to make final analytical file
		- Adding limits to the verifications:
			- Death needs to occur within a year for it to count as a verify condition
			- All other verification needs to occur within 2 years for it count as a verify countion;

* Input: &ctyp._diag&year;
* Output: ADRDinc_0214_lim;

options compress=yes nocenter ls=150 ps=200 errors=5 errorabend errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

%include "../../../../51866/PROGRAMS/setup.inc";
%include "&maclib.listvars.mac";
libname exp "../../data/adrd_inc_explore";
libname demdx "../../data/dementiadx";
libname addrugs "../../data/ad_drug_use";
libname bene "../../../../51866/DATA/Clean_Data/BeneStatus";

%let minyear=&minyear.;
%let maxyear=&maxyear.;

data _null_;
	time=mdy(12,31,&maxyear.)-mdy(1,1,&minyear.)+1;
	call symput('time',time);
run;

%put &time;

proc contents data=demdx.adrd_dxdate_&minyear._&maxyear.; run;
proc contents data=addrugs.addrugs_dts_0616; run;
proc contents data=exp.dem_symptoms&minyear._&maxyear.; run;

data analytical;
	format year best4.;
	merge demdx.adrd_dxdate_&minyear._&maxyear. (in=a rename=demdx_dt=date) addrugs.addrugs_dts_0616 (in=b rename=srvc_dt=date where=(dayssply>=14))
		exp.dem_symptoms&minyear._&maxyear. (in=c);
	by bene_id year date;
	if bene_id ne "";
	if compress(dxtypes,,"l") ne "" then dx=1; * limiting to ccw dementia;
	else dx=0;
	if compress(dxtypes,"A","l") ne "" then naddx=1; 
	else naddx=0;
	if find(dxtypes,"A") then addx=1;
	else addx=0;
	
	if aphasia=1 then symptom_quala="aph";
	if amnesia=1 then symptom_qualb="amn";
	if agnosia_apraxia=1 then symptom_qualc="agn";
	if find(dxtypes,'m') then do;
		symptom=1;
		symptom_quald="mci";
	end;
	symptoms_desc=symptom_quala||symptom_qualb||symptom_qualc||symptom_quald;
	drop symptom_qual:;
run;

data analytical1;
	merge analytical (in=a) bene.bene_demog&maxyear. (in=b keep=bene_id death_date birth_date);
	by bene_id;
	if a;
run;

***** Analysis of AD Incidence;

data ADRDinc_0216_numscens_long;
	set analytical1;
	by bene_id year date;
	
	length first_adrd_type $9. first_symptoms_desc $12.;
	
	* For everybody, getting date of first AD dx, dementia dx, dementia symptoms, or AD drug use
	- If any of the above dates come before the qualifications for AD outcome below, then that 
	person has no outcome;
	if first.bene_id then do;
		first_dx=.;
		first_adrd_type="";
		first_adrx=.;
		first_symptoms=.;
		first_symptoms_desc="";
	end;
	retain first_dx first_adrx first_symptoms first_symptoms_desc;
	
	* Setting first ADRX, dem symtpoms & ADRD date;
	if first_dx=. and dx=1 then do;
		first_dx=date;
		first_adrd_type=dxtypes;
	end;
	if first_adrx=. and ADdrug=1 then first_adrx=date;
	if first_symptoms=. and symptom=1 then do;
		first_symptoms=date;
		first_symptoms_desc=symptoms_desc;
	end;
	format first_dx first_adrx first_symptoms birth_date death_date mmddyy10.;

	* Scenario 1: Flagging as ADRD incident if ADRD diagnosis and >= 1 prescription of an AD medication (in any sequence);
		array scen_dxrx_rxdt_ [&time.] _temporary_;
		array scen_dxrx_dxdt_ [&time.] _temporary_;
		
		if first.bene_id then do;
			scen_dxrx_dt=.;
			scen_dxrx_verifytime=.;
			scen_dxrx_rxdt=.;
			scen_dxrx_dxdt=.;
			do i=1 to &time.;
				scen_dxrx_rxdt_[i]=.;
				scen_dxrx_dxdt_[i]=.;
			end;
		end;
		retain scen_dxrx_rxdt scen_dxrx_dxdt scen_dxrx_dt scen_dxrx_verifytime;
		format scen_dxrx_dt scen_dxrx_rxdt scen_dxrx_dxdt mmddyy10.;
		day=date-mdy(1,1,&minyear.)+1;
		start=max(1,date-mdy(1,1,&minyear.)-730+1);
		end=min(day,&time.);
		if ADdrug and 1<=day<=&time. then scen_dxrx_rxdt_[day]=date;
		if dx and 1<=day<=&time. then scen_dxrx_dxdt_[day]=date;
		if (ADdrug or dx) and scen_dxrx_dt=. then do;
			do i=start to end;
				if scen_dxrx_rxdt=. then scen_dxrx_rxdt=scen_dxrx_rxdt_[i];
				if scen_dxrx_dxdt=. then scen_dxrx_dxdt=scen_dxrx_dxdt_[i];
			end;
			if scen_dxrx_rxdt ne . and scen_dxrx_dxdt ne . then do;
				scen_dxrx_dt=min(scen_dxrx_rxdt,scen_dxrx_dxdt);
				scen_dxrx_verifytime=abs(scen_dxrx_rxdt-scen_dxrx_dxdt);
			end;
			else do;
				scen_dxrx_rxdt=.;
				scen_dxrx_dxdt=.;
			end;
		end;

	* Scenario 2: Two records of AD Diagnosis;
	if first.bene_id then do;
		scen_dx_dt=.;
		scen_dx_verifytime=.;
		scen_dx_dx2dt=.;
	end;
	retain scen_dx_dt scen_dx_verifytime scen_dx_dx2dt;
	format scen_dx_dt scen_dx_dx2dt mmddyy10.;
	if dx=1 then do;
		if scen_dx_dt=. and .<date-scen_dx_dx2dt<=730 then do;
			scen_dx_dt=scen_dx_dx2dt;
			scen_dx_dx2dt=date;
			scen_dx_verifytime=date-scen_dx_dt;
		end;
		else if scen_dx_dt=. then scen_dx_dx2dt=date;
	end;

	* Scenario 3: ADRD diagnosis and any dementia symptoms in any sequence;
	array scen_dxsymp_dxdt_ [&time.] _temporary_;
	array scen_dxsymp_sympdt_ [&time.] _temporary_;
	array scen_dxsymp_desc_ [&time.] $12. _temporary_;
	length scen_dxsymp_desc $12.;
	if first.bene_id then do;
		scen_dxsymp_dt=.;
		scen_dxsymp_desc="";
		scen_dxsymp_sympdt=.;
		scen_dxsymp_dxdt=.;
		scen_dxsymp_verifytime=.;
		do i=1 to &time.;
			scen_dxsymp_dxdt_[i]=.;
			scen_dxsymp_sympdt_[i]=.;
		end;
	end;
	retain scen_dxsymp_dt scen_dxsymp_desc scen_dxsymp_sympdt scen_dxsymp_dxdt scen_dxsymp_verifytime;
	format scen_dxsymp_dt scen_dxsymp_sympdt scen_dxsymp_dxdt mmddyy10.;
	if symptom=1 and 1<=day<=&time. then scen_dxsymp_sympdt_[day]=date;
	if dx=1 and 1<=day<=&time. then scen_dxsymp_dxdt_[day]=date;
	if (dx or symptom) and scen_dxsymp_dt=. then do;
		do i=start to end;
			if scen_dxsymp_sympdt=. then do;
				scen_dxsymp_sympdt=scen_dxsymp_sympdt_[i];
				scen_dxsymp_desc=scen_dxsymp_desc_[i];
			end;
			if scen_dxsymp_dxdt=. then scen_dxsymp_dxdt=scen_dxsymp_dxdt_[i];
		end;
		if scen_dxsymp_dxdt ne . and scen_dxsymp_sympdt ne . then do;
			scen_dxsymp_dt=min(scen_dxsymp_sympdt,scen_dxsymp_dxdt);
			scen_dxsymp_verifytime=abs(scen_dxsymp_dxdt-scen_dxsymp_sympdt);
		end;
		else do;
			scen_dxsymp_dxdt=.;
			scen_dxsymp_sympdt=.;
			scen_dxsymp_desc="";
		end;
	end;
		
	* Scenario 4 - creating different death scenarios for each different incident definition;
	if first.bene_id then do;
		death_dx=.;
		death_dxrx=.;
		death_dxsymp=.;
		death_all=.;
		death_dx_type="     ";
		death_dxrx_type="     ";
		death_dxsymp_type="     ";
		death_all_type="     ";
		death_dx_verifytime=.;
		death_dxrx_verifytime=.;
		death_dxsymp_verifytime=.;
		death_all_verifytime=.;
	end;
	retain death_dx death_dxrx death_dxsymp death_all death_dx_type death_dxrx_type death_dxsymp_type death_all_type
	death_dx_verifytime death_dxrx_verifytime death_dxsymp_verifytime death_all_verifytime;
	format death_dx death_dx death_dxsymp death_all mmddyy10. death_dx_type death_dxrx_type death_dxsymp_type death_all_type $4.;
	if (addrug or dx or symptom) and .<death_date-date<=365 then do;
		if death_all=. then do;
			death_all=date;
			death_all_verifytime=death_date-date;
			if dx then substr(death_all_type,1,1)="x";
			if symptom then substr(death_all_type,2,1)="s";
			if addrug then substr(death_all_type,3,1)="r";
		end;
		if dx and death_dx=. then do;
			death_dx=date;
			death_dx_verifytime=death_date-date;
			if dx then substr(death_dx_type,1,1)="x";
		end;
		if (addrug or dx) and death_dxrx=. then do;
			death_dxrx=date;
			death_dxrx_verifytime=death_date-date;
			if dx then substr(death_dxrx_type,1,1)='x';
			if addrug then substr(death_dxrx_type,3,1)='r';
		end;
		if (symptom or dx) and death_dxsymp=. then do;
			death_dxsymp=date;
			death_dxsymp_verifytime=death_date-date;
			if dx then substr(death_dxsymp_type,1,1)='x';
			if symptom then substr(death_dxsymp_type,2,1)='s';
		end;
	end;
	
	* Creating 4 final scenarios;
	*** Create the final flag, giving priority to the earliest date to make sure that it's the first 
			possible time of AD outcome and also giving priority to shortest verification time. If still no 
			final scenario after scenarios 1-3 then using scenario 4;
	length final_dx_scen final_dxrx_scen final_dxsymp_scen final_all_scen $6.;
	format final_dx_inc final_dxrx_inc final_dxsymp_inc final_all_inc mmddyy10.;
	
	if last.bene_id then do;
		
		keep=1;
		
		final_dx_inc=scen_dx_dt;
		final_dx_verifytime=scen_dx_verifytime;
		if scen_dx_dt ne . then substr(final_dx_scen,2,1)="2";
		if scen_dx_dt=. and death_dx ne . then do;
			final_dx_inc=death_dx;
			final_dx_verifytime=death_dx_verifytime;
			substr(final_dx_scen,4,1)="4";
		end;
		
		final_dxrx_inc=min(scen_dx_dt,scen_dxrx_dt);
		if final_dxrx_inc ne . then do;
			if .<scen_dx_dt<scen_dxrx_dt or scen_dxrx_dt=. then do;
				final_dxrx_verifytime=scen_dx_verifytime;
				substr(final_dxrx_scen,2,1)="2";
			end;
			else if scen_dx_dt=scen_dxrx_dt and scen_dx_dt ne . then do;
				final_dxrx_verifytime=min(scen_dxrx_verifytime,scen_dx_verifytime);
				if final_dxrx_verifytime=scen_dxrx_verifytime then substr(final_dxrx_scen,1,1)='1';
				if final_dxrx_verifytime=scen_dx_verifytime then substr(final_dxrx_scen,2,1)="2";
			end;
			else if .<scen_dxrx_dt<scen_dx_dt or scen_dx_dt=. then do;
				final_dxrx_verifytime=scen_dxrx_verifytime;
				substr(final_dxrx_scen,1,1)='1';
			end;
		end;
		if final_dxrx_inc=. and death_dxrx ne . then do;
			final_dxrx_inc=death_dxrx;
			final_dxrx_verifytime=death_dxrx_verifytime;
			substr(final_dxrx_scen,4,1)='4';
		end;
		
		final_dxsymp_inc=min(scen_dx_dt,scen_dxsymp_dt);
		if final_dxsymp_inc ne . then do;
			if .<scen_dx_dt<scen_dxsymp_dt or scen_dxsymp_dt=. then do;
				final_dxsymp_verifytime=scen_dx_verifytime;
				substr(final_dxsymp_scen,2,1)="2";
			end;
			else if scen_dx_dt=scen_dxsymp_dt and scen_dx_dt ne . then do;
				final_dxsymp_verifytime=min(scen_dxsymp_verifytime,scen_dx_verifytime);
				if final_dxsymp_verifytime=scen_dxsymp_verifytime then substr(final_dxsymp_scen,3,1)='3';
				if final_dxsymp_verifytime=scen_dx_verifytime then substr(final_dxsymp_scen,2,1)="2";
			end;
			else if .<scen_dxsymp_dt<scen_dx_dt or scen_dx_dt=. then do;
				final_dxsymp_verifytime=scen_dxsymp_verifytime;
				substr(final_dxsymp_scen,3,1)='3';
			end;
		end;
		if final_dxsymp_inc=. and death_dxsymp ne . then do;
			final_dxsymp_inc=death_dxsymp;
			final_dxsymp_verifytime=death_dxsymp_verifytime;
			substr(final_dxsymp_scen,4,1)='4';
		end;

		final_all_inc=min(scen_dxrx_dt,scen_dx_dt,scen_dxsymp_dt);
		array scen [*] scen_dxrx_dt scen_dx_dt scen_dxsymp_dt;
		array vdt [*] scen_dxrx_verifytime scen_dx_verifytime scen_dxsymp_verifytime;
		if final_all_inc ne . then do;
			final_all_verifytime=.;
			do i=1 to dim(scen);
				if final_all_inc=scen[i] then final_all_verifytime=min(final_all_verifytime,vdt[i]);
			end;
			do i=1 to dim(scen);
				if final_all_inc=scen[i] and final_all_verifytime=vdt[i] then substr(final_all_scen,i,1)=i;
			end;
		end;
		* if still no final_adscen then using scenario 4;
		if anydigit(final_all_scen)=0 and death_all ne . then do;
			substr(final_all_scen,4,1)='4';
			final_all_inc=death_all;
			final_all_verifytime=death_all_verifytime;
		end;

	end;
		
	final_dx_year=year(final_dx_inc);
	final_dxrx_year=year(final_dxrx_inc);
	final_dxsymp_year=year(final_dxsymp_inc);
	final_all_year=year(final_all_inc);
	
	* counting negatives that don't make sense;
	if final_all_verifytime ne . and final_all_verifytime < 0 then dropall=1;
	if final_dx_verifytime ne . and final_dx_verifytime < 0 then dropdx=1;
	if final_dxrx_verifytime ne . and final_dxrx_verifytime < 0 then dropdxrx=1;
	if final_dxsymp_verifytime ne . and final_dxsymp_verifytime<0 then dropdxsymp=1;
	
run;

proc univariate data=ADRDinc_0216_numscens_long noprint outtable=adrdinc_long_stats; run;
	
proc print data=adrdinc_long_stats; run;
	
data exp.ADRDinc_scens_0216;
	set ADRDinc_0216_numscens_long;
	by bene_id;
	if last.bene_id;
	keep bene_id death_: scen: final: drop:;
run;

proc univariate data=exp.ADRDinc_scens_0216; run;
