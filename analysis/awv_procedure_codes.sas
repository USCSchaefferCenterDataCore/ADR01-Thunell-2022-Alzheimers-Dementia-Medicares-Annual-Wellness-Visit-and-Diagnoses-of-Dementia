/*********************************************************************************************/
title1 'Annual Well Visit Analysis';

* Author: PF;
* Purpose: Pull Procedure Codes for Annual Well Visit;
* Input: [ctyp]_hcpcs&year;
* Output: awv_procedure_2002_&maxyr.;

options compress=yes nocenter ls=150 ps=200 errors=5 errorabend errorcheck=strict mprint merror
	mergenoby=warn varlenchk=warn dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

%include "../../../../51866/PROGRAMS/setup.inc";
%partABlib(types=bsf);
libname awv "../../data/awv/";
libname extracts cvp ("&datalib.Claim_Extracts/ProcedureCodes");
libname test ("/disk/aging/medicare/data/20pct/ip/2013");
libname exp "../../data/adrd_inc_explore";

%let awv="G0438","G0439";
%let ippe="G0344","G0402";
%let lipid="80061";
%let lipid_cholesterol="82465";
%let lipid_lipoproteins="83718";
%let lipid_triglycerides="84478";
%let mammography="77067","G0202","G0204","G0206";
%let mammography_add="77063";
%let pelvic_breast="G0101";
%let FOTB="82270";
%let sigmoidoscopy="G0104";
%let colonoscopy="G0105","G0121";
%let PSA="G0103";
%let DRE="G0102";
%let flushot_admin="G0008";
%let flushot="90658";
%let glucose_quant="82947";
%let glucose_post="82950";
%let GTT="82951";

%let maxyr=2016;

%macro procedure(ctyp,byear,eyear,pre06datev=,post06datev=);
			
			data awv.&ctyp._procedures&byear._&eyear;
				set 
					%do year=2002 %to 2005;
						extracts.&ctyp._hcpcs&year (where=(bene_id ne "" and date ne . and hcpcs_cd ne "") keep=bene_id year &pre06datev hcpcs_cd claim_id rename=&pre06datev=date)
					%end;
					%do year=2006 %to &maxyr;
						extracts.&ctyp._hcpcs&year (where=(bene_id ne "" and date ne . and hcpcs_cd ne "") keep=bene_id year &post06datev hcpcs_cd claim_id rename=&post06datev=date)
					%end;;
				by bene_id claim_id;
				if first.claim_id then do;
					awv=0;
					ippe=0;
					lipid=0;
					lipid_cholesterol=0;
					lipid_lipoproteins=0;
					lipid_triglycerides=0;
					mammography=0;
					mammography_add=0;
					pelvic_breast=0;
					FOTB=0;
					sigmoidoscopy=0;
					colonoscopy=0;
					PSA=0;
					DRE=0;
					flushot_admin=0;
					flushot=0;
					glucose_quant=0;
					glucose_post=0;
					GTT=0;
					anypreventive=0;
				end;
				retain awv--anypreventive;
				if hcpcs_cd in(&awv) then awv=1;
				if hcpcs_cd in(&ippe) then ippe=1;
				if hcpcs_cd in(&lipid) then lipid=1;
				if hcpcs_cd in(&lipid_cholesterol) then lipid_cholesterol=1;
				if hcpcs_cd in(&lipid_lipoproteins) then lipid_lipoproteins=1;
				if hcpcs_cd in(&lipid_triglycerides) then lipid_triglycerides=1;
				if hcpcs_cd in(&mammography) then mammography=1;
				if hcpcs_cd in(&mammography_add) then mammography_add=1;
				if hcpcs_cd in(&pelvic_breast) then pelvic_breast=1;
				if hcpcs_cd in(&FOTB) then FOTB=1;
				if hcpcs_cd in(&sigmoidoscopy) then sigmoidoscopy=1;
				if hcpcs_cd in(&colonoscopy) then colonoscopy=1;
				if hcpcs_cd in(&PSA) then PSA=1;
				if hcpcs_cd in(&DRE) then DRE=1;
				if hcpcs_cd in(&flushot_admin) then flushot_admin=1;
				if hcpcs_cd in(&flushot) then flushot=1;
				if hcpcs_cd in(&glucose_quant) then glucose_quant=1;
				if hcpcs_cd in(&glucose_post) then glucose_post=1;
				if hcpcs_cd in(&GTT) then GTT=1;
				if hcpcs_cd in(&awv,&ippe,&lipid,&lipid_cholesterol,&lipid_lipoproteins,&lipid_triglycerides,&mammography,&mammography_add,&pelvic_breast,&FOTB,&sigmoidoscopy,
				&colonoscopy,&PSA,&DRE,&flushot_admin,&flushot,&glucose_quant,&glucose_post,&GTT) then anypreventive=1;
				month=month(date);
				if anypreventive;
				if last.claim_id;
			run;			
			
%mend;

%procedure(car,2002,&maxyr.,pre06datev=expnsdt1,post06datev=expnsdt1);
%procedure(hha,2002,&maxyr.,pre06datev=rev_dt,post06datev=thru_dt);
%procedure(ip,2002,&maxyr.,pre06datev=rev_dt,post06datev=thru_dt);
%procedure(op,2002,&maxyr.,pre06datev=rev_dt,post06datev=thru_dt);
%procedure(snf,2002,&maxyr.,pre06datev=rev_dt,post06datev=thru_dt);

options obs=100;
proc print data=awv.car_procedures2002_&maxyr.; run;
proc print data=awv.hha_procedures2002_&maxyr.; run;
proc print data=awv.ip_procedures2002_&maxyr.; run;
proc print data=awv.op_procedures2002_&maxyr.; run;
proc print data=awv.snf_procedures2002_&maxyr.; run;
options obs=max;

*** Merge all together;
data awv.preventive_procedures2002_&maxyr.;
	set awv.car_procedures2002_&maxyr. (in=a)
				awv.hha_procedures2002_&maxyr. (in=b)
				awv.ip_procedures2002_&maxyr. (in=c)
				awv.op_procedures2002_&maxyr. (in=d)
				awv.snf_procedures2002_&maxyr. (in=e);
	by bene_id;
	if bene_id ne "";
	if a then car=1;
	if b then hha=1;
	if c then ip=1;
	if d then op=1;
	if e then snf=1;
run;

data procedures_samp;
	merge awv.preventive_procedures2002_&maxyr. (in=a) exp.ffs_samp_0414 (in=b);
	by bene_id;
	
	array insamp [2008:&maxyr.] insamp2008-insamp&maxyr.;
	
	if year(date)>=2008 then do;
		if insamp[year(date)] then output;
	end;
run;

proc means data=awv.preventive_procedures2002_&maxyr. noprint;
	class year month;
	output out=preventive_monthcount (drop=_type_ _freq_) sum(awv--anypreventive)=;
run;

proc means data=procedures_samp noprint;
	class year month;
	output out=preventive_monthcount_samp (drop=_type_ _freq_) sum(awv--anypreventive)=;
run;

***** AWV procedures per month;
ods excel file="./output/preventive_count2016.xlsx";
proc print data=preventive_monthcount; run;
proc print data=preventive_monthcount_samp; run;
ods excel close;

endsas;

proc contents data=awv.preventive_procedures2002_&maxyr.; run;

options obs=50;
proc print data=awv.preventive_procedures2002_&maxyr.; run;
proc print data=awv.preventive_procedures2002_&maxyr.;
	where lipid=1;
	var lipid:;
run;



