/*********************************************************************************************/
TITLE1 "Zip to ZCTA Crosswalk";

* AUTHOR: Patricia Ferido;

* DATE: 10/21/2019;

* PURPOSE: Import shapefiles from Census 2007-2009, import SAS zip code files 2007-2009, merge;

options compress=yes nocenter ls=150 ps=200 errors=5  errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

libname shp07 "./shp2007";
libname shp08 "./shp2008";
libname shp09 "./shp2009";
libname zip "./sas_zip_codes/";
libname data "./data/";
libname xwlk "/schaeffer-a/sch-data-library/public-data/ContextualData/Sas";


* Import shape files;
proc mapimport contents out=zcta07 datafile="./shp2007/fe_2007_us_zcta500.shp"; run;
proc mapimport contents out=zcta08 datafile="./shp2008/tl_2008_us_zcta500.shp"; run;
proc mapimport contents out=zcta09 datafile="./shp2009/tl_2009_us_zcta5.shp"; run;
/*
* Import SAS zip codes;
proc cimport infile="./sas_zip_codes/zipcode_oct07/zipcode_oct07.cpt" library=zip; run;
proc cimport infile="./sas_zip_codes/zipcode_oct08/zipcode_oct08.cpt" library=zip; run;
proc cimport infile="./sas_zip_codes/zipcode_oct09/zipcode_oct09.cpt" library=zip; run;

proc datasets lib=zip;
	change zipcode_07q4_unique=zip2007
				 zipcode_08q4_unique=zip2008
				 zipcode_09q4_unique=zip2009;
run;
*/
* Contents;
proc contents data=zcta07; run;
proc contents data=zcta08; run;
proc contents data=zcta09; run;
proc contents data=zip.zip2007; run;
proc contents data=zip.zip2008; run;
proc contents data=zip.zip2009; run;

* Merge shape files to zip;
data zcta07_1;
	set zcta07;
	zcta5ce00=compress(zcta5ce00,,'kd');
	zip=input(zcta5ce00,best.);
	format zip z5.;
run;

data zcta08_1;
	set zcta08;
	zip=input(zcta5ce00,best.);
run;

data zcta09_1;
	set zcta09;
	zip=input(zcta5ce,best.);
run;

proc sort data=zcta07_1; by zip; run;
proc sort data=zcta08_1; by zip; run;
proc sort data=zcta09_1; by zip; run;
	
data zcta07_2;
	set zcta07_1;
	by zip;
	if first.zip;
run;

data zcta08_2;
	set zcta08_1;
	by zip;
	if first.zip;
run;

data zcta09_2;
	set zcta09_1;
	by zip;
	if first.zip;
run;

proc sort data=zip.zip2007 out=zip07; by zip; run;
proc sort data=zip.zip2008 out=zip08; by zip; run;
proc sort data=zip.zip2009 out=zip09; by zip; run;

data zip_zcta_all07 zip_zcta_match07 zip_nonmatch07 zcta_nonmatch07;
	merge zip07 (in=a) zcta07_2 (in=b);
	by zip;
	zp=a;
	zc=b;
	output zip_zcta_all07;
	if a and not b then output zip_nonmatch07;
	else if b and not a then output zcta_nonmatch07;
	else output zip_zcta_match07;
run;

data zip_zcta_all08 zip_zcta_match08 zip_nonmatch08 zcta_nonmatch08;
	merge zip08 (in=a) zcta08_2 (in=b);
	by zip;
	zp=a;
	zc=b;
	output zip_zcta_all08;
	if a and not b then output zip_nonmatch08;
	else if b and not a then output zcta_nonmatch08;
	else output zip_zcta_match08;
run;

data zip_zcta_all09 zip_zcta_match09 zip_nonmatch09 zcta_nonmatch09;
	merge zip09 (in=a) zcta09_2 (in=b);
	by zip;
	zp=a;
	zc=b;
	output zip_zcta_all09;
	if a and not b then output zip_nonmatch09;
	else if b and not a then output zcta_nonmatch09;
	else output zip_zcta_match09;
