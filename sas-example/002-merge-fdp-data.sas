/***************************************************************************
 * 002-merge-fdp-data.sas
 *
 * Purpose:
 *   Link master CCM observations to earnings actuals/forecasts/following from
 *   five forecast-data providers (FDPs): I/B/E/S, FactSet, Zacks, Capital
 *   IQ, and Bloomberg. Then attach the price two trading days before the
 *   announcement, derive scaled-by-price surprises, and write coverage
 *   indicators.
 *
 * Raw Inputs (from RAW_DATA_DIR):
 *   master_ccm_07182025.sas7bdat            (output of 000-collect-master-ccm-dataset.sas)
 *   surpsum_07182025.sas7bdat               (IBES, downloaded by this script if absent)
 *   surpsumu_07182025.sas7bdat              (IBES, downloaded by this script if absent)
 *   statsum_epsus_07182025.sas7bdat         (IBES, downloaded by this script if absent)
 *   statsumu_epsus_07182025.sas7bdat        (IBES, downloaded by this script if absent)
 *   actu_epsus_07182025.sas7bdat            (IBES, downloaded by this script if absent)
 *   ibes_adj_07182025.sas7bdat              (IBES, downloaded by this script if absent)
 *   iclink_07182025.sas7bdat                (WRDS iclink, downloaded by this script if absent)
 *   surpsum_07222022.sas7bdat               (older IBES snapshot for Bloomberg split-adjustment compare)
 *   zacks_company_info_07182025.sas7bdat    (Zacks, downloaded by this script if absent)
 *   zacks_eps_surp_07182025.sas7bdat        (Zacks, downloaded by this script if absent)
 *   wrds_ciqsymbol_07182025.sas7bdat        (CIQ-GVKEY link, downloaded by this script if absent)
 *   bql_market_e_and_a.sas7bdat             (Bloomberg BQL output; see Notes)
 *   fdp_identifiers.sas7bdat                (Bloomberg ticker map; see Notes)
 *   bql_f.sas7bdat                          (Bloomberg BQL following; see Notes)
 *   dsf_07172025.sas7bdat                   (CRSP daily stock file)
 *   quarterly_consensus_basic_<YYYY>.csv    (FactSet, 1997-2024)
 *
 * Derived Inputs (from DATA_DIR):
 *   raw_ciq_data.dta                        (output of 001-prepare-raw-ciq-data.R)
 *
 * Outputs (to DATA_DIR):
 *   quarterly_consensus_all.sas7bdat        (combined FactSet 1997-2024, derived intermediate)
 *   all_five1.sas7bdat                      (final firm-quarter merged dataset)
 *
 * Notes:
 *   - Reads RAW_DATA_DIR and DATA_DIR from .env via %load_env (defined in MACROS.sas).
 *   - WRDS downloads are wrapped with %if not %sysfunc(exist(...)) checks so a
 *     re-run with the .sas7bdat already on disk skips the download (and the
 *     SIGNON prompt). Re-pulling requires deleting the relevant .sas7bdat first.
 *   - The Bloomberg .sas7bdat files are produced upstream from BQL .dta files
 *     via a manual Stata->SAS conversion outside this code path; this script
 *     reads the existing .sas7bdat directly. The original .dta sources are
 *     not redistributable.
 * -   The Bloomberg fdp_identifiers file was manually created by Stephannie Larocque 
 *     and student RAs at Notre Dame during 2020 - 2022. It was created by linking Bloomberg tickers 
 *     for Russell 3000 constituents to permno/gvkey/cusip using a combination of CUSIP-linking, 
 *     fuzzy name matching, and hand collection. Bloomberg tickers used in the final sample,
 *     along with their mapping to permno/gvkey/cusip are provided in the JAR data package sample_id file. 
 ***************************************************************************/


*Setup*********************************************************************;

/* Resolve the path to this script. SYSIN is set in batch mode (sas -SYSIN);
   SAS_EXECFILEPATH is set by Enhanced Editor / Enterprise Guide interactively. */
%let codepath = %sysfunc(getoption(sysin));
%if %length(&codepath) = 0 %then %do;
    %let codepath = %sysfunc(sysget(SAS_EXECFILEPATH));
