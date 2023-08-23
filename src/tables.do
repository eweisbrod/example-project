/******************************************************************************/
*SETUP*
//change to the directory this do file lives in
//you have to manually change to this directory, it won't do it automatically.

//If we do this once up here then everything below can just be using dots
//and it will work from any computer, can also be used to share one code with
//coauthors (each person puts their directory here).

//Eric Desktop
cd  "D:\Dropbox\CODE EXAMPLES\R\example-project-data"

//Eric Laptop
cd "C:\Users\e679w418\Dropbox\CODE EXAMPLES\R\example-project-data"

/******************************************************************************/
*LOAD DATA*
use "example-data2.dta" , clear


// sidenote: once you change to a root directory, you can also use relative
// pathnames and dots. For example, say you don't use git, but instead 
// have a root folder for your project on Dropbox
// and saved this code in a code subfolder and data in a separate subfolder. 
// Then, a relative path to the data folder from the code folder would be
// use "..\Data\example-data2.dta" , clear
//this will always be the same relative path for each computer/coauthor 
// provided they have changed directories as above, to the root project folder.


/******************************************************************************/
*GENERATE VARIABLES*

//create a numeric gvkey for firm FE. Gvkey is a character variable in the raw
// data. This is fine and should be preserved. However, to use it as a firm
// fixed effects identifier, it may be useful to create a new variable with
//gvkey as a numeric value. The name of the new variable is firm_fe
encode gvkey, generate(firm_fe)




//Similarly, it can be helpful to encode categorical factor variables as numeric
//Here I generate a categorical variable to hold the subperiods
gen subperiod = 1
replace subperiod = 2 if calyear > 1979 & calyear < 1990
replace subperiod = 3 if calyear > 1989 & calyear < 2000
replace subperiod = 4 if calyear > 1999 & calyear < 2010
replace subperiod = 5 if calyear > 2009 & calyear < 2020
replace subperiod = 6 if calyear > 2019 


//Then you can define value labels to each category so that these show in the
//output
label define subperiod_label 1 "1970 - 1979" 2 "1980 - 1989" 3 "1990 - 1999" ///
4 "2000 - 2009" 5 "2010 - 2019" 6 "2020 - 2022"
//assign the value labels to the subperiod variable
label values subperiod subperiod_label



/******************************************************************************/
*LABEL VARIABLES*

label var roa_lead_1 "ROA_{t+1}"
label var roa "ROA_t"
label var loss "LOSS"
label var rd "R\&D"
label var at "TA"
label var mve "SIZE"

label define loss_label 0 "Profit" 1 "Loss" 
label values loss loss_label


//Define Controls
//if you define this list then you don't have to type out each control anymore
// added an example of using a triple slash to break lines if needed
// this would be useful if you had more controls than could fit on one line
global controls rd at ///
mve ///



/******************************************************************************/
*Table 1 - Frequency Table*



// If you need to install the estout package then uncomment and run this line
// ssc install estout

//estout reference material links
// https://repec.sowi.unibe.ch/stata/estout/
// http://repec.org/bocode/e/estout/advanced.html

//clear out any previously stored results
eststo clear

//tabulate the data 
estpost tabulate subperiod loss


//preview the output
esttab, cell(b(fmt(%9.0fc)) colpct(fmt(2) par)) ///
     collabels("(%)") unstack noobs nonumber nomtitle    ///
     eqlabels(, lhs("Sub-Period"))                     
	 

//output the table to excel
// don't use comma-format numbers in the excel file unless you research special
// options, because the excel is a csv file and it will break at the commas
esttab using "output\freq-stata.csv", replace ///
	 cell(b(fmt(%9.0f)) colpct(fmt(2) par)) ///
     collabels("(%)") unstack noobs nonumber nomtitle    ///
     eqlabels(, lhs("Sub-Period"))

// one common method for people coming from corporate used to formatting
// tables in excel is to have one sheet in excel with the raw data and one sheet
// with formulas that read from the raw data and manually add formatting to it
// if you use this method, the "plain" option in estout may be helpful
// see this note from the esttab manual:

/*
Depending on whether the plain option is specified or not, esttab uses
 two different variants of the CSV format. By default, that is, if plain is 
 omitted, the contents of the table cells are enclosed in double quotes 
 preceded by an equal sign (i.e. ="..."). This prevents Excel from trying to
 interpret the contents of the cells and, therefore, preserves formatting
 elements such as parentheses around t-statistics. One drawback of this 
 approach is, however, that the displayed numbers cannot directly be used for 
 further calculations in Excel. Hence, if the purpose of exporting the
 estimates is to do additional computations in Excel, specify the plain
 option. In this case, the table cells are enclosed in double quotes 
 without the equal sign, and Excel will interpret the contents as numbers.
*/

//output the table to word
//comma formatting may be used here
esttab using "output\freq-stata.rtf", replace ///
	 cell(b(fmt(%9.0fc)) colpct(fmt(2) par)) ///
     collabels("(%)") unstack noobs nonumber nomtitle    ///
     eqlabels(, lhs("Sub-Period"))                    

/******************************************************************************/
*Table 2 - Descriptive Statistics*


//clear out any previously stored results
eststo clear

//summarize the data
estpost summarize roa_lead_1 roa loss $controls ///
		, detail

//preview the output
esttab . , replace noobs label ///
cells("count(fmt(%9.0fc)) mean(fmt(%9.3fc)) p50(fmt(%9.3fc)) sd(fmt(%9.3fc)) p25(fmt(%9.3fc)) p75(fmt(%9.3fc))") compress

//output the table to excel
esttab using "output\descrip-stata.csv", replace ///
cells("count(fmt(%9.0f)) mean(fmt(%9.3f)) p50(fmt(%9.3f)) sd(fmt(%9.3f)) p25(fmt(%9.3f)) p75(fmt(%9.3f))") compress ///
 title("Descriptive Statistics") ///
 nomtitles nonumbers noobs label 
 

//output the table to word
esttab using "output\descrip-stata.rtf", replace ///
cells("count(fmt(%9.0fc)) mean(fmt(%9.3fc)) p50(fmt(%9.3fc)) sd(fmt(%9.3fc)) p25(fmt(%9.3fc)) p75(fmt(%9.3fc))") compress ///
 title("Descriptive Statistics") ///
 nomtitles nonumbers noobs label 

/******************************************************************************/
*Table 3 - Regression*


//clear out any previously stored results
eststo clear

//Run first-column regression and store results
eststo, title("Full Sample"): reghdfe roa_lead i.fdp_num, nocons cluster(gvkey best_anndats)  absorb(yearqtr)



eststo, title("2002 to 2006"): reghdfe unsigned_error i.fdp_num if period==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("2007 to 2011"): reghdfe unsigned_error i.fdp_num if period==2, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("2012 to 2016"): reghdfe unsigned_error i.fdp_num if period==3, nocons cluster(gvkey best_anndats)  absorb(yearqtr)

eststo, title("Full Sample"): reghdfe unsigned_error i.fdp_num $controls, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("2002 to 2006"): reghdfe unsigned_error i.fdp_num $controls if period==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("2007 to 2011"): reghdfe unsigned_error i.fdp_num $controls if period==2, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("2012 to 2016"): reghdfe unsigned_error i.fdp_num $controls if period==3, nocons cluster(gvkey best_anndats)  absorb(yearqtr)




esttab using "..\Results\table3.csv", replace  ///
 title("Accuracy Horserace") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3))
 
 
 
 
//****************Table 4 - Predict Horse Race**************//
 
/*Operating Earnings*/
eststo clear

eststo, title("Full Sample"): reghdfe future_op_earn earnings c.earnings#i.fdp_num, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("2002 to 2006"): reghdfe future_op_earn earnings c.earnings#i.fdp_num if period==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("2007 to 2011"): reghdfe future_op_earn earnings c.earnings#i.fdp_num if period==2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("2012 to 2016"): reghdfe future_op_earn earnings c.earnings#i.fdp_num if period==3, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Full Sample"): reghdfe future_op_earn earnings c.earnings#i.fdp_num $controls , nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Full Sample"): reghdfe future_op_earn earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("2002 to 2006"): reghdfe future_op_earn earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if period==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("2007 to 2011"): reghdfe future_op_earn earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if period==2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("2012 to 2016"): reghdfe future_op_earn earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if period==3, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)


esttab using "..\Results\table4.csv", replace  ///
 title("Earn Predict Horserace") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3))
 
 
 
