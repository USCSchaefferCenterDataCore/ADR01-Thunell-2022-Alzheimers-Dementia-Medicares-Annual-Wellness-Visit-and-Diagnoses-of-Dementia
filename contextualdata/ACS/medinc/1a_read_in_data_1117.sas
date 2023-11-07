/*********************************************************************************************/
TITLE1 "ACS SES - Education";

* AUTHOR: Patricia Ferido;

* DATE: 6/28/2019;

* PURPOSE: Read in 5 Year ACS Summary Table S1903 to extract education info;

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
	
%include "read_in_s1903_1112.mac";
%include "read_in_s1903_1316.mac";
%include "read_in_s1903_1717.mac";

%macro loop;
	%do yr=11 %to 17;
		%if &yr<=12 %then %s1903_1112(&yr);
		%if 13<=&yr<=16 %then %s1903_1316(&yr);
		%if &yr>=17 %then %s1903_1717(&yr);
	%end;
%mend;

%loop;