%end;
%include "&codepath\..\MACROS.sas";
%load_env;

libname raw  "&RAW_DATA_DIR";
libname data "&DATA_DIR";

*Decide whether any WRDS downloads are needed -- only signon if so;
%let need_wrds = 0;
%macro check_need(target=);
  %if not %sysfunc(exist(&target)) %then %let need_wrds = 1;
%mend;
%check_need(target=raw.surpsum_07182025);
%check_need(target=raw.surpsumu_07182025);
%check_need(target=raw.statsumu_epsus_07182025);
%check_need(target=raw.statsum_epsus_07182025);
%check_need(target=raw.actu_epsus_07182025);
%check_need(target=raw.ibes_adj_07182025);
%check_need(target=raw.iclink_07182025);
%check_need(target=raw.zacks_company_info_07182025);
%check_need(target=raw.zacks_eps_surp_07182025);
%check_need(target=raw.wrds_ciqsymbol_07182025);

%if &need_wrds = 1 %then %do;
  %let wrds = wrds-cloud.wharton.upenn.edu 4016;
  options comamid=TCP remote=WRDS;
  signon username=_prompt_;
%end;
%else %put NOTE: All WRDS-downloaded raw files already exist -- skipping signon.;

*Wrap each proc download with an existence check;
%macro maybe_download(target=, src=);
  %if not %sysfunc(exist(&target)) %then %do;
    rsubmit;
    proc download data=&src out=&target; run;
    endrsubmit;
  %end;
  %else %put NOTE: &target exists -- skipping download.;
%mend;

/***************************************************************************
PART 1: LINK I/B/E/S DATA TO MASTER CCM
***************************************************************************/

*Download IBES files from WRDS;
%maybe_download(target=raw.surpsum_07182025,        src=ibes.surpsum);
%maybe_download(target=raw.surpsumu_07182025,       src=ibes.surpsumu);
%maybe_download(target=raw.statsumu_epsus_07182025, src=ibes.statsumu_epsus);
%maybe_download(target=raw.statsum_epsus_07182025,  src=ibes.statsum_epsus);
%maybe_download(target=raw.actu_epsus_07182025,     src=ibes.actu_epsus);
%maybe_download(target=raw.ibes_adj_07182025,       src=ibes.adj);

*Link to IBES tickers using WRDS iclink (creates iclink dataset on the WRDS
 server, then downloads it). Wrapped in a macro because %iclink itself
 contains nested %if blocks, which SAS does not support in open code.;
%macro maybe_iclink;
  %if not %sysfunc(exist(raw.iclink_07182025)) %then %do;
    rsubmit;
    %iclink;
    proc download data=iclink out=raw.iclink_07182025; run;
    endrsubmit;
  %end;
  %else %put NOTE: raw.iclink_07182025 exists -- skipping iclink build + download.;
%mend;
%maybe_iclink;

proc sql;
	create table work.ibes1 as select distinct
		a.*, 
		b.ticker as ibes_ticker, 
		b.score as icscore,
		b.cname as ibes_cname
	from raw.master_ccm_07182025 as a 
	left join raw.iclink_07182025 as b
		on a.permno = b.permno and b.score < 3;
quit;

*Merge with unadjusted surprise file;
proc sql;
	create table work.ibes2 as select distinct
		a.*, 
		b.pyear, 
		b.pmon, 
		b.anndats as ibes_anndats, 
		b.surpmean as ibes_mean_u, 
		b.actual as ibes_actual_u,
		b.surpstdev as ibes_stdev_u, 
		b.oftic as ibes_oftic,
		(a.crsp_ticker = b.oftic) as ibes_tickmatch,
		1 - missing(b.surpmean) as ibes_match,
		min(spedis(a.ibes_cname, a.conm), spedis(a.conm, a.ibes_cname)) as ibes_name_dist 
	from work.ibes1 a 
	left join raw.surpsumu_07182025 b
		on a.ibes_ticker = b.ticker 
		and year(a.datadate) = b.pyear 
		and month(a.datadate) = b.pmon
		and b.measure = "EPS" 
		and b.fiscalp = "QTR" 
		and missing(b.surpmean) = 0 
		and missing(b.actual) = 0
		and abs(a.rdq - b.anndats) <= 5;
