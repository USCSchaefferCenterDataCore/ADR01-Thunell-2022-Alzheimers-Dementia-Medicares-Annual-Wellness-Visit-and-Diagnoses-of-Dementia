/*********************************************************************************************/
title1 'Geography Data';

* Author: PF;
* Summary:
	•	Input: bene_geo_YYYY.dta, 02-13. zcta2010tozip.dta. acs_educ_65up.dta, ACS_Income.dta
	•	Output: geoses_0613.dta, geoses_0713.dta, geoses_long0713.dta. geoses_0213.dta. geoses_long0213.dta
	•	Merges geo files, makes geographic control variables, and merges in education and income at the zip5 level.;

options compress=yes nocenter ls=150 ps=200 errors=5 errorabend errorcheck=strict 
	mergenoby=warn varlenchk=warn varinitchk=error dkrocond=error msglevel=i;
/*********************************************************************************************/

%include "../../../../../51866/PROGRAMS/setup.inc";

libname geo "&datalib.&clean_data.Geography/";
libname xwalk "&datalib.ContextData/Geography/Crosswalks/zip_to_2010ZCTA/MasterXwalk/";
libname acs "&datalib.ContextData/SAS/";
libname repbase "../../../data/aht/base";
libname zip "&datalib.ContextData/Geography/Crosswalks/";

/******* Bring in base data sets ******/
%let maxyr=2016;

** Geo;
%macro geo;
%do year=2002 %to 2016;
data geo_&year.; set geo.bene_geo_&year. (keep=bene_id fips_state fips_county ssa_county ssa_state statenm countynm zip3 zip5);
	zip=zip5*1;
	drop zip5;
	rename zip=zip5;
run;

proc sort data=geo_&year.; by bene_id; run;
%end;
%mend;

%geo;

** Zip code crosswalk;
data zcta;
	set zip.ziptozcta0719;
	rename zip=zip5;
	*zcta5=fuzz(zcta5ce10*1);
	*drop zcta5ce10;
run;

proc freq data=zcta; table year; run;
	
** Education;
data educ;
	set acs.educ_65up_1117 ;
	if pct_hsgrads=. then delete;
run;

proc sort data=zcta; by zcta5 descending year; run;
proc sort data=educ; by zcta5 descending year; run;

data educ1;
	merge zcta (in=a) educ (in=b);
	by zcta5 descending year;
	* retaining back earliest data;
	if first.zcta5 then do
		pct_hsgrads1=.;
	end;
	retain pct_hsgrads1;
	if pct_hsgrads ne . then pct_hsgrads1=pct_hsgrads;
	drop pct_hsgrads;
	if a and pct_hsgrads1 ne .;
	rename pct_hsgrads1=pct_hsgrads;
run;

proc sort data=educ1; by zip5 year; run;

** Income;
data inc; 
	set acs.medinc_1117;
	rename median_hh_inc=medinc;
	if median_hh_inc=. then delete;
run;

proc sort data=inc; by zcta5 descending year; run;

data inc1;
	merge zcta (in=a) inc (in=b);
	by zcta5 descending year;
	*retaining back earliest data;
	if first.zcta5 then do;
		medinc1=.;
	end;
	retain medinc1;
	if medinc ne . then medinc1=medinc;
	drop medinc;
	if a and medinc1 ne .;
	rename medinc1=medinc;
run;

proc sort data=inc1; by zip5 year; run;