run;

proc freq data=zip_zcta_all07 noprint;
	table zp*zc / out=freq_match07;
run;

proc freq data=zip_zcta_all08 noprint;
	table zp*zc / out=freq_match08;
run;

proc freq data=zip_zcta_all09 noprint;
	table zp*zc / out=freq_match09;
run;

proc print data=freq_match07; run;
proc print data=freq_match08; run;
proc print data=freq_match09; run;

* Merge nonmatches to centroid;
proc ginside data=zip_nonmatch07 map=zcta07_1 out=zip_nonmatch07
	includeborder;
	id zcta5ce00;
run;

data zip_nonmatch07_1;
	set zip_nonmatch07;
	if zcta5ce00 ne "" then match=1;
	else match=0;
run;

proc ginside data=zip_nonmatch08 map=zcta08_1 out=zip_nonmatch08
	includeborder;
	id zcta5ce00;
run;

data zip_nonmatch08_1;
	set zip_nonmatch08;
	if zcta5ce00 ne "" then match=1;
	else match=0;
run;

proc ginside data=zip_nonmatch09 map=zcta09_1 out=zip_nonmatch09
	includeborder;
	id zcta5ce;
run;

data zip_nonmatch09_1;
	set zip_nonmatch09;
	if zcta5ce ne "" then match=1;
	else match=0;
run;

proc freq data=zip_nonmatch07_1;
	table match;
run;

proc freq data=zip_nonmatch08_1;
	table match;
run;

proc freq data=zip_nonmatch09_1;
	table match;
run;

proc sort data=zip_nonmatch07_1; by zip; run;
proc sort data=zip_nonmatch08_1; by zip; run;
proc sort data=zip_nonmatch09_1; by zip; run;
	
data zip_nonmatch07_2;
	set zip_nonmatch07_1;
	by zip;
	if first.zip;
run;

data zip_nonmatch08_2;
	set zip_nonmatch08_1;
	by zip;
	if first.zip;
run;

data zip_nonmatch09_2;
	set zip_nonmatch09_1;
	by zip;
	if first.zip;
run;

data data.ziptozcta07;
	set zip_zcta_match07 (in=a) zip_nonmatch07_2 (in=b);
	by zip;
	year=2007;
	format join_type $40.;
	if b then join_type="Spatial join to ZCTA";
	if a then join_type="Zip Matches ZCTA";
	if zcta5ce00=. then do;
		join_type="populated ZCTA, missing zip";
		zcta5ce00=zip;
	end;
	zcta5=zcta5ce00;
	keep zip zcta5ce00 zcta5 city county countynm statecode year join_type;
run;

data data.ziptozcta08;
	set zip_zcta_match08 (in=a) zip_nonmatch08_2 (in=b);
	by zip;
	year=2008;
	format join_type $40.;
	if b then join_type="Spatial join to ZCTA";
	if a then join_type="Zip Matches ZCTA";
	if zcta5ce00=. then do;
		join_type="populated ZCTA, missing zip";
		zcta5ce00=zip;
	end;
	zcta5=zcta5ce00;
	keep zip zcta5ce00 zcta5 city county countynm statecode year join_type;
run;

data data.ziptozcta09;
	set zip_zcta_match09 (in=a) zip_nonmatch09_2 (in=b);
	by zip;
	year=2009;
	format join_type $40.;
	if b then join_type="Spatial join to ZCTA";
	if a then join_type="Zip Matches ZCTA";
	if zcta5ce=. then do;
		join_type="populated ZCTA, missing zip";
		zcta5ce=zip;
	end;
	zcta5=zcta5ce;
	keep zip zcta5ce zcta5 city county countynm statecode year join_type;
run;
	
proc freq data=data.ziptozcta07;
	table join_type;
run;

proc freq data=data.ziptozcta08;
	table join_type;
run;

proc freq data=data.ziptozcta09;
	table join_type;
run;

