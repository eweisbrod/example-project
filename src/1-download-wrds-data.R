# Setup ------------------------------------------------------------------------

# Load Libraries [i.e., packages]
library(dbplyr)
library(RPostgres)
library(DBI)
library(glue)
library(arrow)
library(haven)
library(tictoc) #very optional timer, mostly as a teaching example
library(tidyverse) # I like to load tidyverse last to avoid package conflicts


#load helper scripts
#similar to "include" statement in SAS.
source("src/-Global-Parameters.R")
source("src/utils.R")


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
# Just an example to play with the Postgres server

# List all of the tables in Compustat (comp)
wrds |>
  DBI::dbListObjects(DBI::Id(schema = 'comp')) |> 
  dplyr::pull(table) |> 
  purrr::map(~slot(.x, 'name'))  |> 
  dplyr::bind_rows()  |>  
  View()
# can replace "comp" with any schema such as "crsp" "ibes" etc.
# schemas on the Postgres server are similar to WRDS SAS libraries

# Load table references and download data --------------------------------------

# Load funda as a tbl
comp.funda <- tbl(wrds,in_schema("comp", "funda"))
comp.company <- tbl(wrds,in_schema("comp", "company"))

# Optional line:
#if you want to see how long a block of code takes you can start a tictoc timer
#it will tell you how long it takes between when you run tic() and when you run 
# toc()
tictoc::tic()

# Get some raw Compustat data from funda
raw_funda <-
  comp.funda |> 
  #Apply standard Compustat filters
  filter(indfmt=='INDL', datafmt=='STD', popsrc=='D' ,consol=='C') |>
  #Select the variables we want to download
  #the pattern for inline renaming is 
  #new_name = old_name
  select(conm, gvkey, datadate, fyear, fyr, cstat_cusip=cusip, #inline renaming
         cik, cstat_ticker= tic, sich, ib, spi, at, xrd, ceq, sale,
         csho, prcc_f
  ) |> 
  #Merge with the Compustat Company file for header SIC code and GICs code
  inner_join(select(comp.company, gvkey, sic, fic, gind), by="gvkey") |> 
  #Use historical sic [sich] when available. Otherwise use header sic [sic]
  mutate(sic4 = coalesce(sich, as.numeric(sic))) |> 
  #Calculate two digit sic code
  mutate(sic2 = floor(sic4/100)) |> 
  #Delete financial and utility industries
  #For some research projects this is common to remove highly regulated firms
  #with unique accounting practices
  filter(!between(sic2,60,69),
         sic2 != 49) |> 
  # replace missings with 0 for defined vars
  mutate(across(c(spi, xrd),
            ~ coalesce(., 0))) |> 
  # create a few additional variables
  mutate(
    # Some example code to align the data in June calendar time. 
    # Some papers use June of each year and assume a 3 month reporting lag.
    # Effectively this is coded as aligning datadate as of March each year.
    # See, for example, Hou, Van Dijk, and Zhang (2012 JAE) figure 1
    # This example also demonstrates injecting sql into dplyr code
    calyear = if_else( fyr > 3,
                       sql("extract(year from datadate)")+1,
                       sql("extract(year from datadate)")),
    # mve is market value of equity
    mve = csho * prcc_f,
    # define earnings (e) as earnings before special items
    e= ib-spi,
  ) |>
  # filter to fiscal years after 1955, not much in Compustat before that 
  filter(1967 < fyear) |> 
  # filter to US companies
  filter(fic=="USA") |> 
  # everything above manupulates the data inside the WRDS postgres server
  #behind the scenes it generates efficient sql code
  # below line downloads to local machine RAM
  collect()
  #if you comment out the above collect() and instead run below command
  # you can see the behind the scenes sql
  #show_query()

#stop the tictoc timer
tictoc::toc()


# Save the data to disk --------------------------------------------------------

# saving to Stata is convenient for working with coauthors
# glue package allows for dynamic file paths 
# then each coauthor can specify their own local data folder
tic()
write_dta(raw_funda,glue("{data_path}/raw-data-R.dta")) 
toc()
#looks like about 162 MB on my machine

# if the data will stay in R or another advanced/modern language like Python
# then Parquet files are a nice open-source file format for data science
# they are fast and small and have some other advanced features as well

# in this example, we have customized the write_parquet function a bit to 
# default to a high level of gzip compression to save space
# therefore, the write_parquet function is using the function defined in the 
# utils script
tic()
write_parquet(raw_funda,glue("{data_path}/raw-data-R.parquet"))
toc()
# the parquet operations are faster and the file is only 32MB on my machine




