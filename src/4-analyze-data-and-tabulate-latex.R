# Setup ------------------------------------------------------------------------

# Load Libraries [i.e., packages]
library(modelsummary)
library(sjlabelled)
library(kableExtra)
library(formattable)
library(lubridate)
library(glue)
library(haven)
library(fixest)
library(tictoc) #very optional, mostly as a teaching example
library(tidyverse) # I like to load tidyverse last to avoid package conflicts


#load helper scripts
source("src/-Global-Parameters.R")
source("src/utils.R")

#Set this option for the modelsummary output
options(modelsummary_format_numeric_latex = "plain")

# read in the data from the previous step --------------------------------------

#read in the winsorized data
#I found there are not many firms in the 60s so I am just going to start at 1970
regdata <- read_dta(glue("{data_path}/regdata-R.dta")) |> 
  select(gvkey,datadate,calyear,roa,roa_lead_1,loss,at,mve,rd,FF12,ff12num) |> 
  #add variable labels 
  sjlabelled::var_labels(
    roa_lead_1 = "$ROA_{t+1}$",
    roa = "$ROA_t$",
    loss = "$LOSS$",
    rd = "$R\\&D$",
    at = "$TA$",
    mve = "$SIZE$"
  )





# Observations by Decade -------------------------------------------------------

#Goal is to show how to export a basic manual table or data frame into 
# a paper
#At first I did this simply by year but it was too long
#So, I am going to manually group by decade

#basic table
table1 <- regdata |> 
  #use case_when to group calyears into decades with labels
  mutate(Year = case_when(
    calyear %in% 1970:1979 ~ "1970 - 1979",
    calyear %in% 1980:1989 ~ "1980 - 1989",
    calyear %in% 1990:1999 ~ "1990 - 1999",
    calyear %in% 2000:2009 ~ "2000 - 2009",
    calyear %in% 2010:2019 ~ "2010 - 2019",
    calyear >= 2020 ~ "2020 - 2022")
  ) |> 
  group_by(Year) |> 
  #within each year, count the obs and calculate loss percentage
  summarize(`Total Firms` = formattable::comma(n(), digits=0),
            `Loss Firms` = formattable::comma(sum(loss),digits=0),
            `Pct. Losses` = formattable::percent(sum(loss)/n(), digits=2)
            )



#add a total row
totalrow <- regdata |> 
  summarize(`Total Firms` = formattable::comma(n(), digits=0),
            `Loss Firms` = formattable::comma(sum(loss),digits=0),
            `Pct. Losses` = formattable::percent(sum(loss)/n(), digits=2)
  )|> 
  mutate(Year = "Total")

#bind together the existing and total rows
table1 <- bind_rows(table1, totalrow) 

#look at the dataframe 
table1

#use the KableExtra package to create a latex version of the table
kbl(table1,
     format = "latex",
    booktabs = T,
    linesep = "") |> 
  save_kable(glue("{data_path}/output/freqtable-r.tex"))


# Table 2 Descriptive Stats ----------------------------------------------------

#other interesting data summary packages
# gtsummary
# skimr
# psych
# arsenal

##Create formatting functions --------------------------------------------------

#set number formats for descriptive table
my_fmt <- function(x) formattable::comma(x, digits=3)


#N function to handle special format for N with no decimals 
NN <- function(x) {
  out <-  if (is.logical(x) && all(is.na(x))) {
    length(x)
    # number of non-missing observations
  } else {
    sum(!is.na(x))
  }
  out <- formattable::comma(out, digits=0)
  return(out)
}

#for regression N observations
nobs_fmt <- function(x) {
  out <- formattable::comma(x, digits=0)
  out <- paste0("\\multicolumn{1}{c}{",out,"}")
}

#for regression output
gm <- list(
  list("raw" = "nobs", "clean" = "N", "fmt" = nobs_fmt),
  list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = 3),
  list("raw" = "r2.within", "clean" = "$R^2$ Within", "fmt" = 3)
)


#If you make a subset of the data 
#you can handle the variable labels with sjlabelled 
descripdata <- regdata |>
  select(
  roa_lead_1,
  roa,
  loss,
  rd,
  at,
  mve) |> 
  label_to_colnames()


#Run the datasummary function 
# see the documentation for how the formulas work
# basically put variables on one side of the ~ and stats on the other

datasummary( All(descripdata) ~ (N = NN) + Mean * Arguments(fmt = my_fmt) + 
               SD * Arguments(fmt = my_fmt) + 
               Min * Arguments(fmt = my_fmt) + 
               P25 * Arguments(fmt = my_fmt) + 
               Median * Arguments(fmt = my_fmt) + 
               P75 * Arguments(fmt = my_fmt) + 
               Max * Arguments(fmt = my_fmt), 
             # use escape = F to pass the latex formatting along  
             escape = F,
             output = 'latex',
             data = descripdata) |> 
  save_kable(glue("{data_path}/output/descrip-r.tex"))
#Here I save the output to a tex file, but you could also just remove the last
#line and cut and paste the output from the console into Overleaf.