quit;

*Keep best match;
proc sort data=work.ibes2; 
	by gvkey datadate descending ibes_match icscore descending ibes_tickmatch ibes_name_dist; 
run;

proc sort data=work.ibes2 out=work.ibes3 nodupkey; 
	by gvkey datadate; 
run;

*Merge with adjusted surprise file;
proc sql;
	create table work.ibes4 as select distinct
		a.*, 
		b.surpmean as ibes_mean_a, 
		b.actual as ibes_actual_a,
		case when a.ibes_actual_u ne 0 then b.actual / a.ibes_actual_u else 1 end as ibes_a_u_ratio
	from work.ibes3 a 
	left join raw.surpsum_07182025 b
		on a.ibes_ticker = b.ticker 
		and year(a.datadate) = b.pyear 
		and month(a.datadate) = b.pmon
		and b.measure = "EPS" 
		and b.fiscalp = "QTR" 
		and missing(b.surpmean) = 0 
		and missing(b.actual) = 0
		and a.ibes_anndats = b.anndats;
quit;

*Get IBES analyst following from most recent statpers before announcement;
proc sql;
	create table work.ibes_following1 as select distinct
		ticker, 
		fpedats, 
		max(statpers) as statpers format date9., 
		anntims_act 
	from raw.statsum_epsus_07182025
	where statpers <= anndats_act
		and MEASURE = "EPS" 
		and fiscalp = "QTR" 
		and FPI = "6"
	group by ticker, fpedats;
quit;

proc sql;
	create table work.ibes_following2 as select distinct
		a.*, b.numest
	from work.ibes_following1 a
	inner join raw.statsumu_epsus_07182025 b
		on a.ticker = b.ticker 
		and a.fpedats = b.fpedats 
		and a.statpers = b.statpers
	where b.MEASURE = "EPS" 
		and b.fiscalp = "QTR" 
		and b.FPI = "6";
quit;

proc sql;
	create table work.ibes5 as select distinct
		a.*, 
		b.statpers as ibes_statpers, 
		b.numest as ibes_following, 
		missing(b.numest) as missing_ibes_following, 
		b.anntims_act as ibes_anntims
	from work.ibes4 as a 
	left join work.ibes_following2 as b
		on a.ibes_ticker = b.ticker 
		and a.datadate = b.fpedats;
quit;

*Merge IBES split adjustment factors;
proc sort data=raw.ibes_adj_07182025; 
	by ticker spdates; 
run;

data work.adj2;
	format lag_date date9.;
	set raw.ibes_adj_07182025;
	by ticker;
	lag_adj = lag(adj);
	lag_date = lag(spdates);
	if first.ticker then do;
		lag_adj = .;
		lag_date = .;
	end;
run;

proc sort data=work.adj2; 
	by ticker descending spdates; 
run;

data work.adj3;
	format lead_date date9.;
	set work.adj2;
	by ticker;
	lead_adj = lag(adj);
	lead_date = lag(spdates);
	if first.ticker then do;
		lead_adj = .;
		lead_date = .;
	end;
run;

proc sort data=work.adj3; 
	by ticker spdates; 
run;

proc sql;
	create table work.ibes6 as select distinct
		a.*, 
		b.lag_date as lag_spdates, 
		b.spdates, 
		b.lead_date as lead_spdates, 
		b.lag_adj, 
		b.adj, 
		b.lead_adj,
		case when missing(b.lag_adj) then 1 else b.lag_adj end as ibes_sfactor
	from work.ibes5 a 
	left join work.adj3 b 
		on a.ibes_ticker = b.ticker 
		and (b.lag_date = . or b.lag_date <= a.ibes_anndats) 
		and a.ibes_anndats < b.spdates;
quit;

