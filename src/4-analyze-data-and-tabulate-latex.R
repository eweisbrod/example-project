# Setup ------------------------------------------------------------------------

# Load Libraries [i.e., packages]
library(modelsummary)
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


# read in the data from the previous step --------------------------------------

#read in the winsorized data
#I found there are not many firms in the 60s so I am just going to start at 1970
regdata <- read_dta(glue("{data_path}/example-data2.dta")) |> 
  select(gvkey,datadate,calyear,roa,roa_lead_1,loss,at,mve,rd,FF12,ff12num) 





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
  save_kable(glue("{data_path}/output/table1.tex"))


# Table 2 Descriptive Stats ----------------------------------------------------

#other interesting data summary packages
# gtsummary
# skimr
# psych
# arsenal

#can apply custom formatting to the numbers
my_f <- function(x) formattable::comma(x, digits=3)

# use the datasummary command to make a descriptive table
# see the documentation for how the formulas work
# basically put variables on one side of the ~ and stats on the other
# inside the parenthesis can rename the variables in the output table
regdata |> 
  modelsummary::datasummary(formula = (`$ROA_{t+1}$` = roa_lead_1) + (`$ROA_t$` = roa) + 
                (`$LOSS$` = loss) + (`$R\\&D$` = rd) + (`$TA$` = at) + (`$SIZE$` = mve) ~
                N + Mean + SD + Min + P25 + Median + P75 + Max, 
              # use escape = F to pass the latex formatting along  
              escape = F,
              fmt = my_f,
              output = 'latex') |> 
  save_kable(glue("{data_path}/output/table2.tex"))


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
  save_kable(glue("{data_path}/output/table3.tex"))



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

#Use this list to rename the coefficient labels for output
#I think it might be important to list roa:loss before the base terms
coef_labels <- c(
  "roa_lead_1" = "$ROA_{t+1}$",
  "roa:loss" = "$ROA_{t} \\times LOSS$",
  "roa" = "$ROA_{t}$",
  "loss" = "$LOSS$"
)

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
