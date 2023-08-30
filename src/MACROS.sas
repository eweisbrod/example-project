


****************************Trading Days Macro ***********************************;

/**********************************************************************************************/
/* FILENAME:        tddays.sas                                                    			  */
/* ORIGINAL AUTHOR: Eric Weisbrod						                                      */
/* MODIFIED BY:            													                  */
/* DATE CREATED:    Feb 22, 2021                                                              */
/* LAST MODIFIED:   Feb 22, 2021                                                              */
/* MACRO NAME:      tddays			                                                          */
/* ARGUMENTS:       1) DSETIN: input dataset containing an event date.					      */
/*                  2) DSETOUT: output dataset 									              */
/*                  3) BEGINWIN: first trading day relative to the event to collect 		  */
/*                  4) ENDWIN: last trading day relative to the event to collect              */
/*                  5) DATEVAR: variable name of the date in dsetin to use as the event date  */
/*                																			  */
/*                                        												      */
/* DESCRIPTION:     This macro uses a crsp trading date calendar to look up the event date and*/
/*					output a long (tidy) dataset of trading dates relative to the event date. */
/*					The output dataset can be used to then link returns, etc. The macro will  */
/*					give an error if the collection window includes dates that are beyond the */
/*					last available date of CRSP data available. 							  */
/* EXAMPLE(S):      1) %tddays(dsetin = mydata, dsetout = mydata2, datevar = rdq,			  */	
/*							beginwin=-1,endwin=1);									 	      */       
/*                      ==> Collect [-1,1] trading day windows around compustat quarterly 	  */
/*							earnings announcement date.	Helps to have permno already linked.  */
/**********************************************************************************************/

/* Code for how the trading date calendar is created*/

/*
proc sql;
create table dates as select distinct
date
from mycrsp.dsf
order by date;
quit;


data mycrsp.crspdates;
set dates;
n=_n_;
run;
*/



%macro tddays(dsetin=, dsetout=, datevar=, beginwin=0, endwin=0, calendarname=home.crspdates);

*enter a failsafe for out of range dates;
proc sql noprint;
select max(date)
  into :max_dt trimmed
  from &calendarname
;
quit;

data &dsetout (drop=rc n key);
format date YYMMDDN8.;
*instead of one hash we can do two hashes from the same crspdates set, 
one hash will be to match the eventdate, second hash will iterate through the event window;
declare hash nhash(dataset: "&calendarname", multidata:'no');
nhash.DefineKey("n");
nhash.DefineData("n","date");
nhash.DefineDone();
*see this hash is called datehash but uses same dataset;
declare hash datehash(dataset: "&calendarname", multidata:'no');
datehash.DefineKey("date");
datehash.DefineData("n","date");
datehash.DefineDone();

do until(eof);
	set &dsetin end = eof;
	format &datevar  YYMMDDN8.;
	key = 0;
	date = &datevar;
	td_days = %eval(&beginwin);
	rc=1;
	n_evtdate = .;
	n_days = .;

	*look up the event date;
	if not missing(&datevar) then do;
		do until(rc=0);
			rc=datehash.find();
			*if the date does not fall on a trading day,
			look at the next day, the loop will iterate until the date matches a trading day;
			if rc ^= 0 then do;
				date = INTNX("DAY",date,1);
				if date > &max_dt then do;
					put "Error: Date out of Range";
					stop;
				end;
			end;
			else do;
				n_evtdate = n;

			end;
		end;
	end;



	*now use the index of the event day in the trading calendar to find the begin and end days;
	n_days = ((n_evtdate+%eval(&endwin)) - (n_evtdate+%eval(&beginwin))) + 1;
	*if there is more than one day, output them all;
	if n_days > 1 then do;
		n = .;
		do key= (n_evtdate+%eval(&beginwin)) to (n_evtdate+%eval(&endwin)) by 1;

			n = .;
			n = key;
			date=.;
			rc=nhash.find();
			output;
			td_days +1;
		end;
	end;
	*If there is only one day, just look up that one;
	else do;
		key= (n_evtdate+%eval(&beginwin));
		n = key;
		date=.;
		rc=nhash.find();
		output;
	end;


end;
run;


%mend;

%put Trading Days Macro Loaded;


/******************************************************************************************/


**************************** Winsorize Macro ***********************************;

/**********************************************************************************************/
/* FILENAME:        Winsorize_Truncate.sas                                                    */
/* ORIGINAL AUTHOR: Steve Stubben (Stanford University)                                       */
/* MODIFIED BY:     Emmanuel De George and Atif Ellahie (LBS)			                                              */
/* DATE CREATED:    October 3, 2012                                                           */
/* LAST MODIFIED:   October 3, 2012                                                           */
/* MACRO NAME:      winsor			                                                          */
/* ARGUMENTS:       1) DSETIN: input dataset containing variables that will be win/trunc.     */
/*                  2) DSETOUT: output dataset (leave blank to overwrite DSETIN)              */
/*                  3) BYVAR: variable(s) used to form groups (leave blank for total sample)  */
/*                  4) VARS: variable(s) that will be winsorized/truncated                    */
/*                  5) TYPE: = W to winsorize and = T (or anything else) to truncate          */
/*                  6) PCTL = percentile points (in ascending order) to truncate/winsorize    */
/*                            values.  Default is 1st and 99th percentiles.                   */
/* DESCRIPTION:     This macro is capable of both truncating and winsorizing one or multiple  */
/*                  variables.  Truncated values are replaced with a missing observation      */
/*                  rather than deleting the observation.  This gives the user more control   */
/*                  over the resulting dataset.                                               */
/* EXAMPLE(S):      1) %winsor(dsetin = mydata, dsetout = mydata2, byvar = year,  			  */
/*                          vars = assets earnings, type = W, pctl = 0 98)                    */
/*                      ==> Winsorizes by year at 98% and puts resulting dataset into mydata2 */
/**********************************************************************************************/