*Merge 2022 adjusted IBES data for BB split adjustment;
proc sql;
	create table work.ibes7 as select distinct 
		a.*,
		b.actual as ibes_actual_a_2022,
		case when a.ibes_actual_u ne 0 then b.actual / a.ibes_actual_u else 1 end as ibes_a_u_ratio_2022,
		(a.ibes_actual_a = b.actual) as adj_check_2022
	from work.ibes6 a 
	left join raw.surpsum_07222022 b
		on a.ibes_ticker = b.ticker 
		and year(a.datadate) = b.pyear 
		and month(a.datadate) = b.pmon 
		and b.measure = "EPS" 
		and b.fiscalp = "QTR";
quit;

/***************************************************************************
PART 2: LINK FACTSET DATA TO MASTER CCM
***************************************************************************/

*Import and combine FactSet yearly CSV files;
%macro fset_import;
%do i = 1997 %to 2024;
	proc import datafile="&RAW_DATA_DIR\quarterly_consensus_basic_&i..csv"
		out=work.quarterly_&i
		dbms=csv
		replace;
		getnames=yes;
	run;

	data work.quarterly_&i;
		set work.quarterly_&i;
		year = &i;
		FE_STD_DEV_num = FE_STD_DEV * 1;
		drop ADJDATE FE_STD_DEV;
		rename FE_STD_DEV_num = FE_STD_DEV;
	run;
%end;
%mend;
%fset_import; 

*Combine all FactSet years;
data work.fset_all;	
	set work.quarterly_1997 - work.quarterly_2024;
run;

*Save combined consensus data;
data data.quarterly_consensus_all;
	set work.fset_all;
run;

*Filter to USD EPS with valid data. Read from work.fset_all rather than
 the just-saved data.quarterly_consensus_all to avoid a round-trip
 through DATA_DIR (J: drive on Google Drive may not finalize a fresh
 write before the next read);
data work.quarterly_consensus_all;
	set work.fset_all;
	where CUSIP ne ''
		and FE_ITEM = 'EPS'
		and ACTUAL_VALUE ne .
		and CONS_END_DATE <= REPORT_DATE
		and estimate_currency = "USD";
run;

*Keep last consensus before report date;
proc sort data=work.quarterly_consensus_all;
	by CUSIP FE_FP_END descending CONS_END_DATE;
run;

proc sort data=work.quarterly_consensus_all nodupkey;
	by CUSIP FE_FP_END;
run;


*Merge FactSet data;
proc sql;
	create table work.fset1 as select distinct
		a.*, 
		b.fsym_id, 
		b.cons_start_date as fset_cons_start_date,
		b.cons_end_date as fset_cons_end_date,
		b.report_date as fset_anndats, 
		b.actual_value / a.ibes_a_u_ratio as fset_actual_u,
		b.actual_value as fset_actual_a,
		b.fe_mean / a.ibes_a_u_ratio as fset_mean_u,
		b.fe_mean as fset_mean_a,
		b.fe_num_est as fset_following,
		b.primary_ticker_exchange as fset_ticker,
		b.proper_name as fset_cname,
		b.fe_std_dev as fset_stdev_a
	from work.ibes7 a 
	left join work.quarterly_consensus_all b
		on substr(a.cusip, 1, 8) = substr(b.cusip, 1, 8)
		and month(a.datadate) = month(b.fe_fp_end) 
		and year(a.datadate) = year(b.fe_fp_end);
quit;

/***************************************************************************
PART 3: LINK ZACKS DATA
***************************************************************************/

*Download Zacks files from WRDS;
%maybe_download(target=raw.zacks_company_info_07182025, src=zacks.company_info);
%maybe_download(target=raw.zacks_eps_surp_07182025,     src=zacks.eps_surp);

*Merge Zacks surprise with company info;
proc sql;
	create table work.zacks_surp as select distinct
		a.*, 
		b.name, 
		b.cusip 
	from raw.zacks_eps_surp_07182025 a
	inner join raw.zacks_company_info_07182025 b
		on a.zid = b.zid;
quit;

