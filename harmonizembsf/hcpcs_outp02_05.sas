/* hcpcs_outp02_05.sas
   extract hcpcs (or hipps) codes from revcntr/line item segment for all claim types.
   JUST 2002-2005, JUST OP, DME, CAR.
      
   - hcpcs codes. for ip/snf/hha separate out hipps codes.
   - mdfr_cd's (multiply occurring)
   - rev_dt all years revctr recs
   - thru_dt 2006-2010 on line items/ revctr recs
   - expense date all years on line item recs (2 x)
   - dmest_dt - 2002-2005 (carl,dmeol only)
   
   July 2013, p.st.clair
   11/20/2014, p. st.clair: generalized for transition to DUA 25731
	 8/28/2018, p.ferido: modified for DUA 51866
	 
*/

options ls=120 ps=58 nocenter replace mprint;

%include "../../setup.inc";
%include "&maclib.claimfile_set_nseg.inc";   /* sets num segments for all claim types and years */
%include "&maclib.xwalk0205.mac";
%include "&maclib.sascontents.mac";
%include "renv.mac";
%include "extractfrom1.mac";
%include "extprocs1.mac";

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
%let linevardmem=srvc_cnt betos typsrvcb plcsrvc
            ;
%let linevarstd=mtus_cnt mtus_ind srvc_cnt betos typsrvcb plcsrvc
                srvc_cnt;
%let linedx=linedgns;
%let linedxstd=line_icd_dgns_cd;
%let line0205=sgmtline sgmt_num ;

%let revcdt=srev_dt;
%let revcdtstd=rev_dt;
%let revcvarstd=rev_cntr rev_unit;

%let ophha_apc=apchipps;
%let op_apcstd=apc;
%let hha_apcstd=prev_hipps;

%let acommonstd=clm_ln thru_dt;
%let bcommonstd=line_num thru_dt;

/* 2002 to 2005 have same names */

%extprocs1(op,cntrindex &revcdt &ophha_apc sthru_dt,clm_ln &revcdtstd &op_apcstd thru_dt,
           asisnames=hcpcs_cd mdfr_cd: &revcvarstd,
           idvar=ehic,claimvar=claimindex,RLvar=clm_ln,typsfx=R,
           smp=r,clms=,endy=2005);

%extprocs1(dmeo,lineindex &linedt &linedx,line_num &linedtstd &linedxstd,
           asisnames=hcpcs_cd mdfr_cd: &linevarstd &line0205 DMEST_DT,
           idvar=ehic,claimvar=claimindex,RLvar=line_num,typsfx=L,
           smp=20_,clms=_lnits,endy=2005);
%extprocs1(dmem,lineindex &linedt &linedx,line_num &linedtstd &linedxstd,
           asisnames=hcpcs_cd mdfr_cd: &linevardmem &line0205,
           idvar=ehic,claimvar=claimindex,RLvar=line_num,typsfx=L,
           smp=20_,clms=_lnits,endy=2005);

%extprocs1(car,lineindex &linedt &linedx,line_num &linedtstd &linedxstd,
           asisnames=hcpcs_cd mdfr_cd: &linevarstd &line0205,
           idvar=ehic,claimvar=claimindex,RLvar=line_num,typsfx=L,
           smp=l,clms=,endy=2005);

