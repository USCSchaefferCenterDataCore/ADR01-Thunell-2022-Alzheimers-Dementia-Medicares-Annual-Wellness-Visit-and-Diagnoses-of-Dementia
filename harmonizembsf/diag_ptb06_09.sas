/******************************************************************************************************************************************

	Program: diag_ptb06_09 (from mcr_diag)

	Description: Extracts and compiles ICD-9 info from Medicare files 

	Extracts from Part B claims only for 2006-2009

  Originally written by Benoit Stryckman
  Modified by P.St.Clair March 2013 to run on 2009 and 2010. Also added 
     claim id to keep list
  January 2015, p.stclair: updated to standardize code on DUA 25731
  August 2018, p.ferido: updated for DUA 51866
  
******************************************************************************************************************************************/

options ls=125 ps=50 nocenter replace compress=yes mprint FILELOCKS=NONE;

%include "../../setup.inc";
%include "&maclib.claimfile_set_nseg.inc";   /* sets num segments for all claim types and years */
%include "&maclib.xwalk0205.mac";  /* to crosswalk 2002-2005 ehics to bene_ids */
%include "&maclib.sascontents.mac";  /* to produce SAS contents listings */
%include "&maclib.renvars.mac";  /* to rename variables from one list to names in another list */
%include "&maclib.extractfrom1.mac"; /* macro to extract and rename variables from a single file */
%include "&maclib.extprocs1.mac"; /* macro to loop through years calling extractfrom1 for each
                                 and appending files when needed */

%let contentsdir=&doclib.&claim_extract.Contents/DiagnosisCodes/;
%let outfn=diag;
%let outlib=diagout;

libname diagout "&datalib.&claim_extract.DiagnosisCodes";

%partABlib;   

/********************************************************************/

/* use segments for dme files.  Found problems in single file for year
   Jean fixed this Nov 2014: also use segments for snf2007.  the single file has 0 observations
   Use single files for snf 2007 */
%macro resetnseg (typ,byear,eyear);
   %do year=&byear %to &eyear;
       %global nseg&typ&year;
       %let nseg&typ&year=0;
   %end;
%mend;

%resetnseg(ip,2002,2009)
%resetnseg(op,2002,2009)
%resetnseg(snf,2002,2009)
%resetnseg(hha,2002,2009)
%resetnseg(hos,2002,2009)
%resetnseg(car,2002,2009)
%resetnseg(med,2002,2009)
%resetnseg(dme,2002,2009)

%let smp=20; 
%let year=2009;

%macro diagvlist(stem,bsub,esub);
   %do i=&bsub %to &esub;
       &stem&i 
   %end;
%mend;

%include "diag_std_vname.inc";

/********************
   car:
   clm:  DGNS_CD8             Char      5    $5.       Claim Diagnosis Code VIII                           
   line: LINEDGNS              Char      5    $5.         Line Diagnosis Code                                  

   dme: 
   clm:  DGNS_CD8             Char      5    $5.       Claim Diagnosis Code VIII                       
   line: LINEDGNS              Char      5    $5.       Line Diagnosis Code                                 

*********************/   

/* variable names for 2006-2009 */
%let stay_dt=admsn_dt dschrgdt;
%let stay_dtmed=admsndt dschrgdt;
%let stay_dx=ad_dgns;
%let pta_pdx= pdgns_cd;
%let dxv=dgns_cd;
%let pta_dxn=10;
%let ptb_dxn=8;
%let linedx=linedgns;
%let poa=clmpoa;
%let medpoa=dgns_poa;

/* 2006 to 2009 have same names */

%extprocs1(car,%diagvlist(&dxv,1,&ptb_dxn),
               %diagvlist(&dxstd,1,&ptb_dxn),
           asisnames=&dtstd,
           idvar=bene_id,claimvar=clm_id,typsfx=C,
           smp=c,clms=,begy=2006,endy=2009);
%extprocs1(dme,%diagvlist(&dxv,1,&ptb_dxn),
               %diagvlist(&dxstd,1,&ptb_dxn),
           asisnames=&dtstd,
           idvar=bene_id,claimvar=clm_id,typsfx=C,
           smp=c,clms=,begy=2006,endy=2009);

/* for part b there are also line diagnoses */
%let outfn=diag_line;
%extprocs1(car,&linedx   ,
               &linedxstd,
           asisnames=line_num &linedtstd,
           idvar=bene_id,claimvar=clm_id,RLvar=line_num,typsfx=L,
           smp=l,clms=,begy=2006,endy=2009);
%extprocs1(dme,&linedx   ,
               &linedxstd,
           asisnames=line_num &linedtstd,
           idvar=bene_id,claimvar=clm_id,RLvar=line_num,typsfx=L,
           smp=l,clms=,begy=2006,endy=2009);
