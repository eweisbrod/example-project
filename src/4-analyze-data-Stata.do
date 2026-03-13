/******************************************************************************/
*SETUP*

// SHARING CODE WITH COAUTHORS USING .env FILES
//
// WHAT IS A .env FILE?
// A .env file is a simple text file that stores configuration variables like
// file paths. Each line has the format: VARIABLE_NAME=value
//
// WHY USE IT?
// - Your code doesn't contain hardcoded paths specific to your computer
// - Coauthors can run the same code by creating their own .env file
// - Better for sharing code publicly (e.g., journal submissions)
// - The .env file is gitignored so each person has their own local copy
// - The same .env file works across R, Python, and Stata
//
// FIRST-TIME SETUP (only needs to be done once per computer):
//
// Step 1: Install the two Stata packages we use for this:
//   - projectpaths: manages project root directories across machines
//   - doenv: loads .env files into Stata
// Uncomment and run these two lines to install them:
//   net install projectpaths, from("https://raw.githubusercontent.com/eweisbrod/projectpaths/main/src/") replace
//   net install doenv, from("https://github.com/vikjam/doenv/raw/master/") replace
//
// Step 2: Register this project with projectpaths.
// Copy this line to your Stata console and replace the path with YOUR path
// to wherever you cloned this repository:
//   project_paths_list, add project(example-project) path("C:\_git\example-project")
//
// Step 3: Edit the .env file in the project root directory.
// Open it in any text editor (e.g., Notepad) and change the DATA_DIR path
// to wherever you want to store your data. Use FORWARD slashes even on Windows:
//   DATA_DIR=D:/Dropbox/example-project
//
// That's it! After this one-time setup, the code below will just work.
// Each coauthor does the same three steps with their own paths.
//
// ALTERNATIVE: If you find the above too complicated and you don't have
// coauthors, you can skip all of this and just uncomment and edit one line:
//   local data_dir "D:/Dropbox/example-project"
// Then comment out the three lines below (project_paths_list, doenv, local).


// Navigate to the project root directory using projectpaths
project_paths_list, project(example-project) cd

// Load environment variables from the .env file
doenv using ".env"

// Store the data directory path in a local macro
local data_dir "`r(DATA_DIR)'"

// Display to verify it loaded correctly (optional, can comment out)
display "Using data directory: `data_dir'"

//I plan to save the output tables to a subfolder called output
//you need to create this directory if you would like to follow my example.
//You can do it manually or you can uncomment and run the below line
//mkdir "`data_dir'/output"
//You only need to do this once the first time you run the code.


/******************************************************************************/
*LOAD DATA*
use "`data_dir'/regdata-sas.dta" , clear


// NOTE: Because we use projectpaths + doenv to load paths from the .env file,
// all file references use the `data_dir' local macro. This means the code will
// work on any computer without modification -- each coauthor just needs their
// own .env file with their local data path.


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

label var roa_lead_1 "\$ROA_{t+1}\$"
label var roa "\$ROA_t\$"
label var loss "\$LOSS\$"
label var rd "\$R\&D\$"
label var at "\$TA\$"
label var mve "\$SIZE\$"

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

//Other packages you need to fully run this example
// ssc install reghdfe
// ssc install erepost

//estout reference material links
// https://repec.sowi.unibe.ch/stata/estout/
// http://repec.org/bocode/e/estout/advanced.html

//clear out any previously stored results
eststo clear

//tabulate the data 
estpost tabulate subperiod loss


//preview the output
esttab, cell(b(fmt(%9.0fc)) rowpct(fmt(2) par)) ///
     collabels("(%)") unstack noobs nonumber nomtitle    ///
     eqlabels(, lhs("Sub-Period"))                     

//output the table to Latex
esttab using "`data_dir'/output/freq-stata.tex", replace compress booktabs ///
	 cell(b(fmt(%9.0fc)) rowpct(fmt(2) par)) ///
     collabels("(\%)") unstack noobs nonumber nomtitle    ///
     eqlabels(, lhs("Sub-Period")) ///
	 substitute(\_ _)


//output the table to Word
esttab using "`data_dir'/output/freq-stata.rtf", replace ///
	 cell(b(fmt(%9.0fc)) rowpct(fmt(2) par)) ///
     collabels("(%)") unstack noobs nonumber nomtitle    ///
     eqlabels(, lhs("Sub-Period"))                    

//output the table to excel
// don't use comma-format numbers in the excel file unless you research special
// options, because the excel is a csv file and it will break at the commas
esttab using "`data_dir'/output/freq-stata.csv", replace ///
	 cell(b(fmt(%9.0f)) rowpct(fmt(2) par)) /// f format instead of fc
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


/******************************************************************************/
*Table 2 - Descriptive Statistics*


//clear out any previously stored results
eststo clear

//summarize the data
estpost summarize roa_lead_1 roa loss $controls ///
		, detail

//preview the output
esttab . , replace noobs nonumbers label ///
cells("count(fmt(%9.0fc)) mean(fmt(%9.3fc)) p50(fmt(%9.3fc)) sd(fmt(%9.3fc)) p25(fmt(%9.3fc)) p75(fmt(%9.3fc))") compress

