/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: Pulling all events related to AD drug use;
* Input: fdb_ndc_extract, part D events;
* Output: addrug_events;

options compress=yes nocenter ls=150 ps=200 errors=5 errorabend errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

%include "../../../../51866/PROGRAMS/setup.inc";
libname fdb "&datalib.Extracts/FDB/";
%partDlib(types=pde);
libname exp "../../data/adrd_inc_explore";
libname addrugs "../../data/ad_drug_use";

%let maxyr=2016;
***** Flagging all the AD drugs of interest;

data ADrx;
	set fdb.fdb_ndc_extract;

	ndcn=ndc*1;
	
	donep=(ndcn in(00093073805,00093073856,00093073898,00093073905,00093073956,00093073998,00093540765,00093540865,00143974709,00143974730,00143974809,00143974830,00228452903,00228452909,00378102577,00378102593,00378514405,00378514477,00378514493,00378514505,00378514577,00378514593,00781527410,00781527413,00781527431,00781527492,00781527510,00781527513,00781527531,00781527592,00781527664,00781527764,00904624261,00904624361,00904635461,00904635561,00904640846,00904640861,00904640880,00904640889,00904640946,00904640961,00904640980,00904640989,12280029230,12280029290,12280036715,12280036730,12280036790,13668010205,13668010210,13668010230,13668010240,13668010274,13668010290,13668010305,13668010310,13668010326,13668010330,13668010371,13668010374,13668010390,24979000406,24979000407,31722013910,31722014010,31722073705,31722073730,31722073790,31722073805,31722073830,31722073890,33342002707,33342002710,33342002715,33342002744,33342002807,33342002810,33342002815,33342002844,33342002907,33342002960,33342003007,33342003060,33342006107,33342006110,42291024690,42543070201,42543070205,42543070210,42543070230,42543070290,42543070301,42543070305,42543070310,42543070330,42543070390,43547027503,43547027509,43547027511,43547027603,43547027609,43547027611,43547038203,43547038209,45963056004,45963056008,45963056030,45963056104,45963056108,45963056130,49848000590,49848000690,49884023209,49884023211,49999075330,49999075430,49999075490,51079013830,51079013856,51079013930,51079013956,52343008930,52343008990,52343008999,52343009030,52343009090,52343009099,54868395200,54868424500,54868620700,54868620701,54868620800,55111030230,55111030290,55111035605,55111035610,55111035630,55111035690,55111035705,55111035710,55111035730,55111035790,55289015121,55289015130,58864088630,58864089530,59746032930,59746032990,59746033001,59746033030,59746033090,59762024501,59762024502,59762024503,59762024504,59762024601,59762024602,59762024603,59762024604,59762025001,59762025201,60429032110,60429032190,60429032290,60687017101,60687018201,60687018211,62332009230,62332009290,62332009291,62332009330,62332009390,62332009391,62756044018,62756044081,62756044083,62756044518,62756044581,62756044583,62856024511,62856024530,62856024541,62856024590,62856024611,62856024630,62856024641,62856024690,62856024730,62856024790,62856083130,62856083230,63304012810,63304012830,63304012877,63304012890,63304012910,63304012930,63304012977,63304012990,63629363201,63739064610,63739065210,63739065310,63739066710,63739066810,63739067810,64679031101,64679031103,64679031105,64679031201,64679031203,64679031205,65862032530,65862032590,65862032599,65862032630,65862032690,65862032699,67544009215,67544009217,67544009288,68084047701,68084047711,68084047801,68084047811,68084072501,68084072511,68084073401,68084073411,68180052706,68180052709,68382034606,68382034706,69452010813,69452010819,69452010830,69452010913,69452010919,69452010930));


	galan=(ndcn in(00054009021,00054009121,00054009221,00054013749,00115112008,00115112108,00115112208,00378272191,00378272291,00378272391,00378810491,00378810593,00378810693,00378810793,00378810891,00378811291,00555013809,00555013909,00555014009,00555102001,00555102101,00555102201,00591349630,00591349730,00591349830,10147088106,10147088206,10147088306,10147089103,10147089203,10147089303,12280029160,21695018430,21695059130,47335083583,47335083683,47335083783,50458038730,50458038830,50458038930,50458039660,50458039760,50458039860,50458049010,51079046901,51079046903,51079047001,51079047003,51079047101,51079047103,51079085201,51079085203,51079085301,51079085303,51079085401,51079085403,54868545300,55111040760,55111040860,55111040960,57237004960,57237005060,57237005160,59762000801,59762000901,59762001001,60505254206,60505254306,60505254406,63739070833,63739099933,65862045860,65862045960,65862046060,68084049211,68084049221,68084072911,68084072921,68382017714,68382017814,68382017914));

	
	meman=(ndcn in(00378110391,00378110491,00456320014,00456320212,00456320511,00456320560,00456320563,00456321011,00456321060,00456321063,00456340029,00456340733,00456341411,00456341433,00456341463,00456341490,00456342133,00456342833,00456342863,00456342890,00527194313,00591387044,00591387045,00591387060,00591387544,00591387545,00591387560,00591390087,00832111260,00832111360,00904650561,00904650661,12280028460,12280038160,13668022260,13668022360,16590076915,21695016930,21695016960,21695023215,21695023260,27241007006,27241007106,29300017105,29300017116,29300017205,29300017216,33342029709,33342029809,33342029815,35356010560,39328055112,42291055160,42291055260,42292000501,42292000506,42292000601,42292000606,47335032186,47335032213,47335032286,49848000360,49848000460,49999080430,49999080460,53746016930,53746017360,54868516100,54868565400,55111059660,55111059705,55111059760,55289093730,55289093760,58864088730,60687017311,60687017357,60687018411,60687018457,62332007560,62332007591,62332007642,62332007660,64679012102,64679012103,64679012202,64679012203,65862065260,65862065360,65862065399,66105065003,66105065103,68180022907,68180023007));

	
	rivas=(ndcn in(00078032306,00078032315,00078032344,00078032361,00078032406,00078032415,00078032444,00078032506,00078032515,00078032544,00078032606,00078032615,00078032644,00078033931,00078050115,00078050161,00078050215,00078050261,00078050315,00078050361,00591320860,00591320960,00591321060,00591321160,00781261413,00781261460,00781261513,00781261560,00781261613,00781261660,00781261713,00781261760,00781730431,00781730458,00781730931,00781731331,06808405501,12280038960,21695035730,33342008909,33342008915,33342009009,33342009015,33342009109,33342009115,33342009209,33342009215,35356039430,47781030403,47781030503,47781040503,51991079306,51991079406,51991079506,51991079606,54868451200,54868451201,54868524000,54868533900,54868583900,54868595400,54868607000,54868614500,55111035205,55111035260,55111035305,55111035360,55111035405,55111035460,55111035505,55111035560,60429039660,60505322006,60505322106,60505322206,60505322306,62756014513,62756014586,62756014613,62756014686,62756014713,62756014786,62756014813,62756014886,63739057610,63739057710,63739057810,63739057910,68084055001,68084055011));
	
	ADdrug=max(donep,galan,meman,rivas);
	
	if ADdrug=1;
	
