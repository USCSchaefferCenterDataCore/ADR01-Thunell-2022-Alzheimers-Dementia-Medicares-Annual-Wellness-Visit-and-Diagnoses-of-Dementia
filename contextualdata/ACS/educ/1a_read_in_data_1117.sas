/*********************************************************************************************/
TITLE1 "ACS SES - Education";

* AUTHOR: Patricia Ferido;

* DATE: 6/28/2019;

* PURPOSE: Read in 5 Year ACS Summary Table S1501 to extract education info;

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

%include "read_in_s1501_1114.mac";
%include "read_in_s1501_1517.mac";
	
%macro loop;
	%do yr=11 %to 17;
		%if &yr<=14 %then %s1501_1114(&yr);
		%if &yr>=15 %then %s1501_1517(&yr);
	%end;
%mend;

%loop;