/*Operating CF*/
eststo clear

eststo, title("Full Sample"): reghdfe future_op_cf earnings c.earnings#i.fdp_num, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("2002 to 2006"): reghdfe future_op_cf earnings c.earnings#i.fdp_num if period==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("2007 to 2011"): reghdfe future_op_cf earnings c.earnings#i.fdp_num if period==2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("2012 to 2016"): reghdfe future_op_cf earnings c.earnings#i.fdp_num if period==3, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Full Sample"): reghdfe future_op_cf earnings c.earnings#i.fdp_num $controls , nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Full Sample"): reghdfe future_op_cf earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("2002 to 2006"): reghdfe future_op_cf earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if period==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("2007 to 2011"): reghdfe future_op_cf earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if period==2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("2012 to 2016"): reghdfe future_op_cf earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if period==3, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)


esttab using "..\Results\table4.csv", replace  ///
 title("CF Predict Horserace") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3))
 
 
 
 
 
 //****************Table 5 - ERC Horse Race**************//
 
 eststo clear

eststo, title("Full Sample"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("2002 to 2006"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num if period==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("2007 to 2011"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num if period==2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("2012 to 2016"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num if period==3, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Full Sample"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num $controls , nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Full Sample"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("2002 to 2006"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		if period==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)	
		
eststo, title("2007 to 2011"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		if period==2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("2012 to 2016"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		if period==3, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)


esttab using "..\Results\table5.csv", replace  ///
 title("ERC Horserace") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3))
 
	
 
 
 
 
 
 //****************Table 6 - Horserace Partitions**************// 
/*TABLE  - Horserace Partitions*/
 
 
/*Panel A: Accuracy*/
eststo clear

eststo, title("Accuracy - Low Stock Comp"): reghdfe unsigned_error i.fdp_num if high_stkcomp==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("Accuracy - High Stock Comp"): reghdfe unsigned_error i.fdp_num if high_stkcomp==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)

eststo, title("Accuracy - Unexpected Item No"): reghdfe unsigned_error i.fdp_num if unexpected_item==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("Accuracy - Unexpected Item Yes"): reghdfe unsigned_error i.fdp_num if unexpected_item==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)


eststo, title("Accuracy - Low Stock Comp"): reghdfe unsigned_error i.fdp_num $controls if high_stkcomp==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("Accuracy - High Stock Comp"): reghdfe unsigned_error i.fdp_num $controls if high_stkcomp==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)

eststo, title("Accuracy - Unexpected Item No"): reghdfe unsigned_error i.fdp_num $controls if unexpected_item==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("Accuracy - Unexpected Item Yes"): reghdfe unsigned_error i.fdp_num $controls if unexpected_item==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)



esttab using "..\Results\table6A.csv", replace  ///
 title("Subsample Analysis - Accuracy") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 
/*Panel A: Accuracy - Test across partitions*/
eststo clear

eststo, title("Accuracy - Stock Comp Diff"): reghdfe unsigned_error i.fdp_num high_stkcomp i.fdp_num#c.high_stkcomp, nocons cluster(gvkey best_anndats)  absorb(yearqtr#high_stkcomp)

eststo, title("Accuracy - Unexpected Item Diff"): reghdfe unsigned_error i.fdp_num unexpected_item i.fdp_num#c.unexpected_item, nocons cluster(gvkey best_anndats)  absorb(yearqtr#unexpected_item)

