
/*******************************************************************************
LOCAL SETUP
*******************************************************************************/

*macro variable for the filepath to this code;
*this is useful for creating relative file paths;
%let codepath = %qsysfunc(sysget(SAS_EXECFILEPATH));

*print the codepath in the log, it should be the folder this file is saved in;
%put &codepath;

*using the codepath, we can make a path to the MACROS file;
%let macrofile = &codepath\..\MACROS.sas;

*include the code file for the macros; 
*this will allow you to use the macros in the MACROS file 
without copying their code into your script each time;
%include "&macrofile";


*library for my LOCAL data folder (df);
*MODIFY THIS FOR YOUR DATA FOLDER!;
libname df "D:\Dropbox\example-project";

/*******************************************************************************
REMOTE (WRDS) LOGIN AND SETUP
*******************************************************************************/


*I often download all of the raw data to my own machine and work on it locally.
This has benefits for replicability to make sure your paper can be replicated
from the original raw data source. Also, the raw data in most databases changes
with the "vintage" of the data as data is added/removed/corrected/modified 
by the data provider. Therefore, the raw data can change between
downloads, reducing the replicability of your results. See, for example:
https://onlinelibrary.wiley.com/doi/abs/10.1111/j.1540-6261.2009.01484.x
https://link.springer.com/article/10.1007/s11142-020-09560-x;

*In this example, we will do most of the work remotely on the 
WRDS server in case some students have laptops with limited resources;

*Sign on to WRDS;
%let wrds =  wrds-cloud.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

*If you would like to see your remote work files inside your local SAS
console you can create a local library that references your remote
work library on the WRDS server (I have called it rwork);
libname rwork slibref=work server=wrds;

*Every WRDS user has a remote library on WRDS called "home" ;
*this block of code will show you the remote filepath of your home directory;
*you have limited space available in your WRDS home directory;
rsubmit;
%let libpath = %sysfunc(pathname(home)); 
%put &libpath;
endrsubmit;

*If you work with larger files remotely, you should put them in your university's 
temporary scratch space on WRDS. The next command will set up a remote library to 
refer to the University of Kansas scratch space. 

You should replace "ukansas" with the folder for your own university;
rsubmit;
libname ku "/scratch/ukansas";
endrsubmit;



*It is also possible to upload the local macro from this project to WRDS.
Then the macros can be used on the WRDS server. The below commands will upload 
the macro file to your home directory on WRDS. You should not need to edit them 
if you have executed the above code successfully; 

*syslput copies the local macrofile pathname variable to WRDS;
%syslput _user_/like='macro*' remote = wrds;
rsubmit; 
*proc upload uploads the macro file to WRDS;
proc upload infile="&macrofile" outfile="%sysfunc(pathname(home))/MACROS.sas"; run;
endrsubmit;

/*******************************************************************************
Step 1: Obtain Data from Compustat Annual Fundamentals
*******************************************************************************/

rsubmit;
*We will link the annual fundamentals table with the company table 
to get company names, FIC codes, and replacement SIC codes;
proc sql;
create table COMPUSTAT_RAW as select distinct
/*d1 refers to data from the company table, and d2 from the funda table */
d1.conm, d2.gvkey, d2.datadate, d2.cusip as cstat_cusip, d2.cik, d2.tic as cstat_ticker,
d2.fyr, d2.fyear, d2.ceq, d2.ib, d2.at, d2.sale, d2.xrd, d2.spi, d2.csho, d2.prcc_f, 
/* Calculate market value of equity (MVE) as shares outstanding times price */
d2.csho*d2.prcc_f as mve,
/* Use case when to fill in missing historical SIC codes in the funda table with 
current SIC codes from the company table */
case 
	when d2.SICH=. then input(d1.sic,6.) 
	else d2.SICH
end as sic,
/* Use the full SIC codes calculated in the above step to get two-digit SIC (SIC2)*/
int((calculated SIC)/100) as sic2

from comp.company as d1, comp.funda as d2
/* Require GVKEYs to match between funda and the company table */
WHERE d1.GVKEY=d2.GVKEY
/* Apply Standard Compustat Filters, as well as a filter for only US firms */
and d2.indfmt='INDL' and d2.datafmt='STD' and d2.popsrc='D'
and d2.consol='C' and d1.fic = "USA";
quit;
endrsubmit;


rsubmit;
*Do some initial manipulation and cleanup on the WRDS server before 
downloading to our machine;
data compustat1;
set compustat_raw;


