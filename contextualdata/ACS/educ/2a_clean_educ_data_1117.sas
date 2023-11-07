/*********************************************************************************************/
TITLE1 "ACS SES - Education";

* AUTHOR: Patricia Ferido;
* EDITED BY: Khristina Lung;

* DATE: 8/6/2019;
* EDITED: 9/24/2019 (added total population);

* PURPOSE: Clean S1501 and extract education info;

* INPUT: acs_[yr]_5yr_S1501_with_ann.xlsx;

* OUTPUT: acs_s1501_[yrs]_raw, acs_s1501_;

options compress=yes nocenter ls=150 ps=200 errors=5  errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

%macro libs;
	%do yr=11 %to 17;
		libname og&yr "/schaeffer-a/sch-data-library/public-data/ACS-SummaryTables/Original_data/Data/5yr_summary_tables/US-zcta-educ-S1501/20&yr./";
	%end;
	
	libname harm "/schaeffer-a/sch-data-library/public-data/ACS-SummaryTables/Harmonized/Data/5yr_summary_tables/US-zcta-educ-S1501/";
%mend;

%libs;

%let contharm=/schaeffer-a/sch-data-library/public-data/ACS-SummaryTables/Harmonized/Contents/5yr_summary_tables/US-zcta-educ-S1501/;

	data _null_;
		do i=11 to 17;
			call symput("raw"||compress(i),"/schaeffer-a/sch-data-library/public-data/ACS-SummaryTables/Source_data/5yr_summary_tables/US-zcta-educ-S1501/20"||compress(i));
			call symput("cont"||compress(i),"/schaeffer-a/sch-data-library/public-data/ACS-SummaryTables/Original_data/Contents/5yr_summary_tables/US-zcta-educ-S1501/20"||compress(i));
		end;
	run;
	
%include "clean_s1501.mac";

%let minyear=11;
%let maxyear=17;

%macro loop;
	%do yr=&minyear %to &maxyear;
		%if &yr<=14 %then %educ_over65(&yr,geo_id2,HC01_EST_VC01,HC01_EST_VC07,HC01_EST_VC31,HC01_EST_VC16,HC01_EST_VC17,HC01_EST_VC32,HC01_EST_VC33);
		%if &yr>=15 %then %educ_over65(&yr,geo_id2,HC01_EST_VC02,HC01_EST_VC08,HC01_EST_VC32,HC02_EST_VC17,HC02_EST_VC18,HC02_EST_VC33,HC02_EST_VC34);
	%end;
%mend;

%loop;

data harm.educ_&minyear.&maxyear;
	set educ&minyear.-educ&maxyear.;
	by zcta5 year;
run;

proc print data=harm.educ_&minyear.&maxyear (obs=100); run;

proc printto print="&contharm.educ_&minyear.&maxyear..txt" new; run;
proc contents data=harm.educ_&minyear.&maxyear position; run;
proc printto; run;





