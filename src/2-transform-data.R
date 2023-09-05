# Setup ------------------------------------------------------------------------

# Load Libraries [i.e., packages]
library(lubridate)
library(glue)
library(arrow)
library(haven)
library(tidyverse) # I like to load tidyverse last to avoid package conflicts



#load helper scripts
source("src/-Global-Parameters.R")
source("src/utils.R")


# read in the data from the previous step --------------------------------------

#let's work with the parquet version
data1 <- read_parquet(glue("{data_path}/raw-data-R.parquet"))

#note: if you choose to collect your raw data in SAS or Stata
# these could easily be read in using haven::read_dta() or haven::read_sas()


# Some quick peeks at the data -------------------------------------------------

#since the data is structured as a dplyr tibble, just calling its name
#will preview the first 10 rows (similar to a head function)
data1 

#can also glimpse
glimpse(data1)

#or summarize
summary(data1)


# Manipulate a few variables ---------------------------------------------------

#many of the below steps could be combined into one. They also could have been
#done on the WRDS server
#I just separate them for teaching purposes

data2 <- data1 |>
  #filter based on the global parameters for the sample period that we set in
  # the global-parameters script.
  filter(calyear >= beg_year,
         calyear <= end_year) |> 
  #I am going to scale by total assets (at) so I am going to set a minimum at
  # to avoid small denominators
  filter(at >= 10) |> 
  mutate(
    #use the FF utility functions to assign fama french industries
    FF12 = assign_FF12(sic4),
    ff12num = assign_FF12_num(sic4),
    FF49 = assign_FF49(sic4),
    ff49num = assign_FF49_num(sic4),
    # code a loss dummy, I like 1/0 but true/false is also fine
    loss = if_else(e < 0 , 1, 0),
    # scale e by ending total assets
    # FSA purists would probably use average total assets, but just an example
    roa = e / at ,
    # scale r&d by ending total assets
    rd = xrd / at
  ) |> 
  # let's do an earnings persistence regression with lead earnings as y
  # so for each gvkey we need the next earnings for that gvkey
  # first make sure the data is sorted properly
  arrange(gvkey,datadate) |> 
  # then group by firm (gvkey) 
  # this will restrict the lead function to only look at the next obs 
  # for the same firm
  group_by(gvkey) |> 
  mutate(roa_lead_1 = lead(roa,1L),
         datadate_lead_1 = lead(datadate,1L)) |> 
  #check to make sure no gaps or fiscal year changes
  filter(month(datadate_lead_1) == month(datadate),
         year(datadate_lead_1) == year(datadate) + 1) |> 
  #not a bad idea to ungroup once you are finished
  ungroup() |> 
  #Filter multiple variables to require non-missing values
  filter(if_all(c(at, mve,rd,ff12num,starts_with("roa")), ~ !is.na(.x)))


# Play around ------------------------------------------------------------------

#how many observations in each FF12 industry?
data2 |> 
  group_by(FF12) |> 
  count()

#percentage of losses by industry?
data2 |> 
  group_by(FF12) |> 
  summarize(pct_loss = sum(loss, na.rm = T)/n())

#as a quick figure?
data2 |> 
  group_by(FF12) |> 
  summarize(pct_loss = sum(loss, na.rm = T)/n()) |> 
  ggplot(aes(x = FF12, y= pct_loss)) + 
  scale_y_continuous(name = "Freq. of Losses", labels = scales::percent) +
  geom_col() +
  coord_flip() +
  theme_bw() 

# Winsorize the data -----------------------------------------------------------

#check the tail values as an example
quantile(data2$roa, probs = c(0,.01,.99,1))

#default winsorization
data3 <- data2 |> 
  #default is 1% / 99 % , this winsorizes rd and all roa vars at that cut
  mutate(across(c(mve,at,rd,starts_with("roa")), winsorize_x))


#check the winsorized tail values
quantile(data3$roa, probs = c(0,.01,.99,1))


#alternate version, if we want to change the tails
data3b <- data2 |> 
  #winsorize 2.5% / 97.5 % 
  mutate(
    across(c(rd,starts_with("roa")), ~ winsorize_x(.x,cuts = c(0.025,0.025)))
  )

#check
quantile(data2$roa, probs = c(0,.025,.975,1))
quantile(data3b$roa, probs = c(0,.025,.975,1))

# Save the winsorized data  ----------------------------------------------------

# just saving to Stata format this time for brevity
write_dta(data3,glue("{data_path}/regdata-R.dta")) 