*Set missing values to zero. You could add more variables to this 
array as needed. The code will loop through each variable in the array
and set missing values of that variable to zero.;
array zro(*) SPI XRD;
do k=1 to dim(zro);
if zro(k) in('.','.C','.I','.M') then zro(k) = 0;
end;

*delete financial and utility industries;
if (SIC2 >= 60 and SIC2 <= 69) then delete;
if (SIC2 = 49) then delete;

*Some example code to align the data in June calendar time by creating
a calyear variable. Some papers use June of each year and assume a 
3 month reporting lag. Effectively this is coded as aligning datadate as of 
March each year. See, for example, Hou, Van Dijk, and Zhang (2012 JAE) 
Figure 1.;

*Set calyear to the year of the datadate;
calyear = year(datadate);
*If the fiscal year ends in a month after March increment calyear to the 
next year;
if fyr > 3 then calyear = calyear+1;

*Define sample period: 1970-2022;
if 1970 <= calyear <= 2022;
*I am going to scale by total assets (at) so I am going to set a minimum
in order to avoid small denominators;
if at => 10;

*Define earnings (e) as earnings before special items;
e= ib - spi;

*Code a loss dummy that equals 1 for loss firms;
if e < 0 then loss = 1;
	else loss = 0;

*Scale e by total assets;
*FSA purists would probably use average total assets, but just an example;
roa = e / at;

*scale r&d by total assets;
rd = xrd / at;

*drop columns we don't need to save locally for this example;
drop cstat_cusip cik cstat_ticker ceq sale;
run; 
endrsubmit;



*check duplicates;
rsubmit;
proc sql;
create table checkdups as select distinct
gvkey,datadate, count(conm) as n
from compustat1
group by gvkey,datadate
order by n desc;
quit;
endrsubmit;
*no dups;

*check another way;
rsubmit;
proc sql;
create table checkdups as select distinct
gvkey,fyear,count(datadate) as n
from compustat1
group by gvkey,fyear
order by n desc;
quit;
endrsubmit;
*no dups; 


*Download the data from WRDS to your local data folder;
rsubmit;
proc download data=compustat1 out=comp1;
run;
endrsubmit;

*sign off from WRDS;
signoff;


/*******************************************************************************
Step 2: Manipulate the data locally and save to disk
*******************************************************************************/



*Apply the ff12 macro defined in the MACROS script;
%ff12(dsin=comp1, dsout=comp2, sicvar=sic, varname=ff12num);	

*Check the frequency of each industry classification;
proc freq data = comp2;
tables ff12num;
run;

*Merge lead data for dependent variable;
*This might have been preferable to do at an earlier step if
we really wanted to maximize sample size since we have already deleted some
data. In any case, this is simply a coding example. I am going to require
the fiscal year end months to match in order to avoid any observations with
fiscal year changes. The logic here is to join the data with itself, but on
one side of the join we require the year of the datadate to be one year greater
than the datadate on the other side. I do an innner join but a left join
would be needed if we wanted to allow the lead variable to be missing in some
cases; 
proc sql;
create table comp3 as select distinct
a.*,b.roa as roa_lead_1
from comp2 a, comp2 b
where a.gvkey=b.gvkey and 
year(a.datadate)+1=year(b.datadate) and 
month(a.datadate)=month(b.datadate);
quit;

*Delete missing values of key variables;
data comp4; 
set comp3;

*delete missing values;
array myarray(*) mve rd at ff12num roa roa_lead_1; 
/* you could re-use this anywhere, just change this list of variable names */
do k=1 to dim(myarray);
*these are missing value codes for COMPUSTAT on SAS, google them if you want to know what they mean;
if myarray(k) in('.','.C','.I','.M') then delete;
end;



run;

*check the distribution before winsorizing;
proc means data=comp4 n mean min p1 p5 p10 p25 median p75 p90 p95 p99 max;
vars mve at rd roa roa_lead_1;
run;

*winsorize the regression data;
%winsor(dsetin=comp4, dsetout=comp5, byvar=none, vars= mve at rd roa roa_lead_1, type=W, pctl=1 99)

*check the distribution after winsorizing;
proc means data=comp5 n mean min p1 p5 p10 p25 median p75 p90 p95 p99 max;
vars mve at rd roa roa_lead_1;
run;

* save the final dataset to the data folder on your local machine;
data df.regdata; set comp5;
run;


*  save as stata file;
proc export data= comp5
        	outfile= "D:\Dropbox\example-project\regdata-sas.dta"
        	dbms=stata replace;
run;