run;


***** Merging to Part D Events;

%macro pde;

	proc sql;
		%do year=2006 %to &maxyr.;
				create table pde&year as
				select x.bene_id, x.pde_id, x.srvc_dt, &year as year, ADdrug, donep, galan, meman, 
				rivas, x.dayssply, y.gcdf, y.gcdf_desc, x.prscrbid
				from pde.opt1pde&year as x inner join ADrx as y
				on x.prdsrvid=y.ndc
				order by bene_id, year, srvc_dt;
		%end;
	quit;

%mend;

%pde;

***** Setting all together;
data addrugs.ADdrugs_0616;
	format year best4. srvc_dt mmddyy10.;
	set pde:;
	by bene_id year srvc_dt;
run;                 

proc contents data=addrugs.ADdrugs_0616; run;
	
***** Creating date level part D file;
proc sql;
	create table addrugs.ADdrugs_dts_0616 as
	select bene_id, srvc_dt, year, max(ADdrug) as ADdrug, max(donep) as donep, max(galan) as galan,
	max(meman) as meman, max(rivas) as rivas, sum(dayssply) as dayssply
	from addrugs.ADdrugs_0616 
	where dayssply>=14
	group by bene_id, year, srvc_dt
	order by bene_id, year, srvc_dt;
quit;

***** Checks;
proc means data=addrugs.ADdrugs_dts_0616 noprint;
	class year;
	var ADdrug donep galan meman rivas dayssply;
	output out=addrugs_stats (drop=_type_ _freq_) sum(ADdrug donep galan meman rivas)= mean(dayssply)=avg_dayssply;
run;

proc freq data=addrugs.ADdrugs_dts_0616 noprint; table year*bene_id / out=bene_byyear; run;
proc freq data=bene_byyear noprint; table year / out=bene_byyear1 (drop=percent rename=(count=total_bene)); run;
	
data addrugs_stats1;
	merge bene_byyear1 (in=a) addrugs_stats (in=b);
	by year;
run;

proc print data=addrugs_stats1; run;


			