eststo, title("Accuracy - Stock Comp Diff"): reghdfe unsigned_error i.fdp_num high_stkcomp i.fdp_num#c.high_stkcomp $controls ///
	c.high_stkcomp#c.lnmve c.high_stkcomp#c.btm c.high_stkcomp#c.io ///
	c.high_stkcomp#c.unique_following c.high_stkcomp#c.guidance c.high_stkcomp#c.dispersion c.high_stkcomp#c.percent_change_ibq  ///
	c.high_stkcomp#c.percent_change_cshfdq c.high_stkcomp#c.stock_split c.high_stkcomp#c.comp_gaapvstreet_diff c.high_stkcomp#c.abs_spiq_ibq c.high_stkcomp#c.ret_vol ///
	c.high_stkcomp#c.log_lagmins c.high_stkcomp#c.q4 ///	
	, nocons cluster(gvkey best_anndats)  absorb(yearqtr#high_stkcomp)

eststo, title("Accuracy - Unexpected Item Diff"): reghdfe unsigned_error i.fdp_num unexpected_item i.fdp_num#c.unexpected_item $controls ///
	c.unexpected_item#c.lnmve c.unexpected_item#c.btm c.unexpected_item#c.io ///
	c.unexpected_item#c.unique_following c.unexpected_item#c.guidance c.unexpected_item#c.dispersion c.unexpected_item#c.percent_change_ibq  ///
	c.unexpected_item#c.percent_change_cshfdq c.unexpected_item#c.stock_split c.unexpected_item#c.comp_gaapvstreet_diff c.unexpected_item#c.abs_spiq_ibq c.unexpected_item#c.ret_vol ///
	c.unexpected_item#c.log_lagmins c.unexpected_item#c.q4 ///	
	, nocons cluster(gvkey best_anndats)  absorb(yearqtr#unexpected_item)

esttab using "..\Results\table6A_diff.csv", replace  ///
 title("Subsample Analysis - Accuracy, Test Across") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 
 /*Panel B: Operating Earnings*/
eststo clear

eststo, title("Op Earnings - Low Stock Comp"): reghdfe future_op_earn earnings c.earnings#i.fdp_num if high_stkcomp==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("Op Earnings - High Stock Comp"): reghdfe future_op_earn earnings c.earnings#i.fdp_num if high_stkcomp==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Op Earnings - Unexpected Item No"): reghdfe future_op_earn earnings c.earnings#i.fdp_num if unexpected_item==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("Op Earnings - Unexpected Item Yes"): reghdfe future_op_earn earnings c.earnings#i.fdp_num if unexpected_item==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)


eststo, title("Op Earnings - Low Stock Comp"): reghdfe future_op_earn earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if high_stkcomp==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("Op Earnings - High Stock Comp"): reghdfe future_op_earn earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if high_stkcomp==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Op Earnings - Unexpected Item No"): reghdfe future_op_earn earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if unexpected_item==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("Op Earnings - Unexpected Item Yes"): reghdfe future_op_earn earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if unexpected_item==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)



esttab using "..\Results\table6B.csv", replace  ///
 title("Subsample Analysis - Operating Earnings") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 
/*Panel B: Op Earnings - Test across partitions*/
eststo clear

eststo, title("Op Earnings - Stock Comp Diff"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.high_stkcomp ///
		c.earnings#i.fdp_num#c.high_stkcomp, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#high_stkcomp)

eststo, title("Op Earnings - Unexpected Item Diff"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.unexpected_item ///
		c.earnings#i.fdp_num#c.unexpected_item, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#unexpected_item)

eststo, title("Op Earnings - Stock Comp Diff"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.high_stkcomp ///
		c.earnings#i.fdp_num#c.high_stkcomp ///
		$controls ///
		c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		c.high_stkcomp#c.lnmve c.high_stkcomp#c.btm c.high_stkcomp#c.io ///
		c.high_stkcomp#c.unique_following c.high_stkcomp#c.guidance c.high_stkcomp#c.dispersion c.high_stkcomp#c.percent_change_ibq  ///
		c.high_stkcomp#c.percent_change_cshfdq c.high_stkcomp#c.stock_split c.high_stkcomp#c.comp_gaapvstreet_diff c.high_stkcomp#c.abs_spiq_ibq c.high_stkcomp#c.ret_vol ///
		c.high_stkcomp#c.log_lagmins c.high_stkcomp#c.q4 ///
		c.earnings#c.high_stkcomp#c.lnmve c.earnings#c.high_stkcomp#c.btm c.earnings#c.high_stkcomp#c.io ///
		c.earnings#c.high_stkcomp#c.unique_following c.earnings#c.high_stkcomp#c.guidance c.earnings#c.high_stkcomp#c.dispersion c.earnings#c.high_stkcomp#c.percent_change_ibq  ///
		c.earnings#c.high_stkcomp#c.percent_change_cshfdq c.earnings#c.high_stkcomp#c.stock_split c.earnings#c.high_stkcomp#c.comp_gaapvstreet_diff ///
		c.earnings#c.high_stkcomp#c.abs_spiq_ibq c.earnings#c.high_stkcomp#c.ret_vol ///
		c.earnings#c.high_stkcomp#c.log_lagmins c.earnings#c.high_stkcomp#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#high_stkcomp)
		
eststo, title("Op Earnings - Unexpected Item Diff"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.unexpected_item ///
		c.earnings#i.fdp_num#c.unexpected_item ///
		$controls ///
		c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		c.unexpected_item#c.lnmve c.unexpected_item#c.btm c.unexpected_item#c.io ///
		c.unexpected_item#c.unique_following c.unexpected_item#c.guidance c.unexpected_item#c.dispersion c.unexpected_item#c.percent_change_ibq  ///
		c.unexpected_item#c.percent_change_cshfdq c.unexpected_item#c.stock_split c.unexpected_item#c.comp_gaapvstreet_diff c.unexpected_item#c.abs_spiq_ibq c.unexpected_item#c.ret_vol ///
		c.unexpected_item#c.log_lagmins c.unexpected_item#c.q4 ///
		c.earnings#c.unexpected_item#c.lnmve c.earnings#c.unexpected_item#c.btm c.earnings#c.unexpected_item#c.io ///
		c.earnings#c.unexpected_item#c.unique_following c.earnings#c.unexpected_item#c.guidance c.earnings#c.unexpected_item#c.dispersion c.earnings#c.unexpected_item#c.percent_change_ibq  ///
		c.earnings#c.unexpected_item#c.percent_change_cshfdq c.earnings#c.unexpected_item#c.stock_split c.earnings#c.unexpected_item#c.comp_gaapvstreet_diff ///
		c.earnings#c.unexpected_item#c.abs_spiq_ibq c.earnings#c.unexpected_item#c.ret_vol ///
		c.earnings#c.unexpected_item#c.log_lagmins c.earnings#c.unexpected_item#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#unexpected_item)



esttab using "..\Results\table6B_diff.csv", replace  ///
 title("Subsample Analysis - Operating Earnings, Test Across") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 

 
 
 
 
 /*Panel C: Operating CF*/
eststo clear

eststo, title("Op CF - Low Stock Comp"): reghdfe future_op_cf earnings c.earnings#i.fdp_num if high_stkcomp==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("Op CF - High Stock Comp"): reghdfe future_op_cf earnings c.earnings#i.fdp_num if high_stkcomp==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Op CF - Unexpected Item No"): reghdfe future_op_cf earnings c.earnings#i.fdp_num if unexpected_item==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("Op CF - Unexpected Item Yes"): reghdfe future_op_cf earnings c.earnings#i.fdp_num if unexpected_item==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)


eststo, title("Op CF - Low Stock Comp"): reghdfe future_op_cf earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if high_stkcomp==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("Op CF - High Stock Comp"): reghdfe future_op_cf earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if high_stkcomp==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Op CF - Unexpected Item No"): reghdfe future_op_cf earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if unexpected_item==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("Op CF - Unexpected Item Yes"): reghdfe future_op_cf earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if unexpected_item==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)



esttab using "..\Results\table6C.csv", replace  ///
 title("Subsample Analysis - Operating CF") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 
/*Panel C: Op CF - Test across partitions*/
eststo clear

eststo, title("Op CF - Stock Comp Diff"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.high_stkcomp ///
		c.earnings#i.fdp_num#c.high_stkcomp, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#high_stkcomp)

eststo, title("Op CF - Unexpected Item Diff"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.unexpected_item ///
		c.earnings#i.fdp_num#c.unexpected_item, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#unexpected_item)

eststo, title("Op CF - Stock Comp Diff"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.high_stkcomp ///
		c.earnings#i.fdp_num#c.high_stkcomp ///
		$controls ///
		c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		c.high_stkcomp#c.lnmve c.high_stkcomp#c.btm c.high_stkcomp#c.io ///
		c.high_stkcomp#c.unique_following c.high_stkcomp#c.guidance c.high_stkcomp#c.dispersion c.high_stkcomp#c.percent_change_ibq  ///
		c.high_stkcomp#c.percent_change_cshfdq c.high_stkcomp#c.stock_split c.high_stkcomp#c.comp_gaapvstreet_diff c.high_stkcomp#c.abs_spiq_ibq c.high_stkcomp#c.ret_vol ///
		c.high_stkcomp#c.log_lagmins c.high_stkcomp#c.q4 ///
		c.earnings#c.high_stkcomp#c.lnmve c.earnings#c.high_stkcomp#c.btm c.earnings#c.high_stkcomp#c.io ///
		c.earnings#c.high_stkcomp#c.unique_following c.earnings#c.high_stkcomp#c.guidance c.earnings#c.high_stkcomp#c.dispersion c.earnings#c.high_stkcomp#c.percent_change_ibq  ///
		c.earnings#c.high_stkcomp#c.percent_change_cshfdq c.earnings#c.high_stkcomp#c.stock_split c.earnings#c.high_stkcomp#c.comp_gaapvstreet_diff ///
		c.earnings#c.high_stkcomp#c.abs_spiq_ibq c.earnings#c.high_stkcomp#c.ret_vol ///
		c.earnings#c.high_stkcomp#c.log_lagmins c.earnings#c.high_stkcomp#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#high_stkcomp)
		
eststo, title("Op CF - Unexpected Item Diff"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.unexpected_item ///
		c.earnings#i.fdp_num#c.unexpected_item ///
		$controls ///
		c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		c.unexpected_item#c.lnmve c.unexpected_item#c.btm c.unexpected_item#c.io ///
		c.unexpected_item#c.unique_following c.unexpected_item#c.guidance c.unexpected_item#c.dispersion c.unexpected_item#c.percent_change_ibq  ///
		c.unexpected_item#c.percent_change_cshfdq c.unexpected_item#c.stock_split c.unexpected_item#c.comp_gaapvstreet_diff c.unexpected_item#c.abs_spiq_ibq c.unexpected_item#c.ret_vol ///
		c.unexpected_item#c.log_lagmins c.unexpected_item#c.q4 ///
		c.earnings#c.unexpected_item#c.lnmve c.earnings#c.unexpected_item#c.btm c.earnings#c.unexpected_item#c.io ///
		c.earnings#c.unexpected_item#c.unique_following c.earnings#c.unexpected_item#c.guidance c.earnings#c.unexpected_item#c.dispersion c.earnings#c.unexpected_item#c.percent_change_ibq  ///
		c.earnings#c.unexpected_item#c.percent_change_cshfdq c.earnings#c.unexpected_item#c.stock_split c.earnings#c.unexpected_item#c.comp_gaapvstreet_diff ///
		c.earnings#c.unexpected_item#c.abs_spiq_ibq c.earnings#c.unexpected_item#c.ret_vol ///
		c.earnings#c.unexpected_item#c.log_lagmins c.earnings#c.unexpected_item#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#unexpected_item)



esttab using "..\Results\table6C_diff.csv", replace  ///
 title("Subsample Analysis - Operating CF, Test Across") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 

 
 
/*Panel D: ERC*/
eststo clear

eststo, title("ERC - Low Stock Comp"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num if high_stkcomp==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("ERC - High Stock Comp"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num if high_stkcomp==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("ERC - Unexpected Item No"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num if unexpected_item==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("ERC - Unexpected Item Yes"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num if unexpected_item==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)


eststo, title("ERC - Low Stock Comp"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		if high_stkcomp==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("ERC - High Stock Comp"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		if high_stkcomp==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("ERC - Unexpected Item No"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		if unexpected_item==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("ERC - Unexpected Item Yes"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		if unexpected_item==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)



esttab using "..\Results\table6D.csv", replace  ///
 title("Subsample Analysis - ERC") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 
/*Panel D: ERC - Test across partitions*/
eststo clear

eststo, title("ERC - Stock Comp Diff"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.high_stkcomp ///
		c.surp_u_price#i.fdp_num#c.high_stkcomp, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#high_stkcomp)

eststo, title("ERC - Unexpected Item Diff"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.unexpected_item ///
		c.surp_u_price#i.fdp_num#c.unexpected_item, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#unexpected_item)

eststo, title("ERC - Stock Comp Diff"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.high_stkcomp ///
		c.surp_u_price#i.fdp_num#c.high_stkcomp ///
		$controls ///
		c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		c.high_stkcomp#c.lnmve c.high_stkcomp#c.btm c.high_stkcomp#c.io ///
		c.high_stkcomp#c.unique_following c.high_stkcomp#c.guidance c.high_stkcomp#c.dispersion c.high_stkcomp#c.percent_change_ibq  ///
		c.high_stkcomp#c.percent_change_cshfdq c.high_stkcomp#c.stock_split c.high_stkcomp#c.comp_gaapvstreet_diff c.high_stkcomp#c.abs_spiq_ibq c.high_stkcomp#c.ret_vol ///
		c.high_stkcomp#c.log_lagmins c.high_stkcomp#c.q4 ///
		c.surp_u_price#c.high_stkcomp#c.lnmve c.surp_u_price#c.high_stkcomp#c.btm c.surp_u_price#c.high_stkcomp#c.io ///
		c.surp_u_price#c.high_stkcomp#c.unique_following c.surp_u_price#c.high_stkcomp#c.guidance c.surp_u_price#c.high_stkcomp#c.dispersion c.surp_u_price#c.high_stkcomp#c.percent_change_ibq  ///
		c.surp_u_price#c.high_stkcomp#c.percent_change_cshfdq c.surp_u_price#c.high_stkcomp#c.stock_split c.surp_u_price#c.high_stkcomp#c.comp_gaapvstreet_diff ///
		c.surp_u_price#c.high_stkcomp#c.abs_spiq_ibq c.surp_u_price#c.high_stkcomp#c.ret_vol ///
		c.surp_u_price#c.high_stkcomp#c.log_lagmins c.surp_u_price#c.high_stkcomp#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#high_stkcomp)
		
eststo, title("ERC - Unexpected Item Diff"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.unexpected_item ///
		c.surp_u_price#i.fdp_num#c.unexpected_item ///
		$controls ///
		c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		c.unexpected_item#c.lnmve c.unexpected_item#c.btm c.unexpected_item#c.io ///
		c.unexpected_item#c.unique_following c.unexpected_item#c.guidance c.unexpected_item#c.dispersion c.unexpected_item#c.percent_change_ibq  ///
		c.unexpected_item#c.percent_change_cshfdq c.unexpected_item#c.stock_split c.unexpected_item#c.comp_gaapvstreet_diff c.unexpected_item#c.abs_spiq_ibq c.unexpected_item#c.ret_vol ///
		c.unexpected_item#c.log_lagmins c.unexpected_item#c.q4 ///
		c.surp_u_price#c.unexpected_item#c.lnmve c.surp_u_price#c.unexpected_item#c.btm c.surp_u_price#c.unexpected_item#c.io ///
		c.surp_u_price#c.unexpected_item#c.unique_following c.surp_u_price#c.unexpected_item#c.guidance c.surp_u_price#c.unexpected_item#c.dispersion c.surp_u_price#c.unexpected_item#c.percent_change_ibq  ///
		c.surp_u_price#c.unexpected_item#c.percent_change_cshfdq c.surp_u_price#c.unexpected_item#c.stock_split c.surp_u_price#c.unexpected_item#c.comp_gaapvstreet_diff ///
		c.surp_u_price#c.unexpected_item#c.abs_spiq_ibq c.surp_u_price#c.unexpected_item#c.ret_vol ///
		c.surp_u_price#c.unexpected_item#c.log_lagmins c.surp_u_price#c.unexpected_item#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#unexpected_item)



esttab using "..\Results\table6D_diff.csv", replace  ///
 title("Subsample Analysis - ERC, Test Across") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3))  
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 /***********************************************************ADDITIONAL ANALYSES***************************************************************/
 
 
 //****************Additional Table 1 - Partition by following **************// 
/*TABLE  - Horserace Partitions*/
 
 
/*Panel A: Accuracy*/
eststo clear

eststo, title("Accuracy - Low Following"): reghdfe unsigned_error i.fdp_num if high_following==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("Accuracy - High Following"): reghdfe unsigned_error i.fdp_num if high_following==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)

eststo, title("Accuracy - Low Following"): reghdfe unsigned_error i.fdp_num $controls if high_following==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("Accuracy - High Following"): reghdfe unsigned_error i.fdp_num $controls if high_following==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)


esttab using "..\Results\table6Av2.csv", replace  ///
 title("Subsample Analysis - Accuracy") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 
/*Panel A: Accuracy - Test across partitions*/
eststo clear

eststo, title("Accuracy - Following Diff"): reghdfe unsigned_error i.fdp_num high_following i.fdp_num#c.high_following, nocons cluster(gvkey best_anndats)  absorb(yearqtr#high_following)

eststo, title("Accuracy - Following Diff"): reghdfe unsigned_error i.fdp_num high_following i.fdp_num#c.high_following $controls ///
	c.high_following#c.lnmve c.high_following#c.btm c.high_following#c.io ///
	c.high_following#c.unique_following c.high_following#c.guidance c.high_following#c.dispersion c.high_following#c.percent_change_ibq  ///
	c.high_following#c.percent_change_cshfdq c.high_following#c.stock_split c.high_following#c.comp_gaapvstreet_diff c.high_following#c.abs_spiq_ibq c.high_following#c.ret_vol ///
	c.high_following#c.log_lagmins c.high_following#c.q4 ///	
	, nocons cluster(gvkey best_anndats)  absorb(yearqtr#high_following)


esttab using "..\Results\table6A_diffv2.csv", replace  ///
 title("Subsample Analysis - Accuracy, Test Across") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 
 /*Panel B: Operating Earnings*/
eststo clear

eststo, title("Op Earnings - Low Following"): reghdfe future_op_earn earnings c.earnings#i.fdp_num if high_following==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("Op Earnings - High Following"): reghdfe future_op_earn earnings c.earnings#i.fdp_num if high_following==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Op Earnings - Low Following"): reghdfe future_op_earn earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if high_following==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("Op Earnings - High Following"): reghdfe future_op_earn earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if high_following==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)


esttab using "..\Results\table6Bv2.csv", replace  ///
 title("Subsample Analysis - Operating Earnings") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 
/*Panel B: Op Earnings - Test across partitions*/
eststo clear

eststo, title("Op Earnings - Following Diff"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.high_following ///
		c.earnings#i.fdp_num#c.high_following, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#high_following)

eststo, title("Op Earnings - Following Diff"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.high_following ///
		c.earnings#i.fdp_num#c.high_following ///
		$controls ///
		c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		c.high_following#c.lnmve c.high_following#c.btm c.high_following#c.io ///
		c.high_following#c.unique_following c.high_following#c.guidance c.high_following#c.dispersion c.high_following#c.percent_change_ibq  ///
		c.high_following#c.percent_change_cshfdq c.high_following#c.stock_split c.high_following#c.comp_gaapvstreet_diff c.high_following#c.abs_spiq_ibq c.high_following#c.ret_vol ///
		c.high_following#c.log_lagmins c.high_following#c.q4 ///
		c.earnings#c.high_following#c.lnmve c.earnings#c.high_following#c.btm c.earnings#c.high_following#c.io ///
		c.earnings#c.high_following#c.unique_following c.earnings#c.high_following#c.guidance c.earnings#c.high_following#c.dispersion c.earnings#c.high_following#c.percent_change_ibq  ///
		c.earnings#c.high_following#c.percent_change_cshfdq c.earnings#c.high_following#c.stock_split c.earnings#c.high_following#c.comp_gaapvstreet_diff ///
		c.earnings#c.high_following#c.abs_spiq_ibq c.earnings#c.high_following#c.ret_vol ///
		c.earnings#c.high_following#c.log_lagmins c.earnings#c.high_following#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#high_following)
		

esttab using "..\Results\table6B_diffv2.csv", replace  ///
 title("Subsample Analysis - Operating Earnings, Test Across") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 

 
 
 
 
 /*Panel C: Operating CF*/
eststo clear

eststo, title("Op CF - Low Following"): reghdfe future_op_cf earnings c.earnings#i.fdp_num if high_following==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("Op CF - High Following"): reghdfe future_op_cf earnings c.earnings#i.fdp_num if high_following==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Op CF - Low Following"): reghdfe future_op_cf earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if high_following==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("Op CF - High Following"): reghdfe future_op_cf earnings c.earnings#i.fdp_num $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		if high_following==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

		
esttab using "..\Results\table6Cv2.csv", replace  ///
 title("Subsample Analysis - Operating CF") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 
/*Panel C: Op CF - Test across partitions*/
eststo clear

eststo, title("Op CF - Following Diff"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.high_following ///
		c.earnings#i.fdp_num#c.high_following, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#high_following)

eststo, title("Op CF - Following Diff"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.high_following ///
		c.earnings#i.fdp_num#c.high_following ///
		$controls ///
		c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		c.high_following#c.lnmve c.high_following#c.btm c.high_following#c.io ///
		c.high_following#c.unique_following c.high_following#c.guidance c.high_following#c.dispersion c.high_following#c.percent_change_ibq  ///
		c.high_following#c.percent_change_cshfdq c.high_following#c.stock_split c.high_following#c.comp_gaapvstreet_diff c.high_following#c.abs_spiq_ibq c.high_following#c.ret_vol ///
		c.high_following#c.log_lagmins c.high_following#c.q4 ///
		c.earnings#c.high_following#c.lnmve c.earnings#c.high_following#c.btm c.earnings#c.high_following#c.io ///
		c.earnings#c.high_following#c.unique_following c.earnings#c.high_following#c.guidance c.earnings#c.high_following#c.dispersion c.earnings#c.high_following#c.percent_change_ibq  ///
		c.earnings#c.high_following#c.percent_change_cshfdq c.earnings#c.high_following#c.stock_split c.earnings#c.high_following#c.comp_gaapvstreet_diff ///
		c.earnings#c.high_following#c.abs_spiq_ibq c.earnings#c.high_following#c.ret_vol ///
		c.earnings#c.high_following#c.log_lagmins c.earnings#c.high_following#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#high_following)


esttab using "..\Results\table6C_diffv2.csv", replace  ///
 title("Subsample Analysis - Operating CF, Test Across") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 

 
 
/*Panel D: ERC*/
eststo clear

eststo, title("ERC - Low Following"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num if high_following==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("ERC - High Following"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num if high_following==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("ERC - Low Following"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		if high_following==0, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("ERC - High Following"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		if high_following==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)


esttab using "..\Results\table6Dv2.csv", replace  ///
 title("Subsample Analysis - ERC") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 
/*Panel D: ERC - Test across partitions*/
eststo clear

eststo, title("ERC - Following Diff"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.high_following ///
		c.surp_u_price#i.fdp_num#c.high_following, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#high_following)

eststo, title("ERC - Following Diff"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.high_following ///
		c.surp_u_price#i.fdp_num#c.high_following ///
		$controls ///
		c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		c.high_following#c.lnmve c.high_following#c.btm c.high_following#c.io ///
		c.high_following#c.unique_following c.high_following#c.guidance c.high_following#c.dispersion c.high_following#c.percent_change_ibq  ///
		c.high_following#c.percent_change_cshfdq c.high_following#c.stock_split c.high_following#c.comp_gaapvstreet_diff c.high_following#c.abs_spiq_ibq c.high_following#c.ret_vol ///
		c.high_following#c.log_lagmins c.high_following#c.q4 ///
		c.surp_u_price#c.high_following#c.lnmve c.surp_u_price#c.high_following#c.btm c.surp_u_price#c.high_following#c.io ///
		c.surp_u_price#c.high_following#c.unique_following c.surp_u_price#c.high_following#c.guidance c.surp_u_price#c.high_following#c.dispersion c.surp_u_price#c.high_following#c.percent_change_ibq  ///
		c.surp_u_price#c.high_following#c.percent_change_cshfdq c.surp_u_price#c.high_following#c.stock_split c.surp_u_price#c.high_following#c.comp_gaapvstreet_diff ///
		c.surp_u_price#c.high_following#c.abs_spiq_ibq c.surp_u_price#c.high_following#c.ret_vol ///
		c.surp_u_price#c.high_following#c.log_lagmins c.surp_u_price#c.high_following#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num#high_following)



esttab using "..\Results\table6D_diffv2.csv", replace  ///
 title("Subsample Analysis - ERC, Test Across") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3))  
 
 
 
//****************Additional Table 2 - FDP TRAITS **************// 

/*Rank Experience*/
eststo clear
eststo ibes: estpost tabulate rank_exp if fdp_num==1
eststo zacks: estpost tabulate rank_exp if fdp_num==2
eststo ciq: estpost tabulate rank_exp if fdp_num==3
eststo bb: estpost tabulate rank_exp if fdp_num==4
eststo fset: estpost tabulate rank_exp if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\rank_exp.csv", replace  title("Rank Experience") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label 


/*Rank Following*/
eststo clear
eststo ibes: estpost tabulate rank_following if fdp_num==1
eststo zacks: estpost tabulate rank_following if fdp_num==2
eststo ciq: estpost tabulate rank_following if fdp_num==3
eststo bb: estpost tabulate rank_following if fdp_num==4
eststo fset: estpost tabulate rank_following if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\rank_following.csv", replace  title("Rank Following") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label       
 
 
/*Rank Agreement*/
eststo clear
eststo ibes: estpost tabulate actual_agree if fdp_num==1
eststo zacks: estpost tabulate actual_agree if fdp_num==2
eststo ciq: estpost tabulate actual_agree if fdp_num==3
eststo bb: estpost tabulate actual_agree if fdp_num==4
eststo fset: estpost tabulate actual_agree if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\actual_agree.csv", replace  title("Rank Agreement") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label     


/*Street Non-Gaap*/
eststo clear
eststo ibes: estpost tabulate comp_gaapvstreet_diff if fdp_num==1
eststo zacks: estpost tabulate comp_gaapvstreet_diff if fdp_num==2
eststo ciq: estpost tabulate comp_gaapvstreet_diff if fdp_num==3
eststo bb: estpost tabulate comp_gaapvstreet_diff if fdp_num==4
eststo fset: estpost tabulate comp_gaapvstreet_diff if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\comp_gaapvstreet_diff.csv", replace  title("Street Non-GAAP") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label    


/*Rank Tweets*/
eststo clear
eststo ibes: estpost tabulate rank_tweets1 if fdp_num==1
eststo zacks: estpost tabulate rank_tweets1 if fdp_num==2
eststo ciq: estpost tabulate rank_tweets1 if fdp_num==3
eststo bb: estpost tabulate rank_tweets1 if fdp_num==4
eststo fset: estpost tabulate rank_tweets1 if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\rank_tweets.csv", replace  title("Rank Tweets") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label  


/*Rank Tweets2*/
eststo clear
eststo ibes: estpost tabulate rank_tweets2 if fdp_num==1
eststo zacks: estpost tabulate rank_tweets2 if fdp_num==2
eststo ciq: estpost tabulate rank_tweets2 if fdp_num==3
eststo bb: estpost tabulate rank_tweets2 if fdp_num==4
eststo fset: estpost tabulate rank_tweets2 if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\rank_tweets2.csv", replace  title("Rank Tweets 2") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label  


/*Rank Media Cites*/
eststo clear
eststo ibes: estpost tabulate rank_cites if fdp_num==1
eststo zacks: estpost tabulate rank_cites if fdp_num==2
eststo ciq: estpost tabulate rank_cites if fdp_num==3
eststo bb: estpost tabulate rank_cites if fdp_num==4
eststo fset: estpost tabulate rank_cites if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\rank_cites.csv", replace  title("Rank Media Cites") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label    


/*Rank Media Cites 2*/
eststo clear
eststo ibes: estpost tabulate rank_cites2 if fdp_num==1
eststo zacks: estpost tabulate rank_cites2 if fdp_num==2
eststo ciq: estpost tabulate rank_cites2 if fdp_num==3
eststo bb: estpost tabulate rank_cites2 if fdp_num==4
eststo fset: estpost tabulate rank_cites2 if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\rank_cites2.csv", replace  title("Rank Media Cites 2") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label    


/*Rank Predctive Ability*/
eststo clear
eststo ibes: estpost tabulate rank_persist if fdp_num==1
eststo zacks: estpost tabulate rank_persist if fdp_num==2
eststo ciq: estpost tabulate rank_persist if fdp_num==3
eststo bb: estpost tabulate rank_persist if fdp_num==4
eststo fset: estpost tabulate rank_persist if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\rank_persist.csv", replace  title("Rank Predctive Ability") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label     


/*Rank Variable Correlations*/
eststo clear
estpost correlate rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_tweets2 rank_cites rank_cites2 rank_persist, matrix  listwise
esttab using "..\Results\rank_correlations.csv", replace  title("Rank Correlations") unstack not noobs nonote b(3) label 




  
  
//****************Additional Table 3 - ACCURACY BY FDP TRAIT **************// 
generate ln_ea_cashtag_tweets=ln(ea_cashtag_tweets+1)
winsor ln_ea_cashtag_tweets, p(.01) gen(ln_ea_cashtag_tweets_w1)

generate ln_n_articles=ln(n_articles+1)
winsor ln_n_articles, p(.01) gen(ln_n_articles_w1)

eststo clear

eststo, title("FDP Experience"): reghdfe unsigned_error i.fdp_num rank_exp, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Following"): reghdfe unsigned_error i.fdp_num rank_following, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Agreement"): reghdfe unsigned_error i.fdp_num actual_agree, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Street Non-GAAP"): reghdfe unsigned_error i.fdp_num comp_gaapvstreet_diff, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Twitter"): reghdfe unsigned_error i.fdp_num rank_tweets1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Twitter 2"): reghdfe unsigned_error i.fdp_num rank_tweets2, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Media"): reghdfe unsigned_error i.fdp_num rank_cites, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Media 2"): reghdfe unsigned_error i.fdp_num rank_cites2, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Predict"): reghdfe unsigned_error i.fdp_num rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP All"): reghdfe unsigned_error i.fdp_num rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist , nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP All"): reghdfe unsigned_error i.fdp_num rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr)



eststo, title("FDP Experience"): reghdfe unsigned_error i.fdp_num rank_exp $controls, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Following"): reghdfe unsigned_error i.fdp_num rank_following $controls, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Agreement"): reghdfe unsigned_error i.fdp_num actual_agree $controls, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Street Non-GAAP"): reghdfe unsigned_error i.fdp_num comp_gaapvstreet_diff $controls, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Twitter"): reghdfe unsigned_error i.fdp_num rank_tweets1 $controls ln_ea_cashtag_tweets_w1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Twitter 2"): reghdfe unsigned_error i.fdp_num rank_tweets2 $controls ln_ea_cashtag_tweets_w1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Media"): reghdfe unsigned_error i.fdp_num rank_cites $controls ln_n_articles_w1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Media 2"): reghdfe unsigned_error i.fdp_num rank_cites2 $controls ln_n_articles_w1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Predict"): reghdfe unsigned_error i.fdp_num rank_persist $controls, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP All"): reghdfe unsigned_error i.fdp_num rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP All"): reghdfe unsigned_error i.fdp_num rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)

esttab using "..\Results\tableA3.csv", replace  ///
 title("Accuracy FDP Traits") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
//****************Additional Table 4 - PREDICTIVE ABILITY BY FDP TRAIT **************// 

/*Operating Earnings*/
eststo clear

eststo, title("FDP Experience"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_exp rank_exp, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Following"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_following rank_following, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Agreement"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.actual_agree actual_agree, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Street Non-GAAP"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.comp_gaapvstreet_diff comp_gaapvstreet_diff, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets1 rank_tweets1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter 2"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets2 rank_tweets2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_cites rank_cites, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media 2"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_cites2 rank_cites2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Persist"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_persist rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.rank_persist c.earnings#c.comp_gaapvstreet_diff /// 
		c.earnings#c.rank_tweets1 c.earnings#c.rank_cites ///
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num) 
eststo, title("FDP All"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.rank_persist c.earnings#c.comp_gaapvstreet_diff /// 
		c.earnings#c.rank_tweets2 c.earnings#c.rank_cites2 ///
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num) 



eststo, title("FDP Experience"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_exp rank_exp $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Following"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_following rank_following $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Agreement"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.actual_agree actual_agree $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Street Non-GAAP"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.comp_gaapvstreet_diff comp_gaapvstreet_diff $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets1 rank_tweets1 $controls ln_ea_cashtag_tweets_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter 2"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets2 rank_tweets2 $controls ln_ea_cashtag_tweets_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_cites rank_cites $controls ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media 2"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_cites2 rank_cites2 $controls ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Persist"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_persist rank_persist $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.comp_gaapvstreet_diff ///
		c.earnings#c.rank_tweets1 c.earnings#c.rank_cites c.earnings#c.rank_persist  /// 
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.comp_gaapvstreet_diff ///
		c.earnings#c.rank_tweets2 c.earnings#c.rank_cites2 c.earnings#c.rank_persist  /// 
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

		
esttab using "..\Results\tableA4A.csv", replace  ///
 title("Predict Future Earn FDP Traits") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 /*Operating CF*/
eststo clear

eststo, title("FDP Experience"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_exp rank_exp, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Following"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_following rank_following, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Agreement"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.actual_agree actual_agree, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Street Non-GAAP"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.comp_gaapvstreet_diff comp_gaapvstreet_diff, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets1 rank_tweets1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter 2"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets2 rank_tweets2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_cites rank_cites, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media 2"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_cites2 rank_cites2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Persist"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_persist rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.rank_persist c.earnings#c.comp_gaapvstreet_diff /// 
		c.earnings#c.rank_tweets1 c.earnings#c.rank_cites ///
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num) 
eststo, title("FDP All"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.rank_persist c.earnings#c.comp_gaapvstreet_diff /// 
		c.earnings#c.rank_tweets2 c.earnings#c.rank_cites2 ///
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num) 



eststo, title("FDP Experience"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_exp rank_exp $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Following"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_following rank_following $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Agreement"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.actual_agree actual_agree $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Street Non-GAAP"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.comp_gaapvstreet_diff comp_gaapvstreet_diff $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets1 rank_tweets1 $controls ln_ea_cashtag_tweets_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter 2"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets2 rank_tweets2 $controls ln_ea_cashtag_tweets_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_cites rank_cites $controls ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media 2"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_cites2 rank_cites2 $controls ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Persist"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_persist rank_persist $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.comp_gaapvstreet_diff ///
		c.earnings#c.rank_tweets1 c.earnings#c.rank_cites c.earnings#c.rank_persist  /// 
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.comp_gaapvstreet_diff ///
		c.earnings#c.rank_tweets2 c.earnings#c.rank_cites2 c.earnings#c.rank_persist  /// 
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

		
esttab using "..\Results\tableA4B.csv", replace  ///
 title("Predict Future CF FDP Traits") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3))   
 
 
 
 
//****************Additional Table 5 - ERC BY FDP TRAIT **************// 
/*ERC*/
eststo clear

eststo, title("FDP Experience"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_exp rank_exp, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Following"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_following rank_following, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Agreement"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.actual_agree actual_agree, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Street Non-GAAP"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.comp_gaapvstreet_diff comp_gaapvstreet_diff, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_tweets1 rank_tweets1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter 2"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_tweets2 rank_tweets2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_cites rank_cites, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media 2"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_cites2 rank_cites2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Persist"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_persist rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_exp c.surp_u_price#c.rank_following c.surp_u_price#c.actual_agree c.surp_u_price#c.rank_persist c.surp_u_price#c.comp_gaapvstreet_diff /// 
		c.surp_u_price#c.rank_tweets1 c.surp_u_price#c.rank_cites ///
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num) 
eststo, title("FDP All"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_exp c.surp_u_price#c.rank_following c.surp_u_price#c.actual_agree c.surp_u_price#c.rank_persist c.surp_u_price#c.comp_gaapvstreet_diff /// 
		c.surp_u_price#c.rank_tweets2 c.surp_u_price#c.rank_cites2 ///
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num) 



eststo, title("FDP Experience"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_exp rank_exp $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Following"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_following rank_following $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Agreement"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.actual_agree actual_agree $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Street Non-GAAP"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.comp_gaapvstreet_diff comp_gaapvstreet_diff $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_tweets1 rank_tweets1 $controls ln_ea_cashtag_tweets_w1 c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 c.surp_u_price#c.ln_ea_cashtag_tweets_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter 2"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_tweets2 rank_tweets2 $controls ln_ea_cashtag_tweets_w1 c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 c.surp_u_price#c.ln_ea_cashtag_tweets_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_cites rank_cites $controls ln_n_articles_w1 c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 c.surp_u_price#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media 2"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_cites2 rank_cites2 $controls ln_n_articles_w1 c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 c.surp_u_price#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Persist"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_persist rank_persist $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_exp c.surp_u_price#c.rank_following c.surp_u_price#c.actual_agree c.surp_u_price#c.comp_gaapvstreet_diff ///
		c.surp_u_price#c.rank_tweets1 c.surp_u_price#c.rank_cites c.surp_u_price#c.rank_persist  /// 
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1 c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 c.surp_u_price#c.ln_ea_cashtag_tweets_w1 c.surp_u_price#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_exp c.surp_u_price#c.rank_following c.surp_u_price#c.actual_agree c.surp_u_price#c.comp_gaapvstreet_diff ///
		c.surp_u_price#c.rank_tweets2 c.surp_u_price#c.rank_cites2 c.surp_u_price#c.rank_persist  /// 
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1 c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 c.surp_u_price#c.ln_ea_cashtag_tweets_w1 c.surp_u_price#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

		
esttab using "..\Results\tableA5.csv", replace  ///
 title("ERC FDP Traits") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 
 
 
 
 
 
 
/************************************SET MISSING RANK VARIABLES TO ZERO**************************************/
replace rank_exp=0 if rank_exp==.
replace rank_tweets1=0 if rank_tweets1==.
replace rank_tweets2=0 if rank_tweets2==.
replace rank_cites=0 if rank_cites==.
replace rank_cites2=0 if rank_cites2==.
replace rank_persist=0 if rank_persist==.
replace ln_ea_cashtag_tweets_w1=0 if ln_ea_cashtag_tweets_w1==.
replace ln_n_articles_w1=0 if ln_n_articles_w1==.


//****************Additional Table 2 - FDP TRAITS **************// 
/*Rank Experience*/
eststo clear
eststo ibes: estpost tabulate rank_exp if fdp_num==1
eststo zacks: estpost tabulate rank_exp if fdp_num==2
eststo ciq: estpost tabulate rank_exp if fdp_num==3
eststo bb: estpost tabulate rank_exp if fdp_num==4
eststo fset: estpost tabulate rank_exp if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\rank_exp2.csv", replace  title("Rank Experience2") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label 


/*Rank Tweets*/
eststo clear
eststo ibes: estpost tabulate rank_tweets1 if fdp_num==1
eststo zacks: estpost tabulate rank_tweets1 if fdp_num==2
eststo ciq: estpost tabulate rank_tweets1 if fdp_num==3
eststo bb: estpost tabulate rank_tweets1 if fdp_num==4
eststo fset: estpost tabulate rank_tweets1 if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\rank_tweets1v2.csv", replace  title("Rank Tweets1v2") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label  


/*Rank Tweets2*/
eststo clear
eststo ibes: estpost tabulate rank_tweets2 if fdp_num==1
eststo zacks: estpost tabulate rank_tweets2 if fdp_num==2
eststo ciq: estpost tabulate rank_tweets2 if fdp_num==3
eststo bb: estpost tabulate rank_tweets2 if fdp_num==4
eststo fset: estpost tabulate rank_tweets2 if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\rank_tweets2v2.csv", replace  title("Rank Tweets2v2") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label  


/*Rank Media Cites*/
eststo clear
eststo ibes: estpost tabulate rank_cites if fdp_num==1
eststo zacks: estpost tabulate rank_cites if fdp_num==2
eststo ciq: estpost tabulate rank_cites if fdp_num==3
eststo bb: estpost tabulate rank_cites if fdp_num==4
eststo fset: estpost tabulate rank_cites if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\rank_cites1v2.csv", replace  title("Rank Media Cites1v2") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label    


/*Rank Media Cites 2*/
eststo clear
eststo ibes: estpost tabulate rank_cites2 if fdp_num==1
eststo zacks: estpost tabulate rank_cites2 if fdp_num==2
eststo ciq: estpost tabulate rank_cites2 if fdp_num==3
eststo bb: estpost tabulate rank_cites2 if fdp_num==4
eststo fset: estpost tabulate rank_cites2 if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\rank_cites2v2.csv", replace  title("Rank Media Cites2v2") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label    


/*Rank Predctive Ability*/
eststo clear
eststo ibes: estpost tabulate rank_persist if fdp_num==1
eststo zacks: estpost tabulate rank_persist if fdp_num==2
eststo ciq: estpost tabulate rank_persist if fdp_num==3
eststo bb: estpost tabulate rank_persist if fdp_num==4
eststo fset: estpost tabulate rank_persist if fdp_num==5 

//preview the output
esttab ibes zacks ciq bb fset , replace noobs cells("pct(fmt(%9.2fc))") label 

//output the table to excel
esttab ibes zacks ciq bb fset using "..\Results\rank_persist2.csv", replace  title("Rank Predctive Ability2") cells("pct(fmt(%9.2fc))") compress  nomtitles noobs label      



/*Rank Variable Correlations*/
eststo clear
estpost correlate rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_tweets2 rank_cites rank_cites2 rank_persist, matrix  listwise
esttab using "..\Results\rank_correlations2.csv", replace  title("Rank Correlations2") unstack not noobs nonote b(3) label 


//****************Additional Table 3 - ACCURACY BY FDP TRAIT **************// 
eststo clear

eststo, title("FDP Experience"): reghdfe unsigned_error i.fdp_num rank_exp, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Following"): reghdfe unsigned_error i.fdp_num rank_following, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Agreement"): reghdfe unsigned_error i.fdp_num actual_agree, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Street Non-GAAP"): reghdfe unsigned_error i.fdp_num comp_gaapvstreet_diff, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Twitter"): reghdfe unsigned_error i.fdp_num rank_tweets1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Twitter 2"): reghdfe unsigned_error i.fdp_num rank_tweets2, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Media"): reghdfe unsigned_error i.fdp_num rank_cites, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Media 2"): reghdfe unsigned_error i.fdp_num rank_cites2, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Predict"): reghdfe unsigned_error i.fdp_num rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP All"): reghdfe unsigned_error i.fdp_num rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist , nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP All"): reghdfe unsigned_error i.fdp_num rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr)



eststo, title("FDP Experience"): reghdfe unsigned_error i.fdp_num rank_exp $controls, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Following"): reghdfe unsigned_error i.fdp_num rank_following $controls, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Agreement"): reghdfe unsigned_error i.fdp_num actual_agree $controls, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Street Non-GAAP"): reghdfe unsigned_error i.fdp_num comp_gaapvstreet_diff $controls, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Twitter"): reghdfe unsigned_error i.fdp_num rank_tweets1 $controls ln_ea_cashtag_tweets_w1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Twitter 2"): reghdfe unsigned_error i.fdp_num rank_tweets2 $controls ln_ea_cashtag_tweets_w1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Media"): reghdfe unsigned_error i.fdp_num rank_cites $controls ln_n_articles_w1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Media 2"): reghdfe unsigned_error i.fdp_num rank_cites2 $controls ln_n_articles_w1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP Predict"): reghdfe unsigned_error i.fdp_num rank_persist $controls, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP All"): reghdfe unsigned_error i.fdp_num rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)
eststo, title("FDP All"): reghdfe unsigned_error i.fdp_num rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1, nocons cluster(gvkey best_anndats)  absorb(yearqtr)

esttab using "..\Results\tableA3v2.csv", replace  ///
 title("Accuracy FDP Traits") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
//****************Additional Table 4 - PREDICTIVE ABILITY BY FDP TRAIT **************// 

/*Operating Earnings*/
eststo clear

eststo, title("FDP Experience"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_exp rank_exp, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Following"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_following rank_following, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Agreement"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.actual_agree actual_agree, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Street Non-GAAP"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.comp_gaapvstreet_diff comp_gaapvstreet_diff, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets1 rank_tweets1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter 2"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets2 rank_tweets2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_cites rank_cites, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media 2"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_cites2 rank_cites2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Persist"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_persist rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.rank_persist c.earnings#c.comp_gaapvstreet_diff /// 
		c.earnings#c.rank_tweets1 c.earnings#c.rank_cites ///
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num) 
eststo, title("FDP All"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.rank_persist c.earnings#c.comp_gaapvstreet_diff /// 
		c.earnings#c.rank_tweets2 c.earnings#c.rank_cites2 ///
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num) 



eststo, title("FDP Experience"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_exp rank_exp $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Following"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_following rank_following $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Agreement"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.actual_agree actual_agree $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Street Non-GAAP"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.comp_gaapvstreet_diff comp_gaapvstreet_diff $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets1 rank_tweets1 $controls ln_ea_cashtag_tweets_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter 2"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets2 rank_tweets2 $controls ln_ea_cashtag_tweets_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_cites rank_cites $controls ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media 2"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_cites2 rank_cites2 $controls ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Persist"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_persist rank_persist $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.comp_gaapvstreet_diff ///
		c.earnings#c.rank_tweets1 c.earnings#c.rank_cites c.earnings#c.rank_persist  /// 
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe future_op_earn earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.comp_gaapvstreet_diff ///
		c.earnings#c.rank_tweets2 c.earnings#c.rank_cites2 c.earnings#c.rank_persist  /// 
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

		
esttab using "..\Results\tableA4Av2.csv", replace  ///
 title("Predict Future Earn FDP Traits") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 /*Operating CF*/
eststo clear

eststo, title("FDP Experience"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_exp rank_exp, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Following"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_following rank_following, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Agreement"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.actual_agree actual_agree, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Street Non-GAAP"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.comp_gaapvstreet_diff comp_gaapvstreet_diff, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets1 rank_tweets1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter 2"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets2 rank_tweets2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_cites rank_cites, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media 2"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_cites2 rank_cites2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Persist"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_persist rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.rank_persist c.earnings#c.comp_gaapvstreet_diff /// 
		c.earnings#c.rank_tweets1 c.earnings#c.rank_cites ///
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num) 
eststo, title("FDP All"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.rank_persist c.earnings#c.comp_gaapvstreet_diff /// 
		c.earnings#c.rank_tweets2 c.earnings#c.rank_cites2 ///
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num) 



eststo, title("FDP Experience"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_exp rank_exp $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Following"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_following rank_following $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Agreement"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.actual_agree actual_agree $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Street Non-GAAP"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.comp_gaapvstreet_diff comp_gaapvstreet_diff $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets1 rank_tweets1 $controls ln_ea_cashtag_tweets_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter 2"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_tweets2 rank_tweets2 $controls ln_ea_cashtag_tweets_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_cites rank_cites $controls ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media 2"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_cites2 rank_cites2 $controls ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Persist"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_persist rank_persist $controls c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.comp_gaapvstreet_diff ///
		c.earnings#c.rank_tweets1 c.earnings#c.rank_cites c.earnings#c.rank_persist  /// 
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe future_op_cf earnings c.earnings#i.fdp_num c.earnings#c.rank_exp c.earnings#c.rank_following c.earnings#c.actual_agree c.earnings#c.comp_gaapvstreet_diff ///
		c.earnings#c.rank_tweets2 c.earnings#c.rank_cites2 c.earnings#c.rank_persist  /// 
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1 c.earnings#c.lnmve c.earnings#c.btm c.earnings#c.io ///
		c.earnings#c.unique_following c.earnings#c.guidance c.earnings#c.dispersion c.earnings#c.percent_change_ibq  ///
		c.earnings#c.percent_change_cshfdq c.earnings#c.stock_split c.earnings#c.comp_gaapvstreet_diff c.earnings#c.abs_spiq_ibq c.earnings#c.ret_vol ///
		c.earnings#c.log_lagmins c.earnings#c.q4 c.earnings#c.ln_ea_cashtag_tweets_w1 c.earnings#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

		
esttab using "..\Results\tableA4Bv2.csv", replace  ///
 title("Predict Future CF FDP Traits") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3))   
 
 
 
 
//****************Additional Table 5 - ERC BY FDP TRAIT **************// 
/*ERC*/
eststo clear

eststo, title("FDP Experience"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_exp rank_exp, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Following"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_following rank_following, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Agreement"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.actual_agree actual_agree, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Street Non-GAAP"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.comp_gaapvstreet_diff comp_gaapvstreet_diff, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_tweets1 rank_tweets1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter 2"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_tweets2 rank_tweets2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_cites rank_cites, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media 2"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_cites2 rank_cites2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Persist"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_persist rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_exp c.surp_u_price#c.rank_following c.surp_u_price#c.actual_agree c.surp_u_price#c.rank_persist c.surp_u_price#c.comp_gaapvstreet_diff /// 
		c.surp_u_price#c.rank_tweets1 c.surp_u_price#c.rank_cites ///
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num) 
eststo, title("FDP All"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_exp c.surp_u_price#c.rank_following c.surp_u_price#c.actual_agree c.surp_u_price#c.rank_persist c.surp_u_price#c.comp_gaapvstreet_diff /// 
		c.surp_u_price#c.rank_tweets2 c.surp_u_price#c.rank_cites2 ///
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num) 



eststo, title("FDP Experience"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_exp rank_exp $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Following"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_following rank_following $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Agreement"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.actual_agree actual_agree $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Street Non-GAAP"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.comp_gaapvstreet_diff comp_gaapvstreet_diff $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_tweets1 rank_tweets1 $controls ln_ea_cashtag_tweets_w1 c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 c.surp_u_price#c.ln_ea_cashtag_tweets_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Twitter 2"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_tweets2 rank_tweets2 $controls ln_ea_cashtag_tweets_w1 c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 c.surp_u_price#c.ln_ea_cashtag_tweets_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_cites rank_cites $controls ln_n_articles_w1 c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 c.surp_u_price#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Media 2"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_cites2 rank_cites2 $controls ln_n_articles_w1 c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 c.surp_u_price#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP Persist"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_persist rank_persist $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_exp c.surp_u_price#c.rank_following c.surp_u_price#c.actual_agree c.surp_u_price#c.comp_gaapvstreet_diff ///
		c.surp_u_price#c.rank_tweets1 c.surp_u_price#c.rank_cites c.surp_u_price#c.rank_persist  /// 
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets1 rank_cites rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1 c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 c.surp_u_price#c.ln_ea_cashtag_tweets_w1 c.surp_u_price#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("FDP All"): reghdfe car_n1top1 surp_u_price c.surp_u_price#i.fdp_num c.surp_u_price#c.rank_exp c.surp_u_price#c.rank_following c.surp_u_price#c.actual_agree c.surp_u_price#c.comp_gaapvstreet_diff ///
		c.surp_u_price#c.rank_tweets2 c.surp_u_price#c.rank_cites2 c.surp_u_price#c.rank_persist  /// 
		rank_exp rank_following actual_agree comp_gaapvstreet_diff rank_tweets2 rank_cites2 rank_persist $controls ln_ea_cashtag_tweets_w1 ln_n_articles_w1 c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 c.surp_u_price#c.ln_ea_cashtag_tweets_w1 c.surp_u_price#c.ln_n_articles_w1 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

		
esttab using "..\Results\tableA5v2.csv", replace  ///
 title("ERC FDP Traits") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3)) 
 
 
 


 
  
 
//****************Additional Table 6 - DRIFT HORSE RACE **************// 
 winsor bahr_p2top61, p(.01) gen(bahr_p2top61_w1)

eststo clear

eststo, title("Full Sample"): reghdfe bahr_p2top61_w1 surp_u_price c.surp_u_price#i.fdp_num, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("2002 to 2006"): reghdfe bahr_p2top61_w1 surp_u_price c.surp_u_price#i.fdp_num if period==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("2007 to 2011"): reghdfe bahr_p2top61_w1 surp_u_price c.surp_u_price#i.fdp_num if period==2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
eststo, title("2012 to 2016"): reghdfe bahr_p2top61_w1 surp_u_price c.surp_u_price#i.fdp_num if period==3, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Full Sample"): reghdfe bahr_p2top61_w1 surp_u_price c.surp_u_price#i.fdp_num $controls , nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)

eststo, title("Full Sample"): reghdfe bahr_p2top61_w1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("2002 to 2006"): reghdfe bahr_p2top61_w1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		if period==1, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)	
		
eststo, title("2007 to 2011"): reghdfe bahr_p2top61_w1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		if period==2, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)
		
eststo, title("2012 to 2016"): reghdfe bahr_p2top61_w1 surp_u_price c.surp_u_price#i.fdp_num $controls c.surp_u_price#c.lnmve c.surp_u_price#c.btm c.surp_u_price#c.io ///
		c.surp_u_price#c.unique_following c.surp_u_price#c.guidance c.surp_u_price#c.dispersion c.surp_u_price#c.percent_change_ibq  ///
		c.surp_u_price#c.percent_change_cshfdq c.surp_u_price#c.stock_split c.surp_u_price#c.comp_gaapvstreet_diff c.surp_u_price#c.abs_spiq_ibq c.surp_u_price#c.ret_vol ///
		c.surp_u_price#c.log_lagmins c.surp_u_price#c.q4 ///
		if period==3, nocons cluster(gvkey best_anndats)  absorb(yearqtr#fdp_num)


esttab using "..\Results\tablea6.csv", replace  ///
 title("Drift Horserace") ///
  drop(1.fdp_num*) /// drops the baseline empty reference category 
 mtitles label ///
 b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a, fmt (%20.0g 3))