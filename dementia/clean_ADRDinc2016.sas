/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: 	Cleaning up verified ADRD data set;
* Input: exp.ADRDinc_scens_0216;
* Output: exp.ADRD_verified_0216;

options compress=yes nocenter ls=150 ps=200 errors=5 errorabend errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

%include "../../../../51866/PROGRAMS/setup.inc";
%include "&maclib.listvars.mac";
libname exp "../../data/adrd_inc_explore";
libname demdx "../../data/dementiadx";
libname addrugs "../../data/ad_drug_use";
libname bene "../../../../51866/DATA/Clean_Data/BeneStatus";

proc contents data=exp.ADRDinc_scens_0216; run;

proc freq data=exp.ADRDinc_scens_0216;
	table final_dx_scen final_dxrx_scen final_dxsymp_scen final_all_scen
				death_dx_type death_dxrx_type death_dxsymp_type death_all_type;
run;

data exp.ADRDinc_verified0216;
	set exp.ADRDinc_scens_0216;
	
	format dx_scen_inc dxrx_scen_inc dxsymp_scen_inc all_scen_inc 
				 dx_scen_vdt dxrx_scen_vdt dxsymp_scen_vdt all_scen_vdt mmddyy10.
				 dx_scen_inctype dxrx_scen_inctype dxsymp_scen_inctype all_scen_inctype
				 dx_scen_vtype dxrx_scen_vtype dxsymp_scen_vtype all_scen_vtype $4.;
	
	* DX only;		
	if dropdx ne 1 then do;	
		dx_scen_inc=final_dx_inc; 
		dx_scen_vtime=final_dx_verifytime;
		if compress(final_dx_scen)="2" then do;
			substr(dx_scen_inctype,1,1)="1";
			dx_scen_vdt=scen_dx_dx2dt;
			substr(dx_scen_vtype,1,1)="1";
		end;
		else if find(final_dx_scen,"4") then do;
			substr(dx_scen_inctype,1,1)="1";
			dx_scen_vdt=death_date;
			substr(dx_scen_vtype,4,1)="4";
		end;
	end;
	
	* Add RX;
	if dropdxrx ne 1 then do;
		dxrx_scen_inc=final_dxrx_inc;
		dxrx_scen_vtime=final_dxrx_verifytime;
		if final_dxrx_scen="12" then do; * If both scenarios apply, then the dx date always comes first in the dxrx scenario because if the rx came first, it would only the dxrx scenario;
			dxrx_scen_inctype="1";
			dxrx_scen_vdt=scen_dxrx_rxdt;
			dxrx_scen_vtype="12";
		end;
		else if find(final_dxrx_scen,"2") then do;
			substr(dxrx_scen_inctype,1,1)="1";
			dxrx_scen_vdt=scen_dx_dx2dt;
			substr(dxrx_scen_vtype,1,1)="1";
		end;
		else if find(final_dxrx_scen,"1") then do;
			if scen_dxrx_rxdt<scen_dxrx_dxdt then do;
				substr(dxrx_scen_inctype,2,1)="2";
				dxrx_scen_vdt=scen_dxrx_dxdt;
				substr(dxrx_scen_vtype,1,1)="1";
			end;
			else if scen_dxrx_rxdt>scen_dxrx_dxdt then do;
				substr(dxrx_scen_inctype,1,1)="1";
				dxrx_scen_vdt=scen_dxrx_rxdt;
				substr(dxrx_scen_vtype,2,1)="2";
			end;
			else if scen_dxrx_rxdt=scen_dxrx_dxdt then do;
				dxrx_scen_inctype="12";
				dxrx_scen_vdt=scen_dxrx_rxdt;
				dxrx_scen_vtype="12";
			end;
		end;
		else if find(final_dxrx_scen,"4") then do;
			dxrx_scen_vdt=death_date;
			substr(dxrx_scen_vtype,4,1)="4";
			if death_dxrx_type="x r" then dxrx_scen_inctype="12";
			else if find(death_dxrx_type,"x") then substr(dxrx_scen_inctype,1,1)="1";
			else if find(death_dxrx_type,"r") then substr(dxrx_scen_inctype,2,1)="2";
		end;
	end;
	
	* Add symp;
	if dropdxsymp ne 1 then do;
		dxsymp_scen_inc=final_dxsymp_inc;
		dxsymp_scen_vtime=final_dxsymp_verifytime;
		if final_dxsymp_scen=" 23" then do;
			dxsymp_scen_inctype="1";
			dxsymp_scen_vdt=scen_dxsymp_sympdt;
			dxsymp_scen_vtype="1 3";
		end;
		else if find(final_dxsymp_scen,"2") then do;
			substr(dxsymp_scen_inctype,1,1)="1";
			dxsymp_scen_vdt=scen_dx_dx2dt;
			substr(dxsymp_scen_vtype,1,1)="1";
		end;
		else if find(final_dxsymp_scen,"3") then do;
			if scen_dxsymp_sympdt<scen_dxsymp_dxdt then do;
				substr(dxsymp_scen_inctype,3,1)="3";
				dxsymp_scen_vdt=scen_dxsymp_dxdt;
				substr(dxsymp_scen_vtype,1,1)="1";
			end;
			else if scen_dxsymp_sympdt>scen_dxsymp_dxdt then do;
				substr(dxsymp_scen_inctype,1,1)="1";
				dxsymp_scen_vdt=scen_dxsymp_sympdt;
				substr(dxsymp_scen_vtype,3,1)="3";
			end;
			else if scen_dxsymp_sympdt=scen_dxsymp_dxdt then do;
				dxsymp_scen_inctype="1 3";
				dxsymp_scen_vdt=scen_dxsymp_sympdt;
				dxsymp_scen_vtype="1 3";
			end;
		end;
		else if find(final_dxsymp_scen,"4") then do;
			dxsymp_scen_vdt=death_date;
			substr(dxsymp_scen_vtype,4,1)="4";
			if death_dxsymp_type=" sr" then dxsymp_scen_inctype="1 3";
			else if find(death_dxsymp_type,"x") then substr(dxsymp_scen_inctype,1,1)="1";
			else if find(death_dxsymp_type,"s") then substr(dxsymp_scen_inctype,3,1)="3";
		end;
	end;
	
	* Add all;
	if dropall ne 1 then do;
		all_scen_inc=final_all_inc;
		all_scen_vtime=final_all_verifytime;
		if final_all_scen="123" then do;
			all_scen_inctype="1";
			all_scen_vdt=scen_dx_dx2dt;
			all_scen_vtype="123";
		end;
		else if final_all_scen=" 23" then do;
			all_scen_inctype="1";
			all_scen_vdt=scen_dx_dx2dt;
			all_scen_vtype="1 3";
		end;
		else if final_all_scen="12" then do;
			all_scen_inctype="1";
			all_scen_vdt=scen_dx_dx2dt;
			all_scen_vtype="12";
		end;
		else if final_all_scen="1 3" then do;
			if scen_dxsymp_sympdt<scen_dxsymp_dxdt then do;
				all_scen_inctype="1 3";
				all_scen_vdt=scen_dxsymp_dxdt;
				all_scen_vtype=" 2";
			end;
			else if scen_dxsymp_sympdt>scen_dxsymp_dxdt then do;
				all_scen_inctype=" 2";
				all_scen_vdt=scen_dxsymp_sympdt;
				all_scen_vtype="1 3";
			end;
			else if scen_dxsymp_sympdt=scen_dxsymp_dxdt then do;
				all_scen_inctype="123";
				all_scen_vdt=scen_dxsymp_dxdt;
				all_scen_vtype="123";
			end;
		end;
		else if find(final_all_scen,"1") then do;
			if scen_dxrx_rxdt<scen_dxrx_dxdt then do;
				substr(all_scen_inctype,2,1)="2";
				all_scen_vdt=scen_dxrx_dxdt;
				substr(all_scen_vtype,1,1)="1";
			end;
			else if scen_dxrx_rxdt>scen_dxrx_dxdt then do;
				substr(all_scen_inctype,1,1)="1";
				all_scen_vdt=scen_dxrx_rxdt;
				substr(all_scen_vtype,2,1)="2";
			end;
			else if scen_dxrx_rxdt=scen_dxrx_dxdt then do;
				all_scen_inctype="12";
				all_scen_vdt=scen_dxrx_rxdt;
				all_scen_vtype="12";
			end;
		end;
		else if find(final_all_scen,"3") then do;
			if scen_dxsymp_sympdt<scen_dxsymp_dxdt then do;
				substr(all_scen_inctype,3,1)="3";
				all_scen_vdt=scen_dxsymp_dxdt;
				substr(all_scen_vtype,1,1)="1";
			end;
			else if scen_dxsymp_sympdt>scen_dxsymp_dxdt then do;
				substr(all_scen_inctype,1,1)="1";
				all_scen_vdt=scen_dxsymp_sympdt;
				substr(all_scen_vtype,3,1)="3";
			end;
			else if scen_dxsymp_sympdt=scen_dxsymp_dxdt then do;
				all_scen_inctype="1 3";
				all_scen_vdt=scen_dxsymp_sympdt;
				all_scen_vtype="1 3";
			end;
		end;
		else if find(final_all_scen,"2") then do;
			substr(all_scen_inctype,1,1)="1";
			all_scen_vdt=scen_dx_dx2dt;
			substr(all_scen_vtype,1,1)="1";
		end;		
		else if find(final_all_scen,"4") then do;
			all_scen_vdt=death_date;
			substr(all_scen_vtype,4,1)="4";
			if death_all_type=" sr" then all_scen_inctype="1 3";
			else if death_all_type="x r" then all_scen_inctype=" 23";
			else if death_all_type="xsr" then all_scen_inctype="123";
			else if death_all_type="xs" then all_scen_inctype="12"; 
			else if find(death_all_type,"x") then substr(all_scen_inctype,1,1)="1";
			else if find(death_all_type,"s") then substr(all_scen_inctype,3,1)="3";
			else if find(death_all_type,"r") then substr(all_scen_inctype,2,1)="2";
		end;		
	end;
	
	label 
	dx_scen_inc="ADRD incident date for scenario using only dx"
	dx_scen_vdt="Date of verification for scenario using only dx"
	dx_scen_vtime="Verification time for scenario using only dx"
	dx_scen_inctype="1-incident date is ADRD dx, 2-incident date is drug use, 3-incident date is dem symptom"
	dx_scen_vtype="1-verification date is ADRD dx, 2-verification date is drug use, 3-verification date is dem symptom, 4-verified by death"
	dxrx_scen_inc="ADRD incident date for scenario using dx and drugs"
	dxrx_scen_vdt="Date of verification for scenario using dx and drugs"
	dxrx_scen_vtime="Verification time for scenario using dx and drugs"
	dxrx_scen_inctype="1-incident date is ADRD dx, 2-incident date is drug use, 3-incident date is dem symptom"
	dxrx_scen_vtype="1-verification date is ADRD dx, 2-verification date is drug use, 3-verification date is dem symptom, 4-verified by death"
	dxsymp_scen_inc="ADRD incident date for scenario using dx and symptoms"
	dxsymp_scen_vdt="Date of verification for scenario using dx and symptoms"
	dxsymp_scen_vtime="Verification time for scenario using dx and symptoms"
	dxsymp_scen_inctype="1-incident date is ADRD dx, 2-incident date is drug use, 3-incident date is dem symptom"
	dxsymp_scen_vtype="1-verification date is ADRD dx, 2-verification date is drug use, 3-verification date is dem symptom, 4-verified by death"
	all_scen_inc="ADRD incident date for scenario using dx, drugs and symptoms"
	all_scen_vdt="Date of verification for scenario using dx, drugs and symptoms"
	all_scen_vtime="Verification time for scenario using dx, drugs and symptoms"
	all_scen_inctype="1-incident date is ADRD dx, 2-incident date is drug use, 3-incident date is dem symptom"
	all_scen_vtype="1-verification date is ADRD dx, 2-verification date is drug use, 3-verification date is dem symptom, 4-verified by death";	

	keep bene_id death_date all_scen: dx_scen: dxrx_scen: dxsymp_scen:;
run;

/************* Checks**********/
proc freq data=exp.ADRDinc_verified0216 noprint;
	table dx_scen_inctype*dx_scen_vtype / out=dx_scen_freq;
	table dxrx_scen_inctype*dxrx_scen_vtype / out=dxrx_scen_freq;
	table dxsymp_scen_inctype*dxsymp_scen_vtype / out=dxsymp_scen_freq;
	table all_scen_inctype*all_scen_vtype / out=all_scen_freq;
run;

proc print data=dx_scen_freq;
proc print data=dxrx_scen_freq;
proc print data=dxsymp_scen_freq;
proc print data=all_scen_freq; run;
	
proc univariate data=exp.ADRDinc_verified0216 noprint outtable=check_univariate; 
	var dx_scen_inc dx_scen_vdt dx_scen_vtime dxrx_scen_inc dxrx_scen_vdt dxrx_scen_vtime dxsymp_scen_inc dxsymp_scen_vdt dxsymp_scen_vtime all_scen_inc all_scen_vdt all_scen_vtime;
run;

proc print data=check_univariate; run;

proc printto print="ADRDinc_verified0216_contents.txt" new;
proc contents data=exp.ADRDinc_verified0216; run;
proc printto; run;