*Merge Zacks to ongoing dataset;
proc sql;
	create table work.zacks1 as select distinct
		a.*,
		b.zid,
		b.entry_date as zacks_entry_date,
		b.report_date as zacks_anndats,
		b.actual_eps as zacks_actual_a,
		b.actual_eps / a.ibes_a_u_ratio as zacks_actual_u,
		b.consensus_eps as zacks_mean_a,
		b.consensus_eps / a.ibes_a_u_ratio as zacks_mean_u,
		b.consensus_std as zacks_std_a,
		b.number_of_est as zacks_following,
		b.adjustment as zacks_adjustment,
		b.hticker as zacks_ticker,
		b.name as zacks_cname
	from work.fset1 a 
	left join work.zacks_surp b
		on substr(a.cusip, 1, 8) = substr(b.cusip, 1, 8)
		and month(a.datadate) = month(b.reference_period) 
		and year(a.datadate) = year(b.reference_period)
		and abs(a.rdq - b.report_date) <= 5
		and not missing(b.actual_eps);
quit;

*Keep earliest entry date when duplicates;
proc sort data=work.zacks1; 
	by gvkey datadate zacks_entry_date; 
run;

proc sort data=work.zacks1 out=work.zacks2 nodupkey; 
	by gvkey datadate; 
run;

/***************************************************************************
PART 4: LINK CAPITAL IQ DATA
***************************************************************************/

*Import raw CIQ data (from 001 output);
proc import out=work.ciq_data
	datafile="&DATA_DIR\raw_ciq_data.dta";
run;

*Process CIQ data - use normalized basis when available, then GAAP;
proc sql;
	create table work.ciq_majority1 as select distinct 
		*,
		actualSFactor as ciq_sfactor,
		case 
			when estimatevarid = 100173 then "NORM" 
			when estimatevarid = 100278 then "GAAP" 
			else "ADJ" 
		end as ciq_basis,
		actual_effective as actual_edatetime format datetime.,
		datepart(actual_edatetime) as actual_edate format date9.,
		timepart(actual_edatetime) as actual_etime format time8.
	from work.ciq_data
	where not missing(estimatevarid);
quit;

*Download CIQ-GVKEY link;
%maybe_download(target=raw.wrds_ciqsymbol_07182025, src=ciq.wrds_ciqsymbol);

data work.wrds_gvkey;
	set raw.wrds_ciqsymbol_07182025;
	where symboltypecat = 'gvkey';
	gvkey = symbolvalue;
run;

*Link CIQ to GVKEY, exclude ADJ basis;
proc sql;
	create table work.ciq_gvkey as select distinct
		a.*, 
		b.gvkey
	from work.ciq_majority1 a
	inner join work.wrds_gvkey b
		on a.companyid = b.companyid 
		and (b.startdate <= datepart(a.periodenddate) or b.startdate = .B) 
		and (datepart(a.periodenddate) <= b.enddate or b.enddate = .E)
	where not missing(a.periodenddate) 
		and not missing(ciq_mean_u) 
		and not missing(ciq_actual_u) 
		and not missing(ciq_following)
		and ciq_basis ne "ADJ"
	order by companyname, periodenddate;
quit;

*Drop if consensus effective after announcement;
data work.ciq_gvkey2; 
	set work.ciq_gvkey; 
	where consensus_effective <= actual_effective; 
run; 

*Keep last forecast by type;
proc sort data=work.ciq_gvkey2; 
	by gvkey periodenddate ciq_basis descending consensus_effective; 
run;

proc sort data=work.ciq_gvkey2 out=work.ciq_gvkey3 nodupkey; 
	by gvkey periodenddate ciq_basis; 
run;

*When duplicates, prefer NORM to GAAP;
proc sort data=work.ciq_gvkey3; 
	by gvkey periodenddate descending ciq_basis; 
run;

proc sort data=work.ciq_gvkey3 out=work.ciq_gvkey4 nodupkey; 
	by gvkey periodenddate; 
run;