/******** Geography Long 07-14 *******/
data geo_long_0716;
	set geo_2007 (in=a)
	    geo_2008 (in=b)
	    geo_2009 (in=c)
	    geo_2010 (in=d)
	    geo_2011 (in=e)
	    geo_2012 (in=f)
	    geo_2013 (in=g)
	    geo_2014 (in=h)
	    geo_2015 (in=i)
	    geo_2016 (in=j);
	if a then year=2007;
	if b then year=2008;
	if c then year=2009;
	if d then year=2010;
	if e then year=2011;
	if f then year=2012;
	if g then year=2013;
	if h then year=2014;
	if i then year=2015;
	if j then year=2016;
	
  * Census regions
	 		NE 1, MW 2, S 3, W 4, 0 5;
	 	if fips_state="01" then cen4=3; * AL;
	 	if fips_state="02" then cen4=4; * AK;
	 		* AS;
	 	if fips_state="04" then cen4=4; * AZ;
	 	if fips_state="05" then cen4=3; * AR;
	 	if fips_state="06" then cen4=4; * CA;
	 		* CZ;
	 	if fips_state="08" then cen4=4; * CO;
	 	if fips_state="09" then cen4=1; * CT;
	 	if fips_state="10" then cen4=3; * DE;
	 	if fips_state="11" then cen4=3; * DC;
	 	if fips_state="12" then cen4=3; * FL;
	 	if fips_state="13" then cen4=3; * GA;
	 		* GU;
	 	if fips_state="15" then cen4=4; * HI;
	 	if fips_state="16" then cen4=4; * ID;
	 	if fips_state="17" then cen4=2; * IL;
	 	if fips_state="18" then cen4=2; * IN;
	 	if fips_state="19" then cen4=2; * IA;
	 	if fips_state="20" then cen4=2; * KS;
		if fips_state="21" then cen4=3; * KY;   
		if fips_state="22" then cen4=3; * LA;   
		if fips_state="23" then cen4=1; * ME;   
		if fips_state="24" then cen4=3; * MD;   
		if fips_state="25" then cen4=1; * MA;   
		if fips_state="26" then cen4=2; * MI;   
		if fips_state="27" then cen4=2; * MN;   
		if fips_state="28" then cen4=3; * MS;   
		if fips_state="29" then cen4=2; * MO;   
		if fips_state="30" then cen4=4; * MT;   
		if fips_state="31" then cen4=2; * NE;   
		if fips_state="32" then cen4=4; * NV;   
		if fips_state="33" then cen4=1; * NH;   
		if fips_state="34" then cen4=1; * NJ;   
		if fips_state="35" then cen4=4; * NM;   
		if fips_state="36" then cen4=1; * NY;   
		if fips_state="37" then cen4=3; * NC;   
		if fips_state="38" then cen4=2; * ND;   
		if fips_state="39" then cen4=2; * OH;   
		if fips_state="40" then cen4=3; * OK;   
		if fips_state="41" then cen4=4; * OR;   
		if fips_state="42" then cen4=1; * PA;   
			* PR;             
		if fips_state="44" then cen4=1; * RI;   
		if fips_state="45" then cen4=3; * SC;    
		if fips_state="46" then cen4=2; * SD;   
		if fips_state="47" then cen4=3; * TN;   
		if fips_state="48" then cen4=3; * TX;   
		if fips_state="49" then cen4=4; * UT;    
		if fips_state="50" then cen4=1; * VT;   
		if fips_state="51" then cen4=3; * VA;   
			* VI;          
		if fips_state="53" then cen4=4; * WA;   
		if fips_state="54" then cen4=3; * WV;    
		if fips_state="55" then cen4=2; * WI;    
		if fips_state="56" then cen4=4; * WY;    
		if fips_state="60" then cen4=5; * AS;    
		if fips_state="66" then cen4=5; * GU;    
		if fips_state="72" then cen4=5; * PR;    
		if fips_state="78" then cen4=5; * VI;    
		if fips_state="FC" then cen4=5; * UP, FC;
			
run;

* Add education;
proc sort data=geo_long_0716; by zip5 year; run;

* Merge education and income to long;
data repbase.geoses_long0716_zipupdate;
	merge geo_long_0716 (in=a) educ1 (in=b rename=zcta5=educ_zcta5) inc1 (in=c);
	by zip5 year;
	if a;
	educ=b;
	inc=c;
	if zcta5=. then zcta5=educ_zcta5;
	keep bene_id year fips_state fips_county ssa_county ssa_state statenm countynm zip3 zip5 cen4 zcta5 pct_hsgrads medinc educ inc;
run;

** Checks ;
proc contents data=repbase.geoses_long0716_zipupdate; run;

proc print data=repbase.geoses_long0716_zipupdate (obs=200); run;
	
proc freq data=repbase.geoses_long0716_zipupdate;
	table educ inc;
run;

proc freq data=repbase.geoses_long0716_zipupdate noprint;
	table year*educ / out=yr_educ;
	table year*inc / out=yr_inc;
run;
proc contents data=repbase.geoses_long0716_zipupdate; run;
	
proc print data=yr_educ; run;
proc print data=yr_inc; run;

proc univariate data=repbase.geoses_long0716_zipupdate; run;
proc univariate data=repbase.geoses_long0716; run;
proc contents data=repbase.geoses_long0716_zipupdate; run;
	