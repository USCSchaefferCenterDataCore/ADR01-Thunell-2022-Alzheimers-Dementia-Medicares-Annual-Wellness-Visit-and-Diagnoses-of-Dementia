/* bene_status_month2014.sas
   make a file of beneficiary status by month
   Monthly flags for AB enrollment, HMO status, dual eligibility,
     whether alive/ died this month/ died earlier in year, Part D plan,
     LIS status, RDS status.
   Keep flags on whether enrolled AB all year, HMO all yr, FFS allyr,
     whether creditable coverage.
   Also keep gender, birthdate, deathdate, age in month.
   
   SAMPLE: all benes on denominator or bsf, no duplicates,
           and did not die in a prior year according to the death date.
   Level of observation: bene_id, year, month
   
   Input files: den[yyyy] for 2002-2008
                bsf2009d for 2009
                bsfall[yyyy] for 2010-2011
   Output files: bene_status_month[yyyy]
   
   Feb 20, 2014, p. st.clair
   March 14, 2014, p.st.clair: added merge with cleaned bene_demog file
        switched to using birth_date/death_date from bene_demog
   July 2, 2014, p. st.clair: correct missing year variable from 2009-2011,
                              add egwp status, and drop benes with dropflag=Y. 
  October 30, 2014, p. st.clair: generalized for transition to DUA 25731
  August 28, 2018, p. ferido: generalized for transition to DUA 51866
	September 4, 2018, L. Gascue: code from program bene_status_month.sas adjusted to run on 2014
																	(New program "bene_status_month2014.sas")  
	September 9, 2019, p. ferido: removed creditable coverage switch
*/

options ls=150 ps=58 nocenter compress=yes replace;

%include "../../setup.inc";
%include "&maclib.sascontents.mac";
%include "&maclib.listvars.mac";
%include "&maclib.renvars.mac";
%include "statmo_2015on.mac";  /* macro to get bene_status_month vars across years */

%partABlib(types=bsf)

libname bene "&datalib.&clean_data./BeneStatus";

%let contentsdir=&doclib.&clean_data.Contents/BeneStatus/;

proc format;
  %include "&fmtlib.bene_status.fmt";
  %include "&fmtlib.p2egwp.fmt";
run;

%statmo(2015,2016,hmo_mo=hmo_mo,hmoind=hmoind,hmonm=0,stbuy=buyin,denbsf=bsfab,denlib=bsf,demogyr=2016);