%macro winsor	(dsetin = , 
			dsetout = , 
			byvar = none, 
			vars = , 
			type = W, 
			pctl = 1 99);
	%if &dsetout = %then
		%let dsetout = &dsetin;
	%let varL=;
	%let varH=;
	%let xn=1;

	%do %until (%scan(&vars,&xn)= );
		%let token = %scan(&vars,&xn);
		%let varL = &varL &token.L;
		%let varH = &varH &token.H;
		%let xn = %EVAL(&xn + 1);
	%end;

	%let xn = %eval(&xn-1);

	data xtemp;
		set &dsetin;
		%let dropvar =;

		%if &byvar = none %then
			%do;

	data xtemp;
		set xtemp;
		xbyvar = 1;
		%let byvar = xbyvar;
		%let dropvar = xbyvar;
			%end;

	proc sort data = xtemp;
		by &byvar;

		/*compute percentage cutoff values*/
	proc univariate data = xtemp noprint;
		by &byvar;
		var &vars;
		output out = xtemp_pctl PCTLPTS = &pctl PCTLPRE = &vars PCTLNAME = L H;

	data &dsetout;
		merge xtemp xtemp_pctl; /*merge percentage cutoff values into main dataset*/
		by &byvar;
		array trimvars{&xn} &vars;
		array trimvarl{&xn} &varL;
		array trimvarh{&xn} &varH;

		do xi = 1 to dim(trimvars);
			/*winsorize variables*/
			%if &type = W %then
				%do;
					if trimvars{xi} ne . then
						do;
							if (trimvars{xi} < trimvarl{xi}) then
								trimvars{xi} = trimvarl{xi};

							if (trimvars{xi} > trimvarh{xi}) then
								trimvars{xi} = trimvarh{xi};
						end;
				%end;

			/*truncate variables*/
			%else
				%do;
					if trimvars{xi} ne . then
						do;
							/*insert .T code if value is truncated*/
							if (trimvars{xi} < trimvarl{xi}) then
								trimvars{xi} = .T;

							if (trimvars{xi} > trimvarh{xi}) then
								trimvars{xi} = .T;
						end;
				%end;
		end;

		drop &varL &varH &dropvar xi;

		/*delete temporary datasets created during macro execution*/
	proc datasets library=work nolist;
		*delete xtemp xtemp_pctl;
	quit;

	run;

%mend winsor;


%put WINSOR macro loaded;



*# Fama French industry classification ;
* macro borrowed from https://github.com/JoostImpink/fama-french-industry/tree/master/SAS;
* Fama French 12 industry;
%macro ff12(dsin=, dsout=, sicvar=, varname=);

	data &dsout;
	set &dsin;
	
	/* industry assignments */
	if ( &sicvar ge 0100 and &sicvar le 0999) or ( &sicvar ge 2000 and &sicvar le 2399) or ( &sicvar ge 2700 and &sicvar le 2749) or ( &sicvar ge 2770 and &sicvar le 2799) or ( &sicvar ge 3100 and &sicvar le 3199) or ( &sicvar ge 3940 and &sicvar le 3989) then &varname= 1;
	if ( &sicvar ge 2500 and &sicvar le 2519) or ( &sicvar ge 2590 and &sicvar le 2599) or ( &sicvar ge 3630 and &sicvar le 3659) or ( &sicvar ge 3710 and &sicvar le 3711) or ( &sicvar ge 3714 and &sicvar le 3714) or ( &sicvar ge 3716 and &sicvar le 3716) or ( &sicvar ge 3750 and &sicvar le 3751) or ( &sicvar ge 3792 and &sicvar le 3792) or ( &sicvar ge 3900 and &sicvar le 3939) or ( &sicvar ge 3990 and &sicvar le 3999) then &varname= 2;
	if ( &sicvar ge 2520 and &sicvar le 2589) or ( &sicvar ge 2600 and &sicvar le 2699) or ( &sicvar ge 2750 and &sicvar le 2769) or ( &sicvar ge 3000 and &sicvar le 3099) or ( &sicvar ge 3200 and &sicvar le 3569) or ( &sicvar ge 3580 and &sicvar le 3629) or ( &sicvar ge 3700 and &sicvar le 3709) or ( &sicvar ge 3712 and &sicvar le 3713) or ( &sicvar ge 3715 and &sicvar le 3715) or ( &sicvar ge 3717 and &sicvar le 3749) or ( &sicvar ge 3752 and &sicvar le 3791) or ( &sicvar ge 3793 and &sicvar le 3799) or ( &sicvar ge 3830 and &sicvar le 3839) or ( &sicvar ge 3860 and &sicvar le 3899) then &varname= 3;
	if ( &sicvar ge 1200 and &sicvar le 1399) or ( &sicvar ge 2900 and &sicvar le 2999) then &varname= 4;
	if ( &sicvar ge 2800 and &sicvar le 2829) or ( &sicvar ge 2840 and &sicvar le 2899) then &varname= 5;
	if ( &sicvar ge 3570 and &sicvar le 3579) or ( &sicvar ge 3660 and &sicvar le 3692) or ( &sicvar ge 3694 and &sicvar le 3699) or ( &sicvar ge 3810 and &sicvar le 3829) or ( &sicvar ge 7370 and &sicvar le 7379) then &varname= 6;
	if ( &sicvar ge 4800 and &sicvar le 4899) then &varname= 7;
	if ( &sicvar ge 4900 and &sicvar le 4949) then &varname= 8;
	if ( &sicvar ge 5000 and &sicvar le 5999) or ( &sicvar ge 7200 and &sicvar le 7299) or ( &sicvar ge 7600 and &sicvar le 7699) then &varname= 9;
	if ( &sicvar ge 2830 and &sicvar le 2839) or ( &sicvar ge 3693 and &sicvar le 3693) or ( &sicvar ge 3840 and &sicvar le 3859) or ( &sicvar ge 8000 and &sicvar le 8099) then &varname=10;
	if ( &sicvar ge 6000 and &sicvar le 6999) then &varname=11;

	/*  Fama french siccodes file does not include industry codes for 'other'
		Set it to 12 (i.e. 'other') if not yet set
	 */
	if &varname eq . then &varname = 12;
	run;

%mend;

%put FF12 Macro Loaded;

* Fama French 49 industry;