*Merge CIQ to ongoing dataset;
proc sql;
	create table work.ciq1 as select distinct
		a.*, 
		b.companyid as ciq_companyid, 
		b.ciq_basis,
		b.ciq_mean_u,
		b.ciq_mean_a,
		b.ciq_actual_u, 
		b.ciq_actual_a,
		b.ciq_following,
		b.actual_edate as ciq_anndats,
		b.actual_etime as ciq_anntims, 
		b.ciq_sfactor
	from work.zacks2 a 
	left join work.ciq_gvkey4 b
		on a.gvkey = b.gvkey
		and year(a.datadate) = year(datepart(b.periodenddate)) 
		and month(a.datadate) = month(datepart(b.periodenddate));
quit;

/***************************************************************************
PART 5: LINK BLOOMBERG DATA
***************************************************************************/

*Merge BQL to identifiers (Bloomberg .sas7bdat files in raw_data come from
 a manual Stata->SAS conversion of BQL .dta output -- see header notes);
proc sql;
	create table work.bb1 as select distinct
		datepart(a.dates) as datadate format date9.,
		b.gvkey,
		b.lpermno as permno,
		b.cusip,
		b.ticker as ibes_ticker, 
		a.*
	from raw.bql_market_e_and_a a
	inner join raw.fdp_identifiers b
		on a.ticker_full = b.ticker_full
	where not missing(a.dates) 
		and year(datepart(a.dates)) > 1995 
		and not missing(a.actualeps) 
		and not missing(a.meaneps);
quit;

*Merge Bloomberg to ongoing dataset;
proc sql;
	create table work.bb2 as select distinct 
		a.*, 
		b.ticker_full as bb_ticker_full, 
		b.ticker as bb_ticker, 
		b.meaneps as bb_mean_a,
		b.meaneps / a.ibes_a_u_ratio_2022 as bb_mean_u,
		b.actualeps as bb_actual_a,
		b.actualeps / a.ibes_a_u_ratio_2022 as bb_actual_u,
		intnx('month', mdy(qtr(a.datadate) * 3, 1, year(a.datadate)), 0, 'e') as yearqtr format date9.
	from work.ciq1 a 
	left join work.bb1 b
		on a.gvkey = b.gvkey 
		and a.permno = b.permno 
		and a.ibes_ticker = b.ibes_ticker 
		and substr(a.cusip, 1, 8) = substr(b.cusip, 1, 8)
		and year(a.datadate) = year(b.datadate)
		and month(a.datadate) = month(b.datadate)
	order by gvkey, datadate;
quit;

*Merge Bloomberg following data. Read raw.bql_f directly because the
 prior proc import of BQL_F.dta is replaced by this raw read -- the
 .sas7bdat is what raw_data ships;
proc sql;
	create table work.bb3 as select distinct
		a.*,
		b.counteps as bb_following
	from work.bb2 a
	left join raw.bql_f b
		on a.bb_ticker_full = b.ticker_full
		and year(a.datadate) = year(datepart(b.dates))
		and month(a.datadate) = month(datepart(b.dates));
quit;

*Keep Bloomberg match with highest following;
proc sort data=work.bb3; 
	by gvkey datadate descending bb_following; 
run;

proc sort data=work.bb3 out=work.bb4 nodupkey; 
	by gvkey datadate; 
run;

/***************************************************************************
PART 6: CREATE BEST ANNOUNCEMENT DATE AND TIME
***************************************************************************/

