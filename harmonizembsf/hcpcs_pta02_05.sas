/* hcpcs_pta0205.sas
   extract hcpcs (or hipps) codes from revcntr/line item segment for all claim types.
   JUST 2002-2005, JUST IP, HHA, HOS, and SNF.
   
   - hcpcs codes. for ip/snf/hha separate out hipps codes.
   - mdfr_cd's (multiply occurring)
   - rev_dt all years revctr recs
   - thru_dt 2006-2010 on line items/ revctr recs
   - expense date all years on line item recs (2 x)
   - dmest_dt - 2002-2005 (carl,dmeol only)
   
   July 2013, p.st.clair
   11/20/2014, p. st.clair: generalized for transition to DUA 25731
	 8/28/2018, p.ferido: generalized for DUA 51866
*/

options ls=120 ps=58 nocenter replace mprint;

%include "../../setup.inc";
%include "&maclib.claimfile_set_nseg.inc";   /* sets num segments for all claim types and years */
%include "&maclib.xwalk0205.mac";
%include "&maclib.sascontents.mac";
%include "renv.mac";
%include "extractfrom2.mac";
%include "extprocs2.mac";

%let contentsdir=&doclib.&claim_extract.Contents/ProcedureCodes/;

%let outlib=procout;
%let outfn=hcpcs;

libname procout "&datalib.&claim_extract.ProcedureCodes";

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

/* for 2002 to 2005 */

%let linedt=sexpndt1 sexpndt2;
%let linedtstd=expnsdt1 expnsdt2;
%let linevar=LINEDGNS MTUS_CNT MTUS_IND srvc_cnt BETOS typsrvcb plcsrvc
            ;
%let linedx=linedgns;
%let linedxstd=line_icd_dgns_cd;
%let line0205=sgmtline sgmt_num ;

%let revcdt=srev_dt;
%let revcdtstd=rev_dt;
%let revcvarstd=rev_cntr rev_unit;
%let ophhastd=apchipps;
%let ophha_apc=apchipps;
%let hha_apcstd=prev_hipps;

/* 2002 to 2005 have same names */

%extprocs2(ip,&revcdt,&revcdtstd,
           asisnames=hcpcs_cd mdfr_cd: &revcvarstd,
           outf2=hipps,inv2=,outv2=,
           asisv2=&revcvarstd hipps_cd,
           codein=hipps_.sas,
           idvar=ehic,claimvar=claimindex,RLvar=cntrindex,typsfx=R,
           dts=thru_dt rev_dt,
           smp=r,clms=,endy=2005);

/* 2002 to 2005 have same names, but only 2004-2005 have populated modifer codes
   in the SNF claims */
%extprocs2(snf,&revcdt,&revcdtstd,
           asisnames=hcpcs_cd &revcvarstd,
           outf2=hipps,inv2=,outv2=,
           asisv2=&revcvarstd hipps_cd,
           codein=hipps_.sas,
           idvar=ehic,claimvar=claimindex,RLvar=cntrindex,typsfx=R,
           dts=thru_dt rev_dt,
           smp=r,clms=,endy=2003);
%extprocs2(snf,&revcdt,&revcdtstd,
           asisnames=hcpcs_cd mdfr_cd1 mdfr_cd2 mdfr_cd3 &revcvarstd,
           outf2=hipps,inv2=,outv2=,
           asisv2=&revcvarstd hipps_cd mdfr_cd1 mdfr_cd2 mdfr_cd3,
           codein=hipps_.sas,
           idvar=ehic,claimvar=claimindex,RLvar=cntrindex,typsfx=R,
           dts=thru_dt rev_dt,
           smp=r,clms=,begy=2004,endy=2005);

%extprocs2(hha,&revcdt,&revcdtstd,
           asisnames=hcpcs_cd mdfr_cd: &revcvarstd,
           outf2=hipps,inv2=&ophha_apc,outv2=&hha_apcstd,
           asisv2=&revcvarstd hipps_cd,
           codein=hipps_.sas,
           idvar=ehic,claimvar=claimindex,RLvar=cntrindex,typsfx=R,
           dts=thru_dt rev_dt,
           smp=r,clms=,endy=2005);

%extprocs2(hos,&revcdt,&revcdtstd,
           asisnames=hcpcs_cd mdfr_cd: &revcvarstd,
           codein=hcpcs_.sas,
           idvar=ehic,claimvar=claimindex,RLvar=cntrindex,typsfx=R,
           dts=thru_dt rev_dt,
           smp=r,clms=,endy=2005);