%macro ff49(dsin=, dsout=, sicvar=, varname=);

	data &dsout;
	set &dsin;
	
	/* industry assignments */
	if ( &sicvar ge 0100 and &sicvar le 0199) or ( &sicvar ge 0200 and &sicvar le 0299) or ( &sicvar ge 0700 and &sicvar le 0799) or ( &sicvar ge 0910 and &sicvar le 0919) or ( &sicvar ge 2048 and &sicvar le 2048) then &varname= 1;
	if ( &sicvar ge 2000 and &sicvar le 2009) or ( &sicvar ge 2010 and &sicvar le 2019) or ( &sicvar ge 2020 and &sicvar le 2029) or ( &sicvar ge 2030 and &sicvar le 2039) or ( &sicvar ge 2040 and &sicvar le 2046) or ( &sicvar ge 2050 and &sicvar le 2059) or ( &sicvar ge 2060 and &sicvar le 2063) or ( &sicvar ge 2070 and &sicvar le 2079) or ( &sicvar ge 2090 and &sicvar le 2092) or ( &sicvar ge 2095 and &sicvar le 2095) or ( &sicvar ge 2098 and &sicvar le 2099) then &varname= 2;
	if ( &sicvar ge 2064 and &sicvar le 2068) or ( &sicvar ge 2086 and &sicvar le 2086) or ( &sicvar ge 2087 and &sicvar le 2087) or ( &sicvar ge 2096 and &sicvar le 2096) or ( &sicvar ge 2097 and &sicvar le 2097) then &varname= 3;
	if ( &sicvar ge 2080 and &sicvar le 2080) or ( &sicvar ge 2082 and &sicvar le 2082) or ( &sicvar ge 2083 and &sicvar le 2083) or ( &sicvar ge 2084 and &sicvar le 2084) or ( &sicvar ge 2085 and &sicvar le 2085) then &varname= 4;
	if ( &sicvar ge 2100 and &sicvar le 2199) then &varname= 5;
	if ( &sicvar ge 0920 and &sicvar le 0999) or ( &sicvar ge 3650 and &sicvar le 3651) or ( &sicvar ge 3652 and &sicvar le 3652) or ( &sicvar ge 3732 and &sicvar le 3732) or ( &sicvar ge 3930 and &sicvar le 3931) or ( &sicvar ge 3940 and &sicvar le 3949) then &varname= 6;
	if ( &sicvar ge 7800 and &sicvar le 7829) or ( &sicvar ge 7830 and &sicvar le 7833) or ( &sicvar ge 7840 and &sicvar le 7841) or ( &sicvar ge 7900 and &sicvar le 7900) or ( &sicvar ge 7910 and &sicvar le 7911) or ( &sicvar ge 7920 and &sicvar le 7929) or ( &sicvar ge 7930 and &sicvar le 7933) or ( &sicvar ge 7940 and &sicvar le 7949) or ( &sicvar ge 7980 and &sicvar le 7980) or ( &sicvar ge 7990 and &sicvar le 7999) then &varname= 7;
	if ( &sicvar ge 2700 and &sicvar le 2709) or ( &sicvar ge 2710 and &sicvar le 2719) or ( &sicvar ge 2720 and &sicvar le 2729) or ( &sicvar ge 2730 and &sicvar le 2739) or ( &sicvar ge 2740 and &sicvar le 2749) or ( &sicvar ge 2770 and &sicvar le 2771) or ( &sicvar ge 2780 and &sicvar le 2789) or ( &sicvar ge 2790 and &sicvar le 2799) then &varname= 8;
	if ( &sicvar ge 2047 and &sicvar le 2047) or ( &sicvar ge 2391 and &sicvar le 2392) or ( &sicvar ge 2510 and &sicvar le 2519) or ( &sicvar ge 2590 and &sicvar le 2599) or ( &sicvar ge 2840 and &sicvar le 2843) or ( &sicvar ge 2844 and &sicvar le 2844) or ( &sicvar ge 3160 and &sicvar le 3161) or ( &sicvar ge 3170 and &sicvar le 3171) or ( &sicvar ge 3172 and &sicvar le 3172) or ( &sicvar ge 3190 and &sicvar le 3199) or ( &sicvar ge 3229 and &sicvar le 3229) or ( &sicvar ge 3260 and &sicvar le 3260) or ( &sicvar ge 3262 and &sicvar le 3263) or ( &sicvar ge 3269 and &sicvar le 3269) or ( &sicvar ge 3230 and &sicvar le 3231) or ( &sicvar ge 3630 and &sicvar le 3639) or ( &sicvar ge 3750 and &sicvar le 3751) or ( &sicvar ge 3800 and &sicvar le 3800) or ( &sicvar ge 3860 and &sicvar le 3861) or ( &sicvar ge 3870 and &sicvar le 3873) or ( &sicvar ge 3910 and &sicvar le 3911) or ( &sicvar ge 3914 and &sicvar le 3914) or ( &sicvar ge 3915 and &sicvar le 3915) or ( &sicvar ge 3960 and &sicvar le 3962) or ( &sicvar ge 3991 and &sicvar le 3991) or ( &sicvar ge 3995 and &sicvar le 3995) then &varname= 9;
	if ( &sicvar ge 2300 and &sicvar le 2390) or ( &sicvar ge 3020 and &sicvar le 3021) or ( &sicvar ge 3100 and &sicvar le 3111) or ( &sicvar ge 3130 and &sicvar le 3131) or ( &sicvar ge 3140 and &sicvar le 3149) or ( &sicvar ge 3150 and &sicvar le 3151) or ( &sicvar ge 3963 and &sicvar le 3965) then &varname=10;
	if ( &sicvar ge 8000 and &sicvar le 8099) then &varname=11;
	if ( &sicvar ge 3693 and &sicvar le 3693) or ( &sicvar ge 3840 and &sicvar le 3849) or ( &sicvar ge 3850 and &sicvar le 3851) then &varname=12;
	if ( &sicvar ge 2830 and &sicvar le 2830) or ( &sicvar ge 2831 and &sicvar le 2831) or ( &sicvar ge 2833 and &sicvar le 2833) or ( &sicvar ge 2834 and &sicvar le 2834) or ( &sicvar ge 2835 and &sicvar le 2835) or ( &sicvar ge 2836 and &sicvar le 2836) then &varname=13;
	if ( &sicvar ge 2800 and &sicvar le 2809) or ( &sicvar ge 2810 and &sicvar le 2819) or ( &sicvar ge 2820 and &sicvar le 2829) or ( &sicvar ge 2850 and &sicvar le 2859) or ( &sicvar ge 2860 and &sicvar le 2869) or ( &sicvar ge 2870 and &sicvar le 2879) or ( &sicvar ge 2890 and &sicvar le 2899) then &varname=14;
	if ( &sicvar ge 3031 and &sicvar le 3031) or ( &sicvar ge 3041 and &sicvar le 3041) or ( &sicvar ge 3050 and &sicvar le 3053) or ( &sicvar ge 3060 and &sicvar le 3069) or ( &sicvar ge 3070 and &sicvar le 3079) or ( &sicvar ge 3080 and &sicvar le 3089) or ( &sicvar ge 3090 and &sicvar le 3099) then &varname=15;
	if ( &sicvar ge 2200 and &sicvar le 2269) or ( &sicvar ge 2270 and &sicvar le 2279) or ( &sicvar ge 2280 and &sicvar le 2284) or ( &sicvar ge 2290 and &sicvar le 2295) or ( &sicvar ge 2297 and &sicvar le 2297) or ( &sicvar ge 2298 and &sicvar le 2298) or ( &sicvar ge 2299 and &sicvar le 2299) or ( &sicvar ge 2393 and &sicvar le 2395) or ( &sicvar ge 2397 and &sicvar le 2399) then &varname=16;
	if ( &sicvar ge 0800 and &sicvar le 0899) or ( &sicvar ge 2400 and &sicvar le 2439) or ( &sicvar ge 2450 and &sicvar le 2459) or ( &sicvar ge 2490 and &sicvar le 2499) or ( &sicvar ge 2660 and &sicvar le 2661) or ( &sicvar ge 2950 and &sicvar le 2952) or ( &sicvar ge 3200 and &sicvar le 3200) or ( &sicvar ge 3210 and &sicvar le 3211) or ( &sicvar ge 3240 and &sicvar le 3241) or ( &sicvar ge 3250 and &sicvar le 3259) or ( &sicvar ge 3261 and &sicvar le 3261) or ( &sicvar ge 3264 and &sicvar le 3264) or ( &sicvar ge 3270 and &sicvar le 3275) or ( &sicvar ge 3280 and &sicvar le 3281) or ( &sicvar ge 3290 and &sicvar le 3293) or ( &sicvar ge 3295 and &sicvar le 3299) or ( &sicvar ge 3420 and &sicvar le 3429) or ( &sicvar ge 3430 and &sicvar le 3433) or ( &sicvar ge 3440 and &sicvar le 3441) or ( &sicvar ge 3442 and &sicvar le 3442) or ( &sicvar ge 3446 and &sicvar le 3446) or ( &sicvar ge 3448 and &sicvar le 3448) or ( &sicvar ge 3449 and &sicvar le 3449) or ( &sicvar ge 3450 and &sicvar le 3451) or ( &sicvar ge 3452 and &sicvar le 3452) or ( &sicvar ge 3490 and &sicvar le 3499) or ( &sicvar ge 3996 and &sicvar le 3996) then &varname=17;
	if ( &sicvar ge 1500 and &sicvar le 1511) or ( &sicvar ge 1520 and &sicvar le 1529) or ( &sicvar ge 1530 and &sicvar le 1539) or ( &sicvar ge 1540 and &sicvar le 1549) or ( &sicvar ge 1600 and &sicvar le 1699) or ( &sicvar ge 1700 and &sicvar le 1799) then &varname=18;
	if ( &sicvar ge 3300 and &sicvar le 3300) or ( &sicvar ge 3310 and &sicvar le 3317) or ( &sicvar ge 3320 and &sicvar le 3325) or ( &sicvar ge 3330 and &sicvar le 3339) or ( &sicvar ge 3340 and &sicvar le 3341) or ( &sicvar ge 3350 and &sicvar le 3357) or ( &sicvar ge 3360 and &sicvar le 3369) or ( &sicvar ge 3370 and &sicvar le 3379) or ( &sicvar ge 3390 and &sicvar le 3399) then &varname=19;
	if ( &sicvar ge 3400 and &sicvar le 3400) or ( &sicvar ge 3443 and &sicvar le 3443) or ( &sicvar ge 3444 and &sicvar le 3444) or ( &sicvar ge 3460 and &sicvar le 3469) or ( &sicvar ge 3470 and &sicvar le 3479) then &varname=20;
	if ( &sicvar ge 3510 and &sicvar le 3519) or ( &sicvar ge 3520 and &sicvar le 3529) or ( &sicvar ge 3530 and &sicvar le 3530) or ( &sicvar ge 3531 and &sicvar le 3531) or ( &sicvar ge 3532 and &sicvar le 3532) or ( &sicvar ge 3533 and &sicvar le 3533) or ( &sicvar ge 3534 and &sicvar le 3534) or ( &sicvar ge 3535 and &sicvar le 3535) or ( &sicvar ge 3536 and &sicvar le 3536) or ( &sicvar ge 3538 and &sicvar le 3538) or ( &sicvar ge 3540 and &sicvar le 3549) or ( &sicvar ge 3550 and &sicvar le 3559) or ( &sicvar ge 3560 and &sicvar le 3569) or ( &sicvar ge 3580 and &sicvar le 3580) or ( &sicvar ge 3581 and &sicvar le 3581) or ( &sicvar ge 3582 and &sicvar le 3582) or ( &sicvar ge 3585 and &sicvar le 3585) or ( &sicvar ge 3586 and &sicvar le 3586) or ( &sicvar ge 3589 and &sicvar le 3589) or ( &sicvar ge 3590 and &sicvar le 3599) then &varname=21;
	if ( &sicvar ge 3600 and &sicvar le 3600) or ( &sicvar ge 3610 and &sicvar le 3613) or ( &sicvar ge 3620 and &sicvar le 3621) or ( &sicvar ge 3623 and &sicvar le 3629) or ( &sicvar ge 3640 and &sicvar le 3644) or ( &sicvar ge 3645 and &sicvar le 3645) or ( &sicvar ge 3646 and &sicvar le 3646) or ( &sicvar ge 3648 and &sicvar le 3649) or ( &sicvar ge 3660 and &sicvar le 3660) or ( &sicvar ge 3690 and &sicvar le 3690) or ( &sicvar ge 3691 and &sicvar le 3692) or ( &sicvar ge 3699 and &sicvar le 3699) then &varname=22;
	if ( &sicvar ge 2296 and &sicvar le 2296) or ( &sicvar ge 2396 and &sicvar le 2396) or ( &sicvar ge 3010 and &sicvar le 3011) or ( &sicvar ge 3537 and &sicvar le 3537) or ( &sicvar ge 3647 and &sicvar le 3647) or ( &sicvar ge 3694 and &sicvar le 3694) or ( &sicvar ge 3700 and &sicvar le 3700) or ( &sicvar ge 3710 and &sicvar le 3710) or ( &sicvar ge 3711 and &sicvar le 3711) or ( &sicvar ge 3713 and &sicvar le 3713) or ( &sicvar ge 3714 and &sicvar le 3714) or ( &sicvar ge 3715 and &sicvar le 3715) or ( &sicvar ge 3716 and &sicvar le 3716) or ( &sicvar ge 3792 and &sicvar le 3792) or ( &sicvar ge 3790 and &sicvar le 3791) or ( &sicvar ge 3799 and &sicvar le 3799) then &varname=23;
	if ( &sicvar ge 3720 and &sicvar le 3720) or ( &sicvar ge 3721 and &sicvar le 3721) or ( &sicvar ge 3723 and &sicvar le 3724) or ( &sicvar ge 3725 and &sicvar le 3725) or ( &sicvar ge 3728 and &sicvar le 3729) then &varname=24;
	if ( &sicvar ge 3730 and &sicvar le 3731) or ( &sicvar ge 3740 and &sicvar le 3743) then &varname=25;
	if ( &sicvar ge 3760 and &sicvar le 3769) or ( &sicvar ge 3795 and &sicvar le 3795) or ( &sicvar ge 3480 and &sicvar le 3489) then &varname=26;
	if ( &sicvar ge 1040 and &sicvar le 1049) then &varname=27;
	if ( &sicvar ge 1000 and &sicvar le 1009) or ( &sicvar ge 1010 and &sicvar le 1019) or ( &sicvar ge 1020 and &sicvar le 1029) or ( &sicvar ge 1030 and &sicvar le 1039) or ( &sicvar ge 1050 and &sicvar le 1059) or ( &sicvar ge 1060 and &sicvar le 1069) or ( &sicvar ge 1070 and &sicvar le 1079) or ( &sicvar ge 1080 and &sicvar le 1089) or ( &sicvar ge 1090 and &sicvar le 1099) or ( &sicvar ge 1100 and &sicvar le 1119) or ( &sicvar ge 1400 and &sicvar le 1499) then &varname=28;
	if ( &sicvar ge 1200 and &sicvar le 1299) then &varname=29;
	if ( &sicvar ge 1300 and &sicvar le 1300) or ( &sicvar ge 1310 and &sicvar le 1319) or ( &sicvar ge 1320 and &sicvar le 1329) or ( &sicvar ge 1330 and &sicvar le 1339) or ( &sicvar ge 1370 and &sicvar le 1379) or ( &sicvar ge 1380 and &sicvar le 1380) or ( &sicvar ge 1381 and &sicvar le 1381) or ( &sicvar ge 1382 and &sicvar le 1382) or ( &sicvar ge 1389 and &sicvar le 1389) or ( &sicvar ge 2900 and &sicvar le 2912) or ( &sicvar ge 2990 and &sicvar le 2999) then &varname=30;
	if ( &sicvar ge 4900 and &sicvar le 4900) or ( &sicvar ge 4910 and &sicvar le 4911) or ( &sicvar ge 4920 and &sicvar le 4922) or ( &sicvar ge 4923 and &sicvar le 4923) or ( &sicvar ge 4924 and &sicvar le 4925) or ( &sicvar ge 4930 and &sicvar le 4931) or ( &sicvar ge 4932 and &sicvar le 4932) or ( &sicvar ge 4939 and &sicvar le 4939) or ( &sicvar ge 4940 and &sicvar le 4942) then &varname=31;
	if ( &sicvar ge 4800 and &sicvar le 4800) or ( &sicvar ge 4810 and &sicvar le 4813) or ( &sicvar ge 4820 and &sicvar le 4822) or ( &sicvar ge 4830 and &sicvar le 4839) or ( &sicvar ge 4840 and &sicvar le 4841) or ( &sicvar ge 4880 and &sicvar le 4889) or ( &sicvar ge 4890 and &sicvar le 4890) or ( &sicvar ge 4891 and &sicvar le 4891) or ( &sicvar ge 4892 and &sicvar le 4892) or ( &sicvar ge 4899 and &sicvar le 4899) then &varname=32;
	if ( &sicvar ge 7020 and &sicvar le 7021) or ( &sicvar ge 7030 and &sicvar le 7033) or ( &sicvar ge 7200 and &sicvar le 7200) or ( &sicvar ge 7210 and &sicvar le 7212) or ( &sicvar ge 7214 and &sicvar le 7214) or ( &sicvar ge 7215 and &sicvar le 7216) or ( &sicvar ge 7217 and &sicvar le 7217) or ( &sicvar ge 7219 and &sicvar le 7219) or ( &sicvar ge 7220 and &sicvar le 7221) or ( &sicvar ge 7230 and &sicvar le 7231) or ( &sicvar ge 7240 and &sicvar le 7241) or ( &sicvar ge 7250 and &sicvar le 7251) or ( &sicvar ge 7260 and &sicvar le 7269) or ( &sicvar ge 7270 and &sicvar le 7290) or ( &sicvar ge 7291 and &sicvar le 7291) or ( &sicvar ge 7292 and &sicvar le 7299) or ( &sicvar ge 7395 and &sicvar le 7395) or ( &sicvar ge 7500 and &sicvar le 7500) or ( &sicvar ge 7520 and &sicvar le 7529) or ( &sicvar ge 7530 and &sicvar le 7539) or ( &sicvar ge 7540 and &sicvar le 7549) or ( &sicvar ge 7600 and &sicvar le 7600) or ( &sicvar ge 7620 and &sicvar le 7620) or ( &sicvar ge 7622 and &sicvar le 7622) or ( &sicvar ge 7623 and &sicvar le 7623) or ( &sicvar ge 7629 and &sicvar le 7629) or ( &sicvar ge 7630 and &sicvar le 7631) or ( &sicvar ge 7640 and &sicvar le 7641) or ( &sicvar ge 7690 and &sicvar le 7699) or ( &sicvar ge 8100 and &sicvar le 8199) or ( &sicvar ge 8200 and &sicvar le 8299) or ( &sicvar ge 8300 and &sicvar le 8399) or ( &sicvar ge 8400 and &sicvar le 8499) or ( &sicvar ge 8600 and &sicvar le 8699) or ( &sicvar ge 8800 and &sicvar le 8899) or ( &sicvar ge 7510 and &sicvar le 7515) then &varname=33;
	if ( &sicvar ge 2750 and &sicvar le 2759) or ( &sicvar ge 3993 and &sicvar le 3993) or ( &sicvar ge 7218 and &sicvar le 7218) or ( &sicvar ge 7300 and &sicvar le 7300) or ( &sicvar ge 7310 and &sicvar le 7319) or ( &sicvar ge 7320 and &sicvar le 7329) or ( &sicvar ge 7330 and &sicvar le 7339) or ( &sicvar ge 7340 and &sicvar le 7342) or ( &sicvar ge 7349 and &sicvar le 7349) or ( &sicvar ge 7350 and &sicvar le 7351) or ( &sicvar ge 7352 and &sicvar le 7352) or ( &sicvar ge 7353 and &sicvar le 7353) or ( &sicvar ge 7359 and &sicvar le 7359) or ( &sicvar ge 7360 and &sicvar le 7369) or ( &sicvar ge 7374 and &sicvar le 7374) or ( &sicvar ge 7376 and &sicvar le 7376) or ( &sicvar ge 7377 and &sicvar le 7377) or ( &sicvar ge 7378 and &sicvar le 7378) or ( &sicvar ge 7379 and &sicvar le 7379) or ( &sicvar ge 7380 and &sicvar le 7380) or ( &sicvar ge 7381 and &sicvar le 7382) or ( &sicvar ge 7383 and &sicvar le 7383) or ( &sicvar ge 7384 and &sicvar le 7384) or ( &sicvar ge 7385 and &sicvar le 7385) or ( &sicvar ge 7389 and &sicvar le 7390) or ( &sicvar ge 7391 and &sicvar le 7391) or ( &sicvar ge 7392 and &sicvar le 7392) or ( &sicvar ge 7393 and &sicvar le 7393) or ( &sicvar ge 7394 and &sicvar le 7394) or ( &sicvar ge 7396 and &sicvar le 7396) or ( &sicvar ge 7397 and &sicvar le 7397) or ( &sicvar ge 7399 and &sicvar le 7399) or ( &sicvar ge 7519 and &sicvar le 7519) or ( &sicvar ge 8700 and &sicvar le 8700) or ( &sicvar ge 8710 and &sicvar le 8713) or ( &sicvar ge 8720 and &sicvar le 8721) or ( &sicvar ge 8730 and &sicvar le 8734) or ( &sicvar ge 8740 and &sicvar le 8748) or ( &sicvar ge 8900 and &sicvar le 8910) or ( &sicvar ge 8911 and &sicvar le 8911) or ( &sicvar ge 8920 and &sicvar le 8999) or ( &sicvar ge 4220 and &sicvar le 4229) then &varname=34;
	if ( &sicvar ge 3570 and &sicvar le 3579) or ( &sicvar ge 3680 and &sicvar le 3680) or ( &sicvar ge 3681 and &sicvar le 3681) or ( &sicvar ge 3682 and &sicvar le 3682) or ( &sicvar ge 3683 and &sicvar le 3683) or ( &sicvar ge 3684 and &sicvar le 3684) or ( &sicvar ge 3685 and &sicvar le 3685) or ( &sicvar ge 3686 and &sicvar le 3686) or ( &sicvar ge 3687 and &sicvar le 3687) or ( &sicvar ge 3688 and &sicvar le 3688) or ( &sicvar ge 3689 and &sicvar le 3689) or ( &sicvar ge 3695 and &sicvar le 3695) then &varname=35;
	if ( &sicvar ge 7370 and &sicvar le 7372) or ( &sicvar ge 7375 and &sicvar le 7375) or ( &sicvar ge 7373 and &sicvar le 7373) then &varname=36;
	if ( &sicvar ge 3622 and &sicvar le 3622) or ( &sicvar ge 3661 and &sicvar le 3661) or ( &sicvar ge 3662 and &sicvar le 3662) or ( &sicvar ge 3663 and &sicvar le 3663) or ( &sicvar ge 3664 and &sicvar le 3664) or ( &sicvar ge 3665 and &sicvar le 3665) or ( &sicvar ge 3666 and &sicvar le 3666) or ( &sicvar ge 3669 and &sicvar le 3669) or ( &sicvar ge 3670 and &sicvar le 3679) or ( &sicvar ge 3810 and &sicvar le 3810) or ( &sicvar ge 3812 and &sicvar le 3812) then &varname=37;
	if ( &sicvar ge 3811 and &sicvar le 3811) or ( &sicvar ge 3820 and &sicvar le 3820) or ( &sicvar ge 3821 and &sicvar le 3821) or ( &sicvar ge 3822 and &sicvar le 3822) or ( &sicvar ge 3823 and &sicvar le 3823) or ( &sicvar ge 3824 and &sicvar le 3824) or ( &sicvar ge 3825 and &sicvar le 3825) or ( &sicvar ge 3826 and &sicvar le 3826) or ( &sicvar ge 3827 and &sicvar le 3827) or ( &sicvar ge 3829 and &sicvar le 3829) or ( &sicvar ge 3830 and &sicvar le 3839) then &varname=38;
	if ( &sicvar ge 2520 and &sicvar le 2549) or ( &sicvar ge 2600 and &sicvar le 2639) or ( &sicvar ge 2670 and &sicvar le 2699) or ( &sicvar ge 2760 and &sicvar le 2761) or ( &sicvar ge 3950 and &sicvar le 3955) then &varname=39;
	if ( &sicvar ge 2440 and &sicvar le 2449) or ( &sicvar ge 2640 and &sicvar le 2659) or ( &sicvar ge 3220 and &sicvar le 3221) or ( &sicvar ge 3410 and &sicvar le 3412) then &varname=40;
	if ( &sicvar ge 4000 and &sicvar le 4013) or ( &sicvar ge 4040 and &sicvar le 4049) or ( &sicvar ge 4100 and &sicvar le 4100) or ( &sicvar ge 4110 and &sicvar le 4119) or ( &sicvar ge 4120 and &sicvar le 4121) or ( &sicvar ge 4130 and &sicvar le 4131) or ( &sicvar ge 4140 and &sicvar le 4142) or ( &sicvar ge 4150 and &sicvar le 4151) or ( &sicvar ge 4170 and &sicvar le 4173) or ( &sicvar ge 4190 and &sicvar le 4199) or ( &sicvar ge 4200 and &sicvar le 4200) or ( &sicvar ge 4210 and &sicvar le 4219) or ( &sicvar ge 4230 and &sicvar le 4231) or ( &sicvar ge 4240 and &sicvar le 4249) or ( &sicvar ge 4400 and &sicvar le 4499) or ( &sicvar ge 4500 and &sicvar le 4599) or ( &sicvar ge 4600 and &sicvar le 4699) or ( &sicvar ge 4700 and &sicvar le 4700) or ( &sicvar ge 4710 and &sicvar le 4712) or ( &sicvar ge 4720 and &sicvar le 4729) or ( &sicvar ge 4730 and &sicvar le 4739) or ( &sicvar ge 4740 and &sicvar le 4749) or ( &sicvar ge 4780 and &sicvar le 4780) or ( &sicvar ge 4782 and &sicvar le 4782) or ( &sicvar ge 4783 and &sicvar le 4783) or ( &sicvar ge 4784 and &sicvar le 4784) or ( &sicvar ge 4785 and &sicvar le 4785) or ( &sicvar ge 4789 and &sicvar le 4789) then &varname=41;
	if ( &sicvar ge 5000 and &sicvar le 5000) or ( &sicvar ge 5010 and &sicvar le 5015) or ( &sicvar ge 5020 and &sicvar le 5023) or ( &sicvar ge 5030 and &sicvar le 5039) or ( &sicvar ge 5040 and &sicvar le 5042) or ( &sicvar ge 5043 and &sicvar le 5043) or ( &sicvar ge 5044 and &sicvar le 5044) or ( &sicvar ge 5045 and &sicvar le 5045) or ( &sicvar ge 5046 and &sicvar le 5046) or ( &sicvar ge 5047 and &sicvar le 5047) or ( &sicvar ge 5048 and &sicvar le 5048) or ( &sicvar ge 5049 and &sicvar le 5049) or ( &sicvar ge 5050 and &sicvar le 5059) or ( &sicvar ge 5060 and &sicvar le 5060) or ( &sicvar ge 5063 and &sicvar le 5063) or ( &sicvar ge 5064 and &sicvar le 5064) or ( &sicvar ge 5065 and &sicvar le 5065) or ( &sicvar ge 5070 and &sicvar le 5078) or ( &sicvar ge 5080 and &sicvar le 5080) or ( &sicvar ge 5081 and &sicvar le 5081) or ( &sicvar ge 5082 and &sicvar le 5082) or ( &sicvar ge 5083 and &sicvar le 5083) or ( &sicvar ge 5084 and &sicvar le 5084) or ( &sicvar ge 5085 and &sicvar le 5085) or ( &sicvar ge 5086 and &sicvar le 5087) or ( &sicvar ge 5088 and &sicvar le 5088) or ( &sicvar ge 5090 and &sicvar le 5090) or ( &sicvar ge 5091 and &sicvar le 5092) or ( &sicvar ge 5093 and &sicvar le 5093) or ( &sicvar ge 5094 and &sicvar le 5094) or ( &sicvar ge 5099 and &sicvar le 5099) or ( &sicvar ge 5100 and &sicvar le 5100) or ( &sicvar ge 5110 and &sicvar le 5113) or ( &sicvar ge 5120 and &sicvar le 5122) or ( &sicvar ge 5130 and &sicvar le 5139) or ( &sicvar ge 5140 and &sicvar le 5149) or ( &sicvar ge 5150 and &sicvar le 5159) or ( &sicvar ge 5160 and &sicvar le 5169) or ( &sicvar ge 5170 and &sicvar le 5172) or ( &sicvar ge 5180 and &sicvar le 5182) or ( &sicvar ge 5190 and &sicvar le 5199) then &varname=42;
	if ( &sicvar ge 5200 and &sicvar le 5200) or ( &sicvar ge 5210 and &sicvar le 5219) or ( &sicvar ge 5220 and &sicvar le 5229) or ( &sicvar ge 5230 and &sicvar le 5231) or ( &sicvar ge 5250 and &sicvar le 5251) or ( &sicvar ge 5260 and &sicvar le 5261) or ( &sicvar ge 5270 and &sicvar le 5271) or ( &sicvar ge 5300 and &sicvar le 5300) or ( &sicvar ge 5310 and &sicvar le 5311) or ( &sicvar ge 5320 and &sicvar le 5320) or ( &sicvar ge 5330 and &sicvar le 5331) or ( &sicvar ge 5334 and &sicvar le 5334) or ( &sicvar ge 5340 and &sicvar le 5349) or ( &sicvar ge 5390 and &sicvar le 5399) or ( &sicvar ge 5400 and &sicvar le 5400) or ( &sicvar ge 5410 and &sicvar le 5411) or ( &sicvar ge 5412 and &sicvar le 5412) or ( &sicvar ge 5420 and &sicvar le 5429) or ( &sicvar ge 5430 and &sicvar le 5439) or ( &sicvar ge 5440 and &sicvar le 5449) or ( &sicvar ge 5450 and &sicvar le 5459) or ( &sicvar ge 5460 and &sicvar le 5469) or ( &sicvar ge 5490 and &sicvar le 5499) or ( &sicvar ge 5500 and &sicvar le 5500) or ( &sicvar ge 5510 and &sicvar le 5529) or ( &sicvar ge 5530 and &sicvar le 5539) or ( &sicvar ge 5540 and &sicvar le 5549) or ( &sicvar ge 5550 and &sicvar le 5559) or ( &sicvar ge 5560 and &sicvar le 5569) or ( &sicvar ge 5570 and &sicvar le 5579) or ( &sicvar ge 5590 and &sicvar le 5599) or ( &sicvar ge 5600 and &sicvar le 5699) or ( &sicvar ge 5700 and &sicvar le 5700) or ( &sicvar ge 5710 and &sicvar le 5719) or ( &sicvar ge 5720 and &sicvar le 5722) or ( &sicvar ge 5730 and &sicvar le 5733) or ( &sicvar ge 5734 and &sicvar le 5734) or ( &sicvar ge 5735 and &sicvar le 5735) or ( &sicvar ge 5736 and &sicvar le 5736) or ( &sicvar ge 5750 and &sicvar le 5799) or ( &sicvar ge 5900 and &sicvar le 5900) or ( &sicvar ge 5910 and &sicvar le 5912) or ( &sicvar ge 5920 and &sicvar le 5929) or ( &sicvar ge 5930 and &sicvar le 5932) or ( &sicvar ge 5940 and &sicvar le 5940) or ( &sicvar ge 5941 and &sicvar le 5941) or ( &sicvar ge 5942 and &sicvar le 5942) or ( &sicvar ge 5943 and &sicvar le 5943) or ( &sicvar ge 5944 and &sicvar le 5944) or ( &sicvar ge 5945 and &sicvar le 5945) or ( &sicvar ge 5946 and &sicvar le 5946) or ( &sicvar ge 5947 and &sicvar le 5947) or ( &sicvar ge 5948 and &sicvar le 5948) or ( &sicvar ge 5949 and &sicvar le 5949) or ( &sicvar ge 5950 and &sicvar le 5959) or ( &sicvar ge 5960 and &sicvar le 5969) or ( &sicvar ge 5970 and &sicvar le 5979) or ( &sicvar ge 5980 and &sicvar le 5989) or ( &sicvar ge 5990 and &sicvar le 5990) or ( &sicvar ge 5992 and &sicvar le 5992) or ( &sicvar ge 5993 and &sicvar le 5993) or ( &sicvar ge 5994 and &sicvar le 5994) or ( &sicvar ge 5995 and &sicvar le 5995) or ( &sicvar ge 5999 and &sicvar le 5999) then &varname=43;
	if ( &sicvar ge 5800 and &sicvar le 5819) or ( &sicvar ge 5820 and &sicvar le 5829) or ( &sicvar ge 5890 and &sicvar le 5899) or ( &sicvar ge 7000 and &sicvar le 7000) or ( &sicvar ge 7010 and &sicvar le 7019) or ( &sicvar ge 7040 and &sicvar le 7049) or ( &sicvar ge 7213 and &sicvar le 7213) then &varname=44;
	if ( &sicvar ge 6000 and &sicvar le 6000) or ( &sicvar ge 6010 and &sicvar le 6019) or ( &sicvar ge 6020 and &sicvar le 6020) or ( &sicvar ge 6021 and &sicvar le 6021) or ( &sicvar ge 6022 and &sicvar le 6022) or ( &sicvar ge 6023 and &sicvar le 6024) or ( &sicvar ge 6025 and &sicvar le 6025) or ( &sicvar ge 6026 and &sicvar le 6026) or ( &sicvar ge 6027 and &sicvar le 6027) or ( &sicvar ge 6028 and &sicvar le 6029) or ( &sicvar ge 6030 and &sicvar le 6036) or ( &sicvar ge 6040 and &sicvar le 6059) or ( &sicvar ge 6060 and &sicvar le 6062) or ( &sicvar ge 6080 and &sicvar le 6082) or ( &sicvar ge 6090 and &sicvar le 6099) or ( &sicvar ge 6100 and &sicvar le 6100) or ( &sicvar ge 6110 and &sicvar le 6111) or ( &sicvar ge 6112 and &sicvar le 6113) or ( &sicvar ge 6120 and &sicvar le 6129) or ( &sicvar ge 6130 and &sicvar le 6139) or ( &sicvar ge 6140 and &sicvar le 6149) or ( &sicvar ge 6150 and &sicvar le 6159) or ( &sicvar ge 6160 and &sicvar le 6169) or ( &sicvar ge 6170 and &sicvar le 6179) or ( &sicvar ge 6190 and &sicvar le 6199) then &varname=45;
	if ( &sicvar ge 6300 and &sicvar le 6300) or ( &sicvar ge 6310 and &sicvar le 6319) or ( &sicvar ge 6320 and &sicvar le 6329) or ( &sicvar ge 6330 and &sicvar le 6331) or ( &sicvar ge 6350 and &sicvar le 6351) or ( &sicvar ge 6360 and &sicvar le 6361) or ( &sicvar ge 6370 and &sicvar le 6379) or ( &sicvar ge 6390 and &sicvar le 6399) or ( &sicvar ge 6400 and &sicvar le 6411) then &varname=46;
	if ( &sicvar ge 6500 and &sicvar le 6500) or ( &sicvar ge 6510 and &sicvar le 6510) or ( &sicvar ge 6512 and &sicvar le 6512) or ( &sicvar ge 6513 and &sicvar le 6513) or ( &sicvar ge 6514 and &sicvar le 6514) or ( &sicvar ge 6515 and &sicvar le 6515) or ( &sicvar ge 6517 and &sicvar le 6519) or ( &sicvar ge 6520 and &sicvar le 6529) or ( &sicvar ge 6530 and &sicvar le 6531) or ( &sicvar ge 6532 and &sicvar le 6532) or ( &sicvar ge 6540 and &sicvar le 6541) or ( &sicvar ge 6550 and &sicvar le 6553) or ( &sicvar ge 6590 and &sicvar le 6599) or ( &sicvar ge 6610 and &sicvar le 6611) then &varname=47;
	if ( &sicvar ge 6200 and &sicvar le 6299) or ( &sicvar ge 6700 and &sicvar le 6700) or ( &sicvar ge 6710 and &sicvar le 6719) or ( &sicvar ge 6720 and &sicvar le 6722) or ( &sicvar ge 6723 and &sicvar le 6723) or ( &sicvar ge 6724 and &sicvar le 6724) or ( &sicvar ge 6725 and &sicvar le 6725) or ( &sicvar ge 6726 and &sicvar le 6726) or ( &sicvar ge 6730 and &sicvar le 6733) or ( &sicvar ge 6740 and &sicvar le 6779) or ( &sicvar ge 6790 and &sicvar le 6791) or ( &sicvar ge 6792 and &sicvar le 6792) or ( &sicvar ge 6793 and &sicvar le 6793) or ( &sicvar ge 6794 and &sicvar le 6794) or ( &sicvar ge 6795 and &sicvar le 6795) or ( &sicvar ge 6798 and &sicvar le 6798) or ( &sicvar ge 6799 and &sicvar le 6799) then &varname=48;
	if ( &sicvar ge 4950 and &sicvar le 4959) or ( &sicvar ge 4960 and &sicvar le 4961) or ( &sicvar ge 4970 and &sicvar le 4971) or ( &sicvar ge 4990 and &sicvar le 4991) then &varname=49;

	run;

%mend;


%put FF49 Macro Loaded;

%put GOOD JOB! YOU LOADED THE MACROS;

/******************************************************************************************/