* Read in UDS 2010 to 2017 mapper and set on top of each other;
		data uds2010;
			infile "./uds_mapper/zip_to_zcta_2010.csv" lrecl=32767 dsd missover dlm="2c"x firstobs=2;
			informat
				zip best.
				join_type $40.
				city $35.
				statecode $2.
				zcta5 $5.;
			format
				zip best.
				join_type $40.
				city $35.
				statecode $2.
				zcta5 $5.;
			input
				zip 
				join_type $
				city $
				statecode $
				zcta5 $;
			year=2010;
		run;
		
		data uds2011;
			infile "./uds_mapper/zip_to_zcta_2011.csv" lrecl=32767 dsd missover dlm="2c"x firstobs=2;
			informat
				zip best.
				join_type $40.
				city $35.
				statecode $2.
				zcta5 $5.;
			format
				zip best.
				join_type $40.
				city $35.
				statecode $2.
				zcta5 $5.;
			input
				zip 
				join_type $
				city $
				statecode $
				zcta5 $;
			year=2011;
		run;			
		
		data uds2012;
			infile "./uds_mapper/zip_to_zcta_2012.csv" lrecl=32767 dsd missover dlm="2c"x firstobs=2;
			informat
				zip best.
				join_type $40.
				city $35.
				state $40.
				statecode $2.
				zcta5 $5.;
			format
				zip best.
				join_type $40.
				city $35.
				state $40.
				statecode $2.
				zcta5 $5.;
			input
				zip 
				join_type $
				city $
				state $
				statecode $
				zcta5 $;
			year=2012;
		run;
		
		data uds2013;
			infile "./uds_mapper/zip_to_zcta_2013.csv" lrecl=32767 dsd missover dlm="2c"x firstobs=2;
			informat
				zip best.
				join_type $40.
				city $35.
				state $40.
				statecode $2.
				zcta5 $5.;
			format
				zip best.
				join_type $40.
				city $35.
				state $40.
				statecode $2.
				zcta5 $5.;
			input
				zip 
				join_type $
				city $
				state $
				statecode $
				zcta5 $;
			year=2013;
		run;
		
		data uds2014;
			infile "./uds_mapper/zip_to_zcta_2014.csv" lrecl=32767 dsd missover dlm="2c"x firstobs=2;
			informat
				objectid best.
				zip best.
				join_type $40.
				city $35.
				statecode $2.
				enc_zip best.
				zcta5 $5.;
			format
				objectid best.
				zip best.
				join_type $40.
				city $35.
				statecode $2.
				enc_zip best.
				zcta5 $5.;
			input
				objectid 
				zip 
				join_type $
				city $
				statecode $
				enc_zip 
				zcta5 $;
			year=2014;
		run;
		
		data uds2015;
			infile "./uds_mapper/zip_to_zcta_2015.csv" lrecl=32767 dsd missover dlm="2c"x firstobs=2;
			informat
				zip best.
				city $35.
				statecode $2.
				join_type $40.
				zcta5 $5.;
			format
				zip best.
				city $35.
				statecode $2.
				join_type $40.
				zcta5 $5.;
			input
				zip 
				city $
				statecode $
				join_type $
				zcta5 $ ;
			year=2015;
		run;
		
		data uds2016;
			infile "./uds_mapper/zip_to_zcta_2016.csv" lrecl=32767 dsd missover dlm="2c"x firstobs=2;
			informat
				zip best.
				reportingyr best.
				join_type $40.
				city $35.
				statename $40.
				statecode $2.
				enc_zip best.
				zcta5 $5.;
			format
				zip best.
				reportingyr best.
				join_type $40.
				city $35.
				statename $40.
				statecode $2.
				enc_zip best.
				zcta5 $5.;
			input
				zip 
				reportingyr 
				join_type $
				city $
				statename $
				statecode $
				enc_zip 
				zcta5 $;
			year=2016;
		run;
		
		data uds2017;
			infile "./uds_mapper/zip_to_zcta_2017.csv" lrecl=32767 dsd missover dlm="2c"x firstobs=2;
			informat
				zip best.
				city $35.
				statecode $2.
				ziptype $40.
				zcta5 $5.
				join_type $40.;
			format
				zip best.
				city $35.
				statecode $2.
				ziptype $40.
				zcta5 $5.
				join_type $40.;
			input
				zip 
				city $
				statecode $
				ziptype $
				zcta5 $
				join_type $;
			year=2017;
		run;
		
		data uds2018;
			infile "./uds_mapper/zip_to_zcta_2018.csv" lrecl=32767 dsd missover dlm="2c"x firstobs=2;
			informat
				zip best.
				city $35.
				statecode $2.
				ziptype $40.
				zcta5 $5.
				join_type $40.;
			format
				zip best.
				city $35.
				statecode $2.
				ziptype $40.
				zcta5 $5.
				join_type $40.;
			input
				zip 
				city $
				statecode $
				ziptype $
				zcta5 $
				join_type $;
			year=2018;
		run;
		
		data uds2019;
			infile "./uds_mapper/zip_to_zcta_2019.csv" lrecl=32767 dsd missover dlm="2c"x firstobs=2;
			informat
				zip best.
				city $35.
				statecode $2.
				ziptype $40.
				zcta5 $5.
				join_type $40.;
			format
				zip best.
				city $35.
				statecode $2.
				ziptype $40.
				zcta5 $5.
				join_type $40.;
			input
				zip 
				city $
				statecode $
				ziptype $
				zcta5 $
				join_type $;
			year=2019;
		run;
			
