/* bsfall_06max.sas 
   merge the ab and d parts of bsf for all files between 2006 to max year in dua
   this file is when you have to recreate all bsfall files in dua

   Adds three variables:
   - inbsfab = in bsfab (should be 1)
   - inbsfd = in bsfd (should be 1)
   - dupbene = 0/1 flag indicating if the bene_id is a duplicate

	 August 2018
   	Modified for DUA 51866 to use standard setup and macros

   Input files: bsfab2014 and bsfd2014
   Output files: bsfall2014
*/

options ls=125 ps=50 nocenter replace compress=yes mprint;

%include "../../setup.inc";

%let eyear=&maxyr;

%partABlib(byear=2006,eyear=&maxyr,types=bsf)
libname bsfout "&datalib.&clean_data.BeneStatus";

%include "&maclib.sascontents.mac";
%include "bsfall.mac";

%macro doyears(begyr,endyr);
	%do year=&begyr %to &endyr;
		%bsfall(&year,bsf,bsfall,ilib=bsf,olib=bsfout)

		proc freq data=bsfout.bsfall&year;
		   table dupbene inbsf_ab inbsf_d dupbene*inbsf_ab*inbsf_d /missing list;
		run;

		%sascontents(bsfall&year,lib=bsfout,contdir=&doclib.&clean_data.Contents/BeneStatus/)
	%end;
%mend;

%doyears(2006,&maxyr);
