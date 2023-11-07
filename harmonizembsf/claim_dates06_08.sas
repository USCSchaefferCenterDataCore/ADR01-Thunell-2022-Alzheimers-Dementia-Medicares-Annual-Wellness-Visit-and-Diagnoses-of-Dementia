/* claim_dates06_08.sas
   extract claim dates from claim segment for all claim types.
   years 2006-2008.
   the dates extracted are:
   - from and thru dates - all claims
   - dob dates - all claims
   - admission and discharge dates, where available 
     (ip/snf all years,hha discharge only 2002-2005,
      hos discharge only all years)
   - noncovered stay from/thru dates - where available
     (ip/snf all years)
   - carethru date - where available 
     (ip/snf all years)
   - start dates - where available
     (hha/hos all years)
   - qualifying dates - where available   
     (snf all years, hha/ip 2002-2005 only- ALL MISSING, so not extracted)
   - weekly dates - where available
     (all types all years incl car,dme, except op 2002-2005.)
   - benefits exhaust date - where available
     (ip/snf all years, hos only 2002-2005=ALL MISSING, so not extracted)

   NOT INCLUDING:
   - processed dates - where available
     (ip/snf/hos/hha 2002-2005 only, 
      profrom/thru ip/snf 2002-2005 only)
   - claim process date - 2002-2005,2010 ip/op/snf/hha/hos only
   - miscellaneous claim process, forward, received, etc. dates (2002-2005 only)
   
   From line items / rev centers: NOT EXTRACTED HERE. WILL GO ON HCPCS FILE.
   - rev_dt all years revctr recs
   - thru_dt 2006-2010 on line items/ revctr recs
   - expense date all years on line item recs (2 x)
   - dmest_dt - 2002-2005 (carl,dmeol only)

   July 2013, p.st.clair
   Sept. 23, 2014: modified to use single claim files for all years, except
   	for DME which seemed to have some problems. Added Crosswalk of 2002-2005 ids
   Oct. 27, 2014: split 2006-2008 and 2009 extracts into two separate programs.
   August 2018, p.ferido: modified to use single claim files for SNF2007 and DME
   
   Input files: all claim types for all years 2002-2011, i.e., [svc]c[yyyy]
   output fiels: [svc]_claim_dates[yyyy]
*/

options ls=120 ps=58 nocenter replace mprint;

%include "../../setup.inc";
%include "&maclib.xwalk0205.mac";
%include "&maclib.sascontents.mac";
%include "&maclib.claimfile_set_nseg.inc";   /* sets num segments for all claim types and years */

%include "extractfrom.mac";
%include "procs0210.mac";

/* will work with single files per year, except for dme
   where there seem to be problems with the single files */
   
%macro resetnseg (typ,byear,eyear);
   %do year=&byear %to &eyear;
       %global nseg&typ&year;
       %let nseg&typ&year=0;
   %end;
%mend;

%resetnseg(ip,2006,2009)
%resetnseg(op,2006,2009)
%resetnseg(snf,2006,2009)
%resetnseg(hha,2006,2009)
%resetnseg(hos,2006,2009)
%resetnseg(car,2006,2009)
%resetnseg(dme,2006,2009)
/* use segments for dme files.  Found problems in single file for year
    also use segments for snf2007.  the single file has 0 observations */
         
%let contentsdir=&doclib.&claim_extract.Contents/ClaimDates/;
%let outlib=claimdt;
%let outfn=claim_dates;

%partABlib;

libname claimdt "&datalib.&claim_extract.ClaimDates";
   
/********************************************************************/
/**** Macro vars for variable names *********************************/

/* for 2002 to 2005 */

%let common=sfromdt sthrudt sdob;
%let qlfy=sqlfyfrom sqlfythru;
%let stay=sadmsndt sdschrgdt; 
%let ipsnf=sncovfrom sncovthru scarethru sexhstdt;
%let wkly=swklydt;

/* for 2006 to 2010 */

%let commonstd=from_dt thru_dt dob_dt;
%let qlfystd=qlfyfrom qlfythru;
%let staystd=admsn_dt dschrgdt;
%let ipsnfstd=ncovfrom ncovthru carethru exhst_dt;
%let wklystd=wkly_dt;

/********************************************************************/
/** Extract dates from 2006-2008 claim files with standard varnames */

/* 2006 to 2008 have same variables and file name format */
%procs0210(ip,,,asisnames=&commonstd &staystd &ipsnfstd &wklystd,
           idvar=bene_id,claimvar=clm_id,begy=2006,endy=2008,
           smp=c,clms=);
%procs0210(snf,,,asisnames=&commonstd &qlfystd &staystd &ipsnfstd &wklystd,
           idvar=bene_id,claimvar=clm_id,begy=2006,endy=2008,
           smp=c,clms=);
%procs0210(op,,,asisnames=&commonstd &wklystd,
           idvar=bene_id,claimvar=clm_id,begy=2006,endy=2008,
           smp=c,clms=);
%procs0210(hos,,,asisnames=&commonstd &wklystd dschrgdt hspcstrt,
           idvar=bene_id,claimvar=clm_id,begy=2006,endy=2008,
           smp=c,clms=);
%procs0210(hha,,,asisnames=&commonstd &wklystd hhstrtdt,
           idvar=bene_id,claimvar=clm_id,begy=2006,endy=2008,
           smp=c,clms=);
%procs0210(car,,,asisnames=&commonstd &wklystd hcpcs_yr,
           idvar=bene_id,claimvar=clm_id,begy=2006,endy=2008,
           smp=c,clms=);
%procs0210(dme,,,asisnames=&commonstd &wklystd hcpcs_yr,smp=c,
           idvar=bene_id,claimvar=clm_id,begy=2006,endy=2008,clms=)    