# Table 3: Correlation Matrix --------------------------------------------------

#For the correlation matrix, just select the subset of variables we want to 
#include, we can also rename them
corrdata <- regdata |> 
  select(`$ROA_{t+1}$` = roa_lead_1,
         `$ROA_t$` = roa, 
         `$LOSS$` = loss,
         `$R\\&D$` = rd,
         `$TA$` = at,
         `$SIZE$` = mve)

#check how it looks 
corrdata

# preview how datasummary will make the correlation matrix
# pearspear will do pearson above diagonal and spearman below
datasummary_correlation(corrdata, method = "pearspear")

#This time, save it to latex
datasummary_correlation(corrdata, 
                        method = "pearspear",
                        output = "latex",
                        escape = F) |> 
  save_kable(glue("{data_path}/output/corrtable-r.tex"))



# Table 4: Regression Table ----------------------------------------------------

#make a list of regressions to put in the table
#there are lots of options for this in the fixest package as well
#fixef.rm removes singletons for comparability with reghdfe in Stata
models <- list(
  "$ROA_{t+1}$" = feols(roa_lead_1 ~ roa, regdata, fixef.rm = "both"),
  "$ROA_{t+1}$" = feols(roa_lead_1 ~ roa*loss, regdata, fixef.rm = "both"),
  "$ROA_{t+1}$" = feols(roa_lead_1 ~ roa*loss | calyear, regdata, fixef.rm = "both"),
  "$ROA_{t+1}$" = feols(roa_lead_1 ~ roa*loss | calyear + gvkey, regdata, fixef.rm = "both")
)


#Coefficient map
#The order of the coefficients will follow this map, also if you wish to 
#leave out coefficients, simply don't list them in the map
#there may be ways to experiment with doing this with less work/code, but this
#method gives a lot of control over the output.

cm <- c(
  `ln_rev_tweets` = "$Ln(Rev\\ Tweets)$",
  `ln_total_tweets` = "$Ln(Total\\ Tweets)$",
  `ln_total_stories` = "$Ln(Total\\ Stories)$",
  # `factor(TD_HR)4` = "$Trade\\ Hour:4$",
  # `factor(TD_HR)8` = "$Trade\\ Hour:8$",
  # `factor(TD_HR)12` = "$Trade\\ Hour:12$",
  `ln_rev_tweets:factor(TD_HR)4` = "$Ln(Rev\\ Tweets) x [4,7]\ Window$",
  `ln_rev_tweets:factor(TD_HR)8` = "$Ln(Rev\\ Tweets) x [8,11]\ Window$",
  `ln_rev_tweets:factor(TD_HR)12` = "$Ln(Rev\\ Tweets) x [12,15]\ Window$"
)


#Add Rows for Headings and Fixed Effects
FE_Row <- tribble(~term,~"[0,+3] Only",~"All Windows", ~"All Windows",~"All Windows",
                  "Revision Fixed Effects","\\multicolumn{1}{c}{Excluded}","\\multicolumn{1}{c}{Included}","\\multicolumn{1}{c}{Included}","\\multicolumn{1}{c}{Included}",
                  "Ann. Hr. Fixed Effects","\\multicolumn{1}{c}{Included}","\\multicolumn{1}{c}{Included}","\\multicolumn{1}{c}{Included}","\\multicolumn{1}{c}{Included}",
                  "Event Window Fixed Effects","\\multicolumn{1}{c}{Excluded}","\\multicolumn{1}{c}{Excluded}","\\multicolumn{1}{c}{Included}","\\multicolumn{1}{c}{Included}")
attr(FE_Row,"position") <- c(13,14,15)



#latex
panel <- modelsummary(models, 
                      vcov = ~ PERMNO + ANNDATS,
                      statistic = "statistic",
                      stars = c('\\sym{*}' = .1, '\\sym{**}' = .05, '\\sym{***}' = .01) ,
                      coef_map = cm,
                      gof_map = c("nobs", "r.squared", "r2.within"),
                      output = "latex", 
                      escape = F,
                      booktabs = T,
                      add_rows = FE_Row
) 


#if the table is too wide then tell latex to scale it down
#kable_styling(latex_options = c("scale_down")) |> 
#save_kable(glue("{dropbox_path}/table.tex"))

panel


#run the modelsummary function with the list of models
modelsummary(models, 
             #cluster standard errors by gvkey and calyear
             vcov = ~ gvkey + calyear,
             #t-stats in parenthesis under coefficients
             statistic = "statistic",
             #add significance stars
             stars = c('*' = .1, '**' = .05, '***' = .01) ,
             #apply the coefficient labels
             coef_rename = coef_labels,
             #choose which summary statistics to output at bottom
             #there is also a way to rename these in the output if needed
             gof_map = c("nobs", "adj.r.squared", "r2.within.adjusted", "FE: calyear" , "FE: gvkey"),
             output = "latex", 
             escape = F,
             booktabs = T
             ) |> 
  #if the table is too wide then tell latex to scale it down
  kable_styling(latex_options = c("scale_down")) |> 
  save_kable(glue("{data_path}/output/table4.tex"))
