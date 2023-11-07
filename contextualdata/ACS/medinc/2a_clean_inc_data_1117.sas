/*********************************************************************************************/
TITLE1 "ACS SES - Income";

* AUTHOR: Patricia Ferido;

* DATE: 8/6/2019;

* PURPOSE: Clean S1903 and extract info;

* INPUT: acs_[yr]_5yr_S1903_with_ann.xlsx;

* OUTPUT: acs_s1903_[yrs]_raw, acs_s1903_;

options compress=yes nocenter ls=150 ps=200 errors=5  errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

%macro libs;
	%do yr=11 %to 17;
		libname og&yr "/schaeffer-a/sch-data-library/public-data/ACS-SummaryTables/Original_data/Data/5yr_summary_tables/US-zcta-medinc-S1903/20&yr./";
	%end;
	
	libname harm "/schaeffer-a/sch-data-library/public-data/ACS-SummaryTables/Harmonized/Data/5yr_summary_tables/US-zcta-medinc-S1903/";
%mend;

%libs;

%let contharm=/schaeffer-a/sch-data-library/public-data/ACS-SummaryTables/Harmonized/Contents/5yr_summary_tables/US-zcta-medinc-S1903/;

	data _null_;
		do i=11 to 17;
			call symput("raw"||compress(i),"/schaeffer-a/sch-data-library/public-data/ACS-SummaryTables/Source_data/5yr_summary_tables/US-zcta-medinc-S1903/20"||compress(i));
			call symput("cont"||compress(i),"/schaeffer-a/sch-data-library/public-data/ACS-SummaryTables/Original_data/Contents/5yr_summary_tables/US-zcta-medinc-S1903/20"||compress(i));
		end;
	run;
	
%include "clean_s1903.mac";

%let minyear=11;
%let maxyear=17;

%macro loop;
	%do yr=&minyear %to &maxyear;
		%if &yr<=12 %then %medinc(&yr,geo_id2,HC02_EST_VC02);
		%if 13<=&yr<=16 %then %medinc(&yr,geo_id2,HC02_EST_VC02);
		%if 17<=&yr %then %medinc(&yr,geo_id2,HC03_EST_VC02);
	%end;
%mend;

%loop;

data harm.medinc_&minyear.&maxyear;
	set medinc_&minyear.-medinc_&maxyear.;
	by zcta5 year;
run;

proc print data=harm.medinc_&minyear.&maxyear (obs=100); run;

proc printto print="&contharm.medinc_&minyear.&maxyear..txt" new; run;
proc contents data=harm.medinc_&minyear.&maxyear position; run;
proc printto; run;