data ziptozcta0719;
	set data.ziptozcta07-data.ziptozcta09 uds2010-uds2019;
	keep zip zcta5 year join_type city statecode;
run;

proc sort data=ziptozcta0719 nodupkey out=ziptozcta0719_s; by zip year zcta5; run;

proc contents data=ziptozcta0719_s; run;
	
/* Checks */
data ck;
	set ziptozcta0719_s;
	by zip year;
	if not(first.year and last.year);
run;

proc sort data=ziptozcta0719 out=zcta_s; by zcta5 year; run;
	
data ck2;
	set zcta_s;
	by zcta5 year;
	if not(first.year and last.year);
run;

proc print data=ck (obs=50); run;
proc print data=ck2 (obs=50); run;
	
/* Fixes */
data ziptozcta0719_1;
	set ziptozcta0719_s;

	*	 delete records where zcta5 are blank;
	if zip=96898 and zcta5="No ZC" then delete;
	
	* turn zcta to numeric;
	zcta=fuzz(compress(zcta5,,'kd')*1);
	
	if zcta=0 then zcta=.;
	
	drop zcta5;
	rename zcta=zcta5;
run;

* retain backward and forward;
data ziptozcta0719_2;
	set ziptozcta0719_1;
	by zip year;
	if first.zip then zcta_r=.;
	retain zcta_r;
	if zcta5 ne . then zcta_r=zcta5;
	if zcta5=. and zcta_r ne . then do;
		filldown=1;
		zcta5=zcta_r;
	end;
run;

proc sort data=ziptozcta0719_2 out=ziptozcta0719_2s; by zip descending year; run;
/*
proc print data=ziptozcta0719_2 (obs=50);
	where filldown=1;
run;

proc print data=ziptozcta0719_2;
	where zip=96970;
run;
*/
data ziptozcta0719_3;
	set ziptozcta0719_2s;
	by zip descending year;
	if first.zip then zcta_u=.;
	retain zcta_u;
	if zcta5 ne . then zcta_u=zcta5;
	if zcta5=. and zcta_u ne . then do;
		fillup=1;
		zcta5=zcta_u;
	end;
	
	* Concatenated ZCTAs
	if zcta5<10 and zip>100 and zcta5=floor(zip/100) then fix=1;
	if zcta5<1000 and zip>1000 and zcta5=floor(zip/100) then fix=1;
	
	if fix=1 then zip=zcta5;
run;

proc freq data=ziptozcta0719_3;
	table fix / missing;
run;

proc sort data=ziptozcta0719_3 (keep=city statecode zip zcta5 year) out=data.ziptozcta0719; by zip year; run;