data work.all_five1;
	format best_anndats date9.;
	set work.bb4;

	*Count how many sources agree with each announcement date;
	ibes_anndats_n = 1;
	if ibes_anndats = rdq then ibes_anndats_n + 1;
	if ibes_anndats = ciq_anndats then ibes_anndats_n + 1;
	if ibes_anndats = fset_anndats then ibes_anndats_n + 1;
	if ibes_anndats = zacks_anndats then ibes_anndats_n + 1;
	if missing(ibes_anndats) then ibes_anndats_n = 0;

	ciq_anndats_n = 1;
	if ciq_anndats = rdq then ciq_anndats_n + 1;
	if ciq_anndats = ibes_anndats then ciq_anndats_n + 1;
	if ciq_anndats = fset_anndats then ciq_anndats_n + 1;
	if ciq_anndats = zacks_anndats then ciq_anndats_n + 1;
	if missing(ciq_anndats) then ciq_anndats_n = 0;

	fset_anndats_n = 1;
	if fset_anndats = rdq then fset_anndats_n + 1;
	if fset_anndats = ciq_anndats then fset_anndats_n + 1;
	if fset_anndats = ibes_anndats then fset_anndats_n + 1;
	if fset_anndats = zacks_anndats then fset_anndats_n + 1;
	if missing(fset_anndats) then fset_anndats_n = 0;

	zacks_anndats_n = 1;
	if zacks_anndats = rdq then zacks_anndats_n + 1;
	if zacks_anndats = ciq_anndats then zacks_anndats_n + 1;
	if zacks_anndats = fset_anndats then zacks_anndats_n + 1;
	if zacks_anndats = ibes_anndats then zacks_anndats_n + 1;
	if missing(zacks_anndats) then zacks_anndats_n = 0;

	*Select best announcement date (prefer one that agrees with 3+ sources, else earliest);
	if ibes_anndats_n >= 3 then best_anndats = ibes_anndats;
	else if ciq_anndats_n >= 3 then best_anndats = ciq_anndats;
	else if fset_anndats_n >= 3 then best_anndats = fset_anndats;
	else if zacks_anndats_n >= 3 then best_anndats = zacks_anndats;
	else best_anndats = min(rdq, ibes_anndats, fset_anndats, ciq_anndats, zacks_anndats);

	ibes_anndats_best = (ibes_anndats = best_anndats);
	ciq_anndats_best = (ciq_anndats = best_anndats);
	fset_anndats_best = (fset_anndats = best_anndats);
	zacks_anndats_best = (zacks_anndats = best_anndats);
	rdq_anndats_best = (rdq = best_anndats);

	*Determine best announcement time from CIQ and IBES;
	ibes_anntime = dhms(ibes_anndats, 0, 0, ibes_anntims);
	ciq_anntime = dhms(ciq_anndats, 0, 0, ciq_anntims);
	format ibes_anntime ciq_anntime datetime.;

	if ibes_anndats_best = 1 and ciq_anndats_best = 1 then best_anntims = min(ibes_anntime, ciq_anntime);
	else if ibes_anndats_best = 1 and ciq_anndats_best = 0 then best_anntims = ibes_anntime;
	else if ibes_anndats_best = 0 and ciq_anndats_best = 1 then best_anntims = ciq_anntime;
	format best_anntims datetime.;

	*Adjust announcement date if after market hours;
	if hour(best_anntims) > 15 then best_anndats_adj = best_anndats + 1;
	else best_anndats_adj = best_anndats;
	format best_anndats_adj date9.;

	*Create surprise variables;
	ibes_surp_u = ibes_actual_u - ibes_mean_u;
	fset_surp_u = fset_actual_u - fset_mean_u;
	zacks_surp_u = zacks_actual_u - zacks_mean_u;
	ciq_surp_u = ciq_actual_u - ciq_mean_u;
	bb_surp_u = bb_actual_u - bb_mean_u;

	*Round all means, actuals, and surprises to 0.01;
	array myvars(*) ibes_actual: ibes_mean: ibes_surp: zacks_actual: zacks_mean: zacks_surp: 
					ciq_actual: ciq_mean: ciq_surp: bb_actual: bb_mean: bb_surp: 
					fset_actual: fset_mean: fset_surp:;
	do i = 1 to dim(myvars);
		if not missing(myvars(i)) then myvars(i) = round(myvars(i), 0.01);
	end;
	drop i;
run;

/***************************************************************************
PART 7: OBTAIN PRICE TWO TRADING DAYS PRIOR TO EA DATE
***************************************************************************/

proc sql;
	create table work.dates as select distinct date
	from raw.dsf_07172025
	order by date;
quit;

data work.crspdates;
	set work.dates;
	n = _n_;
run;

%tddays(dsetin=work.all_five1 (keep=gvkey permno datadate rdq best_anndats_adj), 
		dsetout=work.temp1, 
		datevar=best_anndats_adj,
		beginwin=-2,
		endwin=-2,
		calendarname=work.crspdates);

