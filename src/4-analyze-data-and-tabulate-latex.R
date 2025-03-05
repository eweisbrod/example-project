# Setup ------------------------------------------------------------------------

# Load Libraries [i.e., packages]
library(modelsummary)
library(sjlabelled)
library(kableExtra)
library(tinytable)
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

#tinytable version
tt(table1) |> 
  format_tt(escape = TRUE) |> 
  save_tt(glue("{data_path}/output/freqtable-tiny-r.tex"),
          overwrite = TRUE)

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




#Here I select the variables I want to include in the table
#then I use the label_to_colnames() function to apply the variable labels
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

datasummary( All(descripdata) ~ (N = NN) + 
               (Mean + SD + Min + P25 + 
                  Median + P75 + Max) * Arguments(fmt = my_fmt), 
             data = descripdata,
             # use escape = F to pass the latex formatting along  
             escape = F,
             output = glue("{data_path}/output/descrip-r.tex")) 


#Here I save the output to a tex file, but you could also just remove the last
#line and cut and paste the output from the console into Overleaf.

# Table 3: Correlation Matrix --------------------------------------------------


# preview how datasummary will make the correlation matrix
# pearspear will do pearson above diagonal and spearman below
datasummary_correlation(descripdata, method = "pearspear")

#This time, save it to latex
datasummary_correlation(descripdata, 
                        method = "pearspear",
                        output = glue("{data_path}/output/corrtable-r.tex"),
                        escape = F) 



# Table 4: Regression Table ----------------------------------------------------

#make a list of regressions to put in the table
#there are lots of options for this in the fixest package as well
#fixef.rm removes singletons for comparability with reghdfe in Stata
#The labels you give each model will be in the column headings
models <- list(
  "Base" = feols(roa_lead_1 ~ roa, regdata, fixef.rm = "both"),
  "No FE" = feols(roa_lead_1 ~ roa*loss, regdata, fixef.rm = "both"),
  "Year FE" = feols(roa_lead_1 ~ roa*loss | calyear, regdata, fixef.rm = "both"),
  "Two-Way FE" = feols(roa_lead_1 ~ roa*loss | calyear + gvkey, regdata, fixef.rm = "both"),
  "With Controls" = feols(roa_lead_1 ~ roa*loss + at + rd + mve | calyear + gvkey, regdata, fixef.rm = "both")
)


#Coefficient map
#The order of the coefficients will follow this map, also if you wish to 
#leave out coefficients, simply don't list them in the map
#there may be ways to experiment with doing this with less work/code, but this
#method gives a lot of control over the output.
#Note how this allows for labelling interaction terms as well. 
cm <- c(
  "roa_lead_1" = "$ROA_{t+1}$",
  "roa" = "$ROA_{t}$",
  "loss" = "$LOSS$",
  "roa:loss" = "$ROA_{t} \\times LOSS$"
)


#Optional custom formula to format the regression N observations in the output
nobs_fmt <- function(x) {
  out <- formattable::comma(x, digits=0)
  out <- paste0("\\multicolumn{1}{c}{",out,"}")
}

#Optional formula to check if controls are in the model
#note that you need to define at least one variable in the list of controls
#this is adapted from the modelsummary help pages
#https://modelsummary.com/vignettes/modelsummary.html#collapse-control-variables-into-an-indicator
glance_custom.fixest <- function(x, ...) {
  #modify this line with your control variables
  controls <- c("at", "rd","mve")
  if (all(controls %in% names(coef(x)))) {
    #you could modify this to write whatever you want, "included/excluded etc"
    out <- data.frame(Controls = "X")
    #original formating from modelsummary help pages
    #out <- data.frame(Controls = "✓")
  } else {
    out <- data.frame(Controls = "")
    #original formating from modelsummary help pages
    #out <- data.frame(Controls = "✗")
  }
  return(out)
}

#Optional custom format for the mapping of what to display in the goodness of
#fit statistics below the regression output. See the documentation for 
#modelsummary and the estimation commands you are using, there will be many 
#different possible choices of what to output.
gm <- list(
  list("raw" = "FE: calyear", "clean" = "Year FE", "fmt" = NULL),
  list("raw" = "FE: gvkey", "clean" = "Firm FE","fmt" = NULL),
  list("raw" = "Controls", "clean" = "Controls","fmt" = NULL),
  list("raw" = "nobs", "clean" = "N", "fmt" = nobs_fmt),
  list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = 3),
  list("raw" = "r2.within", "clean" = "$R^2$ Within", "fmt" = 3)
)

#Preview the output without adding extra rows.
panel <- modelsummary(models, 
                      #cluster standard errors by gvkey and calyear
                      vcov = ~ gvkey + calyear,
                      #t-stats in parenthesis under coefficients
                      statistic = "statistic",
                      #add significance stars
                      stars = c('*' = .1, '**' = .05, '***' = .01) ,
                      estimate="{estimate}{stars}",
                      #apply the coefficient map for coef labels
                      coef_map = cm,
                      gof_map = gm,
                      #output = "latex", 
                      escape = F,
                      booktabs = T,
                      #add_rows = my_rows
) 

panel

#Optional: if you prefer to manually add heading and FE rows.
#However, above I have provided the code to use the 
#built in ability of fixest to create the FE Rows. 
#This defines the rows we wish to add.
#The terms should match what you used as the model/column names in the model list.
# my_rows <- tribble(~term,~"Base",~"No FE", ~"Year FE",~"Two-Way FE",~"With Controls",
#                   "Year FE","\\multicolumn{1}{c}{Excluded}","\\multicolumn{1}{c}{Excluded}","\\multicolumn{1}{c}{Included}","\\multicolumn{1}{c}{Included}","\\multicolumn{1}{c}{Included}",
#                   "Firm FE","\\multicolumn{1}{c}{Excluded}","\\multicolumn{1}{c}{Excluded}","\\multicolumn{1}{c}{Excluded}","\\multicolumn{1}{c}{Included}","\\multicolumn{1}{c}{Included}",
#                   "Controls","\\multicolumn{1}{c}{Excluded}","\\multicolumn{1}{c}{Excluded}","\\multicolumn{1}{c}{Excluded}","\\multicolumn{1}{c}{Excluded}","\\multicolumn{1}{c}{Included}")
# #count the rows in the preview output to see where to insert these extra rows
# attr(my_rows,"position") <- c(7,8,9)



#Output to latex with the extra rows added
modelsummary(models, 
                      #cluster standard errors by gvkey and calyear
                      vcov = ~ gvkey + calyear,
                      #t-stats in parenthesis under coefficients
                      statistic = "statistic",
                      #add significance stars
                      stars = c('\\sym{*}' = .1, '\\sym{**}' = .05, '\\sym{***}' = .01),
                      estimate="{estimate}{stars}",
                      #apply the coefficient map for coef labels
                      coef_map = cm,
                      gof_map = gm,
                      output = glue("{data_path}/output/regression-r.tex"), 
                      escape = F
                      #booktabs = T
                      #add_rows = my_rows,
                      #if you want to decimal align the columns, use the number 
                      #of d equal to the number of models
                      #if I comment out the below line, modelsummary would do 
                      # "lccccc" on its own as the default.
                      #align = "lddddd"
                      )


