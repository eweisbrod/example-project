# Setup ------------------------------------------------------------------------

#Note: Some formatting I only do in LaTeX. So, you may wish to review the latex 
#version as well for some additional / advanced formatting options.

# Load Libraries [i.e., packages]
library(modelsummary)
library(sjlabelled)
library(formattable)
library(flextable)
library(equatags)
library(officer)
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
regdata <- read_dta(glue("{data_path}/regdata-R.dta")) |> 
  select(gvkey,datadate,calyear,roa,roa_lead_1,loss,at,mve,rd,FF12,ff12num) |> 
  #add variable labels 
  sjlabelled::var_labels(
    roa_lead_1 = "ROA_{t+1}",
    roa = "ROA_t",
    loss = "LOSS",
    rd = "R\\&D",
    at = "TA",
    mve = "SIZE"
  )




# Observations by Decade -------------------------------------------------------

## NOTE: see the latex version of this script for additional comments on 
## each step

#basic table
t1 <- regdata |> 
  mutate(Year = case_when(
    calyear %in% 1970:1979 ~ "1970 - 1979",
    calyear %in% 1980:1989 ~ "1980 - 1989",
    calyear %in% 1990:1999 ~ "1990 - 1999",
    calyear %in% 2000:2009 ~ "2000 - 2009",
    calyear %in% 2010:2019 ~ "2010 - 2019",
    calyear >= 2020 ~ "2020 - 2022")
  ) |> 
  group_by(Year) |> 
  summarize(`Total Firms` = formattable::comma(n(), digits=0),
            `Loss Firms` = formattable::comma(sum(loss),digits=0),
            `Pct. Losses` = formattable::percent(sum(loss)/n(), digits=2)
  )

t1

#add a total row
totalrow <- regdata |> 
  summarize(`Total Firms` = formattable::comma(n(), digits=0),
            `Loss Firms` = formattable::comma(sum(loss),digits=0),
            `Pct. Losses` = formattable::percent(sum(loss)/n(), digits=2)
  )|> 
  mutate(Year = "Total")

#bind together the existing rows and the new total row
t1 <- bind_rows(t1, totalrow) 

#look at it
t1

#turn it into a flextable
ftable1 <- flextable(t1) %>% autofit()

#look at it
ftable1

#hold onto these flextables for now
#will combine in a word doc later


# Table 2 Descriptive Stats ----------------------------------------------------

#I will use modelsummary's datasummary function
#other interesting data summary packages
# gtsummary
# skimr
# psych
# arsenal


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

#output will be stored in a flextable named ftable2
ftable2 <- datasummary( All(descripdata) ~ (N = NN) + Mean * Arguments(fmt = my_fmt) + 
               SD * Arguments(fmt = my_fmt) + 
               Min * Arguments(fmt = my_fmt) + 
               P25 * Arguments(fmt = my_fmt) + 
               Median * Arguments(fmt = my_fmt) + 
               P75 * Arguments(fmt = my_fmt) + 
               Max * Arguments(fmt = my_fmt), 
             # use escape = F to pass the latex formatting along  
             escape = F,
             output = 'flextable',
             data = descripdata) |> 
  #format the coefficient names in column 1 (j=1) as equations
  compose(
    j = 1,
    value = as_paragraph(as_equation(` `))) |> 
  fit_to_width(max_width = 6.5)

ftable2

# Table 3: Correlation Matrix --------------------------------------------------

# preview
datasummary_correlation(descripdata, method = "pearspear")

#To flextable
ftable3 <- datasummary_correlation(descripdata, 
                        method = "pearspear",
                        output = "flextable") |> 
  #format the first column as equations for variable names
  compose(
    j = 1,
    value = as_paragraph(as_equation(.)),
    use_dot = TRUE) |> 
  #format the header row as equations for variable names
  compose(
   part = "header",
   i=1,
   value = as_paragraph(as_equation(.)),
   use_dot = TRUE) |> 
  #resize the table
  fit_to_width(max_width = 6.5)

ftable3



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
  "roa_lead_1" = "ROA_{t+1}",
  "roa" = "ROA_{t}",
  "loss" = "LOSS",
  "roa:loss" = "ROA_{t} \\times LOSS"
)


#Optional custom formula to format the regression N observations in the output
nobs_fmt <- function(x) {
  out <- formattable::comma(x, digits=0)
}

#Optional custom format for the mapping of what to display in the goodness of
#fit statistics below the regression output. See the documentation for 
#modelsummary and the estimation commands you are using, there will be many 
#different possible choices of what to output.
gm <- list(
  list("raw" = "FE: calyear", "clean" = "Year FE", "fmt" = NULL),
  list("raw" = "FE: gvkey", "clean" = "Firm FE","fmt" = NULL),
  list("raw" = "nobs", "clean" = "N", "fmt" = nobs_fmt),
  list("raw" = "r.squared", "clean" = "R^2", "fmt" = 3),
  list("raw" = "r2.within", "clean" = "R^2 Within", "fmt" = 3)
  )

#use the modelsummary command to create the flextable
ftable4 <- panel <- modelsummary(models, 
             #cluster standard errors by gvkey and calyear
             vcov = ~ gvkey + calyear,
             #t-stats in parenthesis under coefficients
             statistic = "statistic",
             #add significance stars
             stars = c('*' = .1, '**' = .05, '***' = .01),
             estimate="{estimate}{stars}",
             #apply the coefficient map for coef labels
             coef_map = cm,
             gof_map = gm,
             output = "flextable"
             ) |> 
  #format the variable names as equations, this is the first six rows (i)
  #in the first column (j). Each coefficient has two rows, one for the 
  #estimate and one for the t-stat
  compose(
    i = 1:6,
    j = 1,
    value = as_paragraph(as_equation(.)),
    use_dot = TRUE) |> 
  #if you want to format the header row as equations if you have a 
  #variable name for you dependent measure as a column heading, you can 
  #uncomment the below compose command.
  # compose(
  #   part = "header",
  #   i=1,
  #   value = as_paragraph(as_equation(.)),
  #   use_dot = TRUE) |> 
  fit_to_width(max_width = 6.5) |> 
  autofit()

ftable4


#make a word document with all of the results
#I add one figure at the end as an example of adding a figure.
#These commands use the Officer package.
#you can look at the documentation for more options.
read_docx() |> 
  body_add_par("Sample Frequency", style = "heading 1") |> 
  body_add_par("") |> 
  body_add_flextable(value=ftable1) |> 
  body_add_break(pos = "after") |> 
  body_add_par("Descriptive Statistics", style = "heading 1") |> 
  body_add_par("") |> 
  body_add_flextable(value=ftable2) |>
  body_add_break(pos = "after") |> 
  body_add_par("Correlation Matrix", style = "heading 1") |> 
  body_add_par("") |> 
  body_add_flextable(value=ftable3) |> 
  body_add_break(pos = "after") |> 
  body_add_par("Regression Table", style = "heading 1") |> 
  body_add_par("") |> 
  body_add_flextable(value=ftable4) |>  
  body_add_break(pos = "after") |> 
  body_add_par("Figure 1", style = "heading 1") |> 
  body_add_par("") |> 
  body_add_img(glue("{data_path}/output/ff12_fig.png"), 
               height = 3.6,
               width = 4.2,
               style = "centered") |> 
  print(target = glue("{data_path}/output/tables-r.docx"))


#Since these are flextables, they can also be output to html, ppt, markdown, etc.
# https://ardata-fr.github.io/flextable-book/
#you can look into the many options, the world is your oyster.

             