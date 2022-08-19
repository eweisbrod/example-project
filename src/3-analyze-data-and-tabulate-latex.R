# Setup ------------------------------------------------------------------------

# Load Libraries [i.e., packages]
library(modelsummary)
library(kableExtra)
library(lubridate)
library(glue)
library(haven)
library(tictoc) #very optional, mostly as a teaching example
library(tidyverse) # I like to load tidyverse last to avoid package conflicts

library(modelsummary)

#load helper scripts
source("src/-Global-Parameters.R")
source("src/utils.R")


# read in the data from the previous step --------------------------------------

#read in the winsorized data
#I found there are not many firms in the 60s so I am just going to start at 1970
regdata <- read_dta(glue("{data_path}/example-data2.dta")) |> 
  select(gvkey,datadate,calyear,roa,roa_lead_1,loss,at,mve,rd,FF12,ff12num) |> 
  filter(calyear >= 1970)





# Observations by Decade -------------------------------------------------------

#Goal is to show how to export a basic manual table or data frame into 
# a paper
#At first I did this simply by year but it was too long
#So, I am going to manually group by decade

#basic table
table1 <- regdata |> 
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

table1

#add a total row
totalrow <- regdata |> 
  summarize(`Total Firms` = formattable::comma(n(), digits=0),
            `Loss Firms` = formattable::comma(sum(loss),digits=0),
            `Pct. Losses` = formattable::percent(sum(loss)/n(), digits=2)
  )|> 
  mutate(Year = "Total")

table1 <- bind_rows(table1, totalrow) 

table1


table1tex<- kbl(table1,
                    format = "latex",
                    booktabs = T,
                    linesep = "")

table1_latex

#Word document using flextable and Officer

library(flextable)
library(officer)

#make a word document
read_docx() |> 
  body_add_par("Sample Frequency", style = "heading 1") |> 
  body_add_par("") |> 
  body_add_flextable(value=flextable(table1) %>% autofit()) |> 
  print(target = glue("{data_path}/output/table1.docx"))

cm <- c("rd" = "R&D", "roa" = "ROA")


var_label(regdata)

regdata <- regdata |> 
  set_variable_labels(rd = "R&D")

table2 <- regdata |> 
  datasummary(formula = (`ROA_{t+1}` = roa_lead_1) + (`ROA_t` = roa) + loss + (`R\\&D` = rd) + at + mve ~
                N + Mean + SD + Min + P25 + Median + P75 + max, 
              escape = F,
              fmt = NULL,
              output = "flextable") |> 
  colformat_double(j = 3:9, big.mark = ",", digits = 3) |> 
  compose(
    j = 1,
    value = as_paragraph(as_equation(` `))) |> 
  fit_to_width(max_width = 6.5)


read_docx(glue("{data_path}/output/table1.docx")) |> 
  body_add_par("Descriptive Statistics", style = "heading 1") |> 
  body_add_par("") |> 
  body_add_flextable(value=table2 ) |> 
  print(target = glue("{data_path}/output/table2.docx"))


