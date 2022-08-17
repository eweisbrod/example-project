# Setup ------------------------------------------------------------------------

# Load Libraries [i.e., packages]
library(dbplyr)
library(RPostgres)
library(DBI)
library(tidyverse)



# Log into wrds ----------------------------------------------------------------

if(exists("wrds")){
  dbDisconnect(wrds)  # because otherwise WRDS might time out
}

wrds <- dbConnect(Postgres(),
                  host='wrds-pgdata.wharton.upenn.edu',
                  port=9737,
                  user=rstudioapi::askForSecret("WRDS user"),
                  password=rstudioapi::askForSecret("WRDS pw"),
                  sslmode='require',
                  dbname='wrds')
wrds  # checking if connection exists


# See a list of tables in a schema ---------------------------------------------

# List all of the tables in Compustat (comp)
wrds %>%
  DBI::dbListObjects(DBI::Id(schema = 'comp')) |> 
  dplyr::pull(table) |> 
  purrr::map(~slot(.x, 'name'))  |> 
  dplyr::bind_rows()  |>  
  View()

# Load funda as a tbl
comp.funda <- tbl(wrds,in_schema("comp", "funda"))
comp.company <- tbl(wrds,in_schema("comp", "company"))


# Get some raw Compustat data from funda
raw_funda <-
  comp.funda |> 
  #Apply standard Compustat filters
  filter(indfmt=='INDL', datafmt=='STD', popsrc=='D' ,consol=='C') %>%
  #Select the variables we want to dowload
  select(gvkey, datadate, conm, fyear, fyr, cstat_cusip=cusip, #inline renaming
         cik, cstat_ticker= tic, sich, ib, ibc, spi, at, dvc, act, che, lct, dlc, txp,
         xrd, dp, ceq, sale,csho, prcc_f, ajex, ni,
         epsfi, epsfx, epspi, epspx, opeps, cshfd, cshpri,
         oancf, ivncf, fincf
  ) |> 
  #Merge with the Compustat Company file for header SIC code and GICs code
  inner_join(select(comp.company, gvkey, sic, fic, gind), by="gvkey") |> 
  #Use historical sic [sich] when available. Otherwise use header sic [sic]
  mutate(sic4 = case_when( is.null(sich) ~ as.numeric(sic), TRUE ~ sich)) |> 
  #Calculate two digit sic code
  mutate(sic2 = floor(sic4/100)) |> 
  # replace missings with 0 for defined vars
  mutate(across(c(spi, dvc, che, lct, dlc, txp, dp, xrd),
            ~ coalesce(., 0))) |> 
  mutate(
    # align the data in calendar time following HVZ
    # they use June of each year and assume a 3 month reporting lag
    # so effectively this is coded as aligning as of March each year
    # See HVZ (2012) figure 1
    calyear = if_else( fyr > 3,
                       sql("extract(year from datadate)")+1,
                       sql("extract(year from datadate)")),
    mve = csho * prcc_f,
    e= ib-spi,
    gics_year = sql("extract(year from datadate)"),
    gics_month = sql("extract(month from datadate)")
  ) %>%
  filter(1955 < fyear) |> 
  filter(fic=="USA") |> 
  # download to local machine
  collect()