//output the table to LaTeX
esttab using "`data_dir'/output/descrip-stata.tex", replace compress booktabs ///
cells("count(fmt(%9.0fc)) mean(fmt(%9.3fc)) p50(fmt(%9.3fc)) sd(fmt(%9.3fc)) p25(fmt(%9.3fc)) p75(fmt(%9.3fc))") ///
 title("Descriptive Statistics") ///
 nomtitles nonumbers noobs label ///
 substitute(\_ _)
 

//output the table to Word
esttab using "`data_dir'/output/descrip-stata.rtf", replace ///
cells("count(fmt(%9.0fc)) mean(fmt(%9.3fc)) p50(fmt(%9.3fc)) sd(fmt(%9.3fc)) p25(fmt(%9.3fc)) p75(fmt(%9.3fc))") compress ///
 title("Descriptive Statistics") ///
 nomtitles nonumbers noobs label 
 
 //output the table to excel
esttab using "`data_dir'/output/descrip-stata.csv", replace ///
cells("count(fmt(%9.0f)) mean(fmt(%9.3f)) p50(fmt(%9.3f)) sd(fmt(%9.3f)) p25(fmt(%9.3f)) p75(fmt(%9.3f))") compress ///
 title("Descriptive Statistics") ///
 nomtitles nonumbers noobs label 

/******************************************************************************/
*Table 3 - Regression*


//clear out any previously stored results
eststo clear

//Run first-column regression and store results
eststo m1, title("Base"): reghdfe roa_lead_1 roa, cluster(gvkey calyear)  noabsorb
eststo m2, title("No FE"): reghdfe roa_lead_1 c.roa##i.loss, cluster(gvkey calyear)  noabsorb
eststo m3, title("Year FE"): reghdfe roa_lead_1 c.roa##i.loss, cluster(gvkey calyear)  absorb(calyear)
eststo m4, title("Twoway FE"): reghdfe roa_lead_1 c.roa##i.loss, cluster(gvkey calyear)  absorb(firm_fe calyear)
eststo m5, title("With Controls"): reghdfe roa_lead_1 c.roa##i.loss $controls, cluster(gvkey calyear)  absorb(firm_fe calyear)

// Here is a trick from the author of reghdfe to add FE indicator rows
// http://scorreia.com/software/reghdfe/faq.html#how-can-i-combine-reghdfe-with-esttab-or-estout
// use reghdfe's built in estfe command
	estfe . m* , labels(calyear "Year FE" firm_fe "Firm FE")
	return list

//if you want to drop some of the coefficients from the output
// it can be helpful to look at what stata is calling them using this command
//matrix list e(b)
//you should do this after running the most complex model probably
//I can see that the variables for the empty reference categories start with 0
//so i will drop anything that starts with zero
//if you wanted to surpress displaying the controls in the table, you can add
// $controls do the drop() option below or use the indicate command

//preview the output
esttab, ///
drop(0* _cons) /// drops the baseline empty reference categories and constant 
 mtitles label ///
 title("Regression Table") ///
 varlabels(1.loss#c.roa "Loss x ROA_t") ///
 indicate( "Controls=$controls" `r(indicate_fe)') /// adds indicator rows
  b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a r2_a_within, fmt (%20.0gc 3) labels("N" "Adj. R-Square" "Adj. R-Square (within)"))

 
 
//seems like you have to rerun this before each esttab call
	estfe . m* , labels(calyear "Year FE" firm_fe "Firm FE")
	return list
//Output to Latex
esttab using "`data_dir'/output/regression-stata.tex", replace compress booktabs ///
 substitute(\_ _ _cons Constant) /// 
drop(0* _cons) /// drops the baseline empty reference categories and constant 
 mtitles label nolegend nonotes ///
 title("Regression Table") ///
 varlabels(1.loss "\$LOSS\$" 1.loss#c.roa "\$ LOSS \times ROA_{t}\$") ///
 indicate( "Controls=$controls" `r(indicate_fe)') /// adds indicator rows
  b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a r2_a_within, fmt (%20.0gc 3) labels("N" "Adj. R-Square" "Adj. R-Square (within)"))

 
 
 //seems like you have to rerun this before each esttab call
	estfe . m* , labels(calyear "Year FE" firm_fe "Firm FE")
	return list
	
//Output to Word
esttab using "`data_dir'/output/regression-stata.rtf", replace ///
drop(0* _cons) /// drops the baseline empty reference categories and constant 
 mtitles label nolegend nonotes ///
 title("Regression Table") ///
 varlabels(1.loss#c.roa "Loss x ROA_t") ///
 indicate( "Controls=$controls" `r(indicate_fe)') /// adds indicator rows
  b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a r2_a_within, fmt (%20.0gc 3) labels("N" "Adj. R-Square" "Adj. R-Square (within)"))

 //seems like you have to rerun this before each esttab call
	estfe . m* , labels(calyear "Year FE" firm_fe "Firm FE")
	return list
	
//Output to Excel
esttab using "`data_dir'/output/regression-stata.csv", replace ///
drop(0* _cons) /// drops the baseline empty reference categories and constant 
 mtitles label nolegend nonotes ///
 title("Regression Table") ///
 varlabels(1.loss#c.roa "Loss x ROA_t") ///
 indicate( "Controls=$controls" `r(indicate_fe)') /// adds indicator rows
  b(3) t(2) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 stats(N r2_a r2_a_within, fmt (%20.0g 3) labels("N" "Adj. R-Square" "Adj. R-Square (within)"))

