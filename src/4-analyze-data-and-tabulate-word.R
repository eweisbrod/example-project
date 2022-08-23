# Setup ------------------------------------------------------------------------

# Load Libraries [i.e., packages]
library(modelsummary)
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
regdata <- read_dta(glue("{data_path}/example-data2.dta")) |> 
  select(gvkey,datadate,calyear,roa,roa_lead_1,loss,at,mve,rd,FF12,ff12num) 




# Observations by Decade -------------------------------------------------------

#Goal is to show how to export a basic manual table or data frame into 
# a paper
#At first I did this simply by year but it was too long
#So, I am going to manually group by decade

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

#other interesting data summary packages
# gtsummary
# skimr
# psych
# arsenal

my_f <- function(x) formattable::comma(x, digits=3)

ftable2 <- regdata |> 
  modelsummary::datasummary(formula = (`ROA_{t+1}` = roa_lead_1) + (`ROA_t` = roa) + 
                (`LOSS` = loss) + (`R\\&D` = rd) + (`TA` = at) + (`SIZE` = mve) ~
                N + Mean + SD + Min + P25 + Median + P75 + Max, 
              escape = F,
              fmt = NULL,
              output = "flextable") |> 
  colformat_double(j = 3:9, big.mark = ",", digits = 3) |> 
  compose(
    j = 1,
    value = as_paragraph(as_equation(` `))) |> 
  fit_to_width(max_width = 6.5)

ftable2

# Table 3: Correlation Matrix --------------------------------------------------

corrdata <- regdata |> 
  select(`ROA_{t+1}` = roa_lead_1,
         `ROA_t` = roa, 
         `LOSS` = loss,
         `R\\&D` = rd,
         `TA` = at,
         `SIZE` = mve)

corrdata

# preview
datasummary_correlation(corrdata, method = "pearspear")

#To flextable
ftable3 <- datasummary_correlation(corrdata, 
                        method = "pearspear",
                        output = "flextable") |> 
  #colformat_double(j = 3:9, big.mark = ",", digits = 3) |> 
  compose(
    j = 1,
    value = as_paragraph(as_equation(.)),
    use_dot = TRUE) |> 
  compose(
   part = "header",
   i=1,
   value = as_paragraph(as_equation(.)),
   use_dot = TRUE) |> 
  fit_to_width(max_width = 6.5)

ftable3



# Table 4: Regression Table ----------------------------------------------------

models <- list(
  "ROA_{t+1}" = feols(roa_lead_1 ~ roa, regdata, fixef.rm = "both"),
  "ROA_{t+1}" = feols(roa_lead_1 ~ roa*loss, regdata, fixef.rm = "both"),
  "ROA_{t+1}" = feols(roa_lead_1 ~ roa*loss | calyear, regdata, fixef.rm = "both"),
  "ROA_{t+1}" = feols(roa_lead_1 ~ roa*loss | calyear + gvkey, regdata, fixef.rm = "both")
)

coef_labels <- c(
  "roa_lead_1" = "ROA_{t+1}",
  "roa:loss" = "ROA_{t} \\times LOSS",
  "roa" = "ROA_{t}",
  "loss" = "LOSS"
)

ftable4 <- modelsummary(models, 
             vcov = ~ gvkey + calyear,
             statistic = "statistic",
             stars = c('*' = .1, '**' = .05, '***' = .01) ,
             coef_rename = coef_labels,
             gof_map = c("nobs", "adj.r.squared", "r2.within.adjusted", "FE: calyear" , "FE: gvkey"),
             output = "flextable"
             ) |> 
  #colformat_double(j = 3:9, big.mark = ",", digits = 3) |> 
  compose(
    i = 1:8,
    j = 1,
    value = as_paragraph(as_equation(.)),
    use_dot = TRUE) |> 
  compose(
    part = "header",
    i=1,
    value = as_paragraph(as_equation(.)),
    use_dot = TRUE) |> 
  fit_to_width(max_width = 6.5) |> 
  autofit()

ftable4

#make a word document
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
  print(target = glue("{data_path}/output/tables.docx"))

             