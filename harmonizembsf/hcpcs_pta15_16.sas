/* hcpcs_pta09_11.sas
   extract hcpcs (or hipps) codes from revcntr/line item segment for all claim types.
   JUST 2009-2011, JUST IP, HHA, HOS, and SNF.
   
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

%let maxyr=2016; /* current default is 2012 */
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

%resetnseg(ip,2002,2016)
%resetnseg(op,2002,2016)
%resetnseg(snf,2002,2016)
%resetnseg(hha,2002,2016)
%resetnseg(hos,2002,2016)
%resetnseg(car,2002,2016)

/* for 2006 to 2010
  ip/snf no rev_dt
  apchipps: hha/op-2002-2010,hos/ip/snf-2002-2005
  check if always missing hos/ip/snf 2002-2005
  check if same as hipps code in hcpcs_cd in hha/snf  */

%let linedtstd=expnsdt1 expnsdt2;
%let linedx=linedgns;
%let linedxstd=line_icd_dgns_cd;
%let linevarstd=mtus_cnt mtus_ind srvc_cnt betos typsrvcb plcsrvc
                srvc_cnt;
%let acommonstd=clm_ln thru_dt;
%let bcommonstd=line_num thru_dt;

%let revcdtstd=rev_dt;
%let revcvarstd=rev_cntr rev_unit;
%let ophha_apc=apchipps;
%let op_apcstd=apc;
%let hha_apcstd=prev_hipps;

%extprocs2(ip,,,
           asisnames=thru_dt hcpcs_cd &revcvarstd,
           outf2=hipps,inv2=,outv2=,
           asisv2=&revcvarstd hipps_cd,
           codein=hipps_.sas,
           dts=thru_dt,
           idvar=bene_id,claimvar=clm_id,RLvar=clm_ln,typsfx=R,
           begy=2015,endy=2016,
           smp=r,clms=);

%extprocs2(hha,,,
           asisnames=thru_dt hcpcs_cd &revcvarstd &revcdtstd,
           outf2=hipps,inv2=&ophha_apc,outv2=&hha_apcstd,
           asisv2=&revcvarstd hipps_cd,
           codein=hipps_.sas,
           dts=thru_dt rev_dt,
           idvar=bene_id,claimvar=clm_id,RLvar=clm_ln,typsfx=R,
           smp=r,clms=,begy=2015,endy=2016);

%extprocs2(snf,,,
           asisnames=thru_dt hcpcs_cd &revcvarstd,
           outf2=hipps,inv2=,outv2=,
           asisv2=&revcvarstd hipps_cd,
           codein=hipps_.sas,
           dts=thru_dt,
           idvar=bene_id,claimvar=clm_id,RLvar=clm_ln,typsfx=R,
           begy=2015,endy=2016,
           smp=r,clms=);

%extprocs2(hos,,,
           asisnames=thru_dt hcpcs_cd &revcvarstd &revcdtstd,
           dts=thru_dt rev_dt,
           idvar=bene_id,claimvar=clm_id,RLvar=clm_ln,typsfx=R,
           codein=hcpcs_.sas,
           smp=r,clms=,begy=2015,endy=2016);

endsas;


