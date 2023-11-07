/*********************************************************************************************/
title1 'Annual Well Visit Analysis';

* Author: PF;
* Purpose: Bring together AD Drugs, ADRD Outcomes, AWV claims, specialist info;
* Input: dementia claims, drug claims, specialist visits;
* Output: awv_procedure_2002_&maxyr.;

options compress=yes nocenter ls=150 ps=200 errors=5 errorabend errorcheck=strict mprint merror
	mergenoby=warn varlenchk=warn dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

%include "../../../../51866/PROGRAMS/setup.inc";
%partABlib(types=bsf);
libname awv "../../data/awv/";
libname extracts cvp "&datalib..Claim_Extracts/ProcedureCodes";
libname addrugs "../../data/ad_drug_use";
libname demdx "../../data/dementiadx";
libname exp "../../data/adrd_inc_explore";

%let maxyr=2016;

proc sort data=demdx.adrd_dx_snf_2002_&maxyr. out=snf; by bene_id claim_id; run;
proc sort data=demdx.adrd_dx_op_2002_&maxyr. out=op; by bene_id claim_id; run;
proc sort data=demdx.adrd_dx_ip_2002_&maxyr. out=ip; by bene_id claim_id; run;
proc sort data=demdx.adrd_dx_hha_2002_&maxyr. out=hha; by bene_id claim_id; run;
proc sort data=demdx.adrd_dx_carmrg_2002_&maxyr. out=carmrg; by bene_id claim_id; run;
	
data dxclaims;
	set ip op hha snf carmrg;
	by bene_id claim_id;
	keep bene_id demdx_dt demdx: dxtypes claim_id clm_typ;
run;

proc sort data=exp.demsymptoms_ip_2002_&maxyr. out=symp_ip; by bene_id claim_id; run;
proc sort data=exp.demsymptoms_op_2002_&maxyr. out=symp_op; by bene_id claim_id; run;
proc sort data=exp.demsymptoms_hha_2002_&maxyr. out=symp_hha; by bene_id claim_id; run;
proc sort data=exp.demsymptoms_snf_2002_&maxyr. out=symp_snf; by bene_id claim_id; run;
proc sort data=exp.demsymptoms_carmrg_2002_&maxyr. out=symp_carmrg; by bene_id claim_id; run;
	

data sympclaims;
	set symp_ip (in=a) symp_op (in=b) symp_hha (in=c)
	symp_snf (in=d) symp_carmrg (in=e);
	by bene_id claim_id;
	if a then clm_typ="1";
	if b then clm_typ="3";
	if c then clm_typ="4";
	if d then clm_typ="2";
	if e then clm_typ="5";
	symptom=max(of symptom_ip,symptom_op,symptom_snf,symptom_hha,symptom_carmrg);
	amnesia=max(of amnesia_ip,amnesia_op,amnesia_snf,amnesia_hha,amnesia_carmrg);
	aphasia=max(of aphasia_ip,aphasia_op,aphasia_snf,aphasia_hha,aphasia_carmrg);
	agnosia_apraxia=max(of agnosia_apraxia_ip,agnosia_apraxia_op,agnosia_apraxia_snf,agnosia_apraxia_hha,agnosia_apraxia_carmrg);
	keep bene_id symptom amnesia aphasia agnosia_apraxia claim_id thru_dt clm_typ;
run;

* Merge dx and symp claims by claim_id;
data dxsympclaims;
	merge dxclaims (in=a) sympclaims (in=b);
	by bene_id claim_id;
	dx=a;
	symp=b;
	if thru_dt ne demdx_dt and thru_dt ne . and demdx_dt ne . then diffdt=1;
	date=min(thru_dt,demdx_dt);
	format date mmddyy10.;
run;

proc freq data=dxsympclaims noprint;
	table dx*symp / out=dxsymp;
	table diffdt / out=diffdt missing;
	table clm_typ / out=clmtyp;
run;

proc print data=clmtyp; run;
proc print data=diffdt; run;
proc print data=dxsymp; run;
	
* Add in addrugs and awv;
data awv;
	set awv.preventive_procedures2002_&maxyr.;
	if ip then clm_typ="1";
	if snf then clm_typ="2";
	if op then clm_typ="3";
	if hha then clm_typ="4";
	if car then clm_typ="5";
run;

data analytical;
	format bene_id claim_id date;
	set dxsympclaims (drop=thru_dt demdx_dt diffdt dx symp) addrugs.addrugs_0614 (drop=year rename=srvc_dt=date) awv (drop=car hha ip op snf hcpcs_cd month year);
	by bene_id;
	* Change 0's to blanks;
	array var [*] symptom amnesia aphasia agnosia_apraxia ADdrug donep galan meman
	awv--anypreventive; 
	do i=1 to dim(var);
		if var[i]=0 then var[i]=.;
	end;
	if bene_id ne "";
	month=month(date);
	year=year(date);
	drop i;
	label DRE="Flag for Digital Rectal Exam HCPCS Cd G0102"
				FOTB="Flag for Fecal Occult Blood Test HCPCS Cd 82270 "
				GTT="Flag for Glucose Tolerance Test HCPCS Cd 82951"
				PSA="Flag for Prostate Cancer Screening HCPCS Cd G0103"
				agnosia_apraxia="Flag for ICD9 DX 784.69"
				amnesia="Flag for ICD9 DX 780.93"
				anypreventive="Flag for any preventive HCPCS"
				aphasia="Flag for ICD9 DX 784.3"
				awv="Flag for Annual Wellness Visit HCPCS Cd G0438,G0439"
				colonoscopy="Flag for HCPCS Cd G0105,G0121"
				flushot="Flag for HCPCS Cd 90658"
				flushot_admin="Flag for HCPCS Cd G0008"
				glucose_post="Flag for HCPCS Cd 82950"
				glucose_quant="Flag for HCPCS Cd 82947"
				ippe="Flag for Initial Preventive Physical Exam HCPCS Cd G0344,G0402"
				lipid="Flag for HCPCS Cd 80061"
				lipid_cholesterol="Flag for HCPCS Cd 82465"
				lipid_lipoproteins="Flag for HCPCS Cd 83718"
				lipid_triglycerides="Flag for HCPCS Cd 84478"
				mammography="Flag for HCPCS Cd 77067,G0202,G0204,G0206"
				mammography_add="Flag for HCPCS Cd 77063"
				pelvic_breast="Flag for HCPCS Cd G0101"
				sigmoidoscopy="Flag for HCPCS Cd G0104"
				symptom="Flag for ICD9 DX 784.69,780.93,784.3";
run;

proc sort data=analytical out=awv.analytical&maxyr.; by bene_id claim_id year month date; run;
	
endsas;	
/************** OLD CODE ****************/
/*
* Merge to following sample information: age_beg, sex, race, enrFFS, ptD, enrAB, birth_date, death_date;
data awv.analytical&maxyr.;
	merge analytical (in=a) 
	exp.ffsptd_samp_0416 (in=b keep=bene_id age_beg: sex race_bg enrFFS: ptD: enrAB: birth_date death_date);
	by bene_id;
	if b;
run;

proc contents data=awv.analytical&maxyr.; run;
	
options obs=100;
proc print data=awv.analytical&maxyr.; run;
*/
	
	