proc sql;
	create table work.temp2 as select 
		a.*, 
		abs(b.prc) as prcn2 'Share Price at day -2 Relative to EA Date'
	from work.temp1 as a 
	left join raw.dsf_07172025 as b
		on a.permno = b.permno and a.date = b.date;
quit;

proc sql;
	create table work.all_five2 as select distinct
		a.*, 
		b.prcn2
	from work.all_five1 a 
	left join work.temp2 b
		on a.gvkey = b.gvkey and a.datadate = b.datadate;
quit;

/***************************************************************************
PART 8: CREATE DERIVED VARIABLES
***************************************************************************/

data work.all_five3;
	set work.all_five2;

	*Scale surprise by price;
	ibes_surp_u_price = ibes_surp_u / prcn2;
	fset_surp_u_price = fset_surp_u / prcn2;
	zacks_surp_u_price = zacks_surp_u / prcn2;
	ciq_surp_u_price = ciq_surp_u / prcn2;
	bb_surp_u_price = bb_surp_u / prcn2;

	*Max, min, and std dev of surprise across FDPs;
	max_surp = max(ibes_surp_u, bb_surp_u, ciq_surp_u, fset_surp_u, zacks_surp_u);
	min_surp = min(ibes_surp_u, bb_surp_u, ciq_surp_u, fset_surp_u, zacks_surp_u);
	max_min_surp = max_surp - min_surp;
	std_dev_surp = std(ibes_surp_u, bb_surp_u, ciq_surp_u, fset_surp_u, zacks_surp_u);
	max_min_surp_price = max_min_surp / prcn2;
	std_dev_surp_price = std_dev_surp / prcn2;

	*Beat and miss indicators;
	if min_surp = . then at_least_one_miss = 0;
	else if min_surp <= -0.015 then at_least_one_miss = 1;
	else at_least_one_miss = 0;

	if max_surp = . then at_least_one_beat = 0;
	else if max_surp >= 0.015 then at_least_one_beat = 1;
	else at_least_one_beat = 0;

	if at_least_one_miss = 1 and at_least_one_beat = 1 then miss_and_beat_mbe_2 = 1; 
	else miss_and_beat_mbe_2 = 0;
run;

/***************************************************************************
PART 9: COUNT UNIQUE ANALYST FOLLOWING ACROSS FDPS
***************************************************************************/

data work.following_long;
	set work.all_five3;
	
	if ibes_following ne . then do; following = ibes_following; output; end;
	if fset_following ne . then do; following = fset_following; output; end;
	if zacks_following ne . then do; following = zacks_following; output; end;
	if ciq_following ne . then do; following = ciq_following; output; end;
	if bb_following ne . then do; following = bb_following; output; end;
	
	keep gvkey datadate following;
run;

proc sort data=work.following_long nodupkey;
	by gvkey datadate following;
run;

proc means data=work.following_long noprint;
	var following;
	output out=work.follow_unique n=unique_following;
	by gvkey datadate;
run;

proc sql;
	create table work.all_five4 as select distinct
		a.*, 
		b.unique_following 
	from work.all_five3 a 
	left join work.follow_unique b
		on a.gvkey = b.gvkey and a.datadate = b.datadate;
quit;

/***************************************************************************
PART 10: CREATE CONSISTENT COVERAGE INDICATORS AND SAVE
Coverage is defined as having a mean forecast (mean_a) for each FDP
***************************************************************************/

data data.all_five1;
	set work.all_five4;
	
	*Define coverage consistently as having a mean forecast (mean_a);
	ibes_covered = (not missing(ibes_mean_a));
	fset_covered = (not missing(fset_mean_a));
	zacks_covered = (not missing(zacks_mean_a));
	ciq_covered = (not missing(ciq_mean_a));
	bb_covered = (not missing(bb_mean_a));
run;

*Signoff only if we signed on at the top. Wrapped in a macro because
 calling %maybe_download / %maybe_iclink earlier left SAS's open-code
 %if state confused enough that a bare %if here gets ignored;
%macro maybe_signoff;
  %if &need_wrds = 1 %then %do;
    signoff;
  %end;
%mend;
%maybe_signoff;

