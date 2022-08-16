# Setup -------------------------------------------------------------------
library(tidyverse)
library(dbplyr)
library(dplyr)
library(RPostgres)
library(DBI)
write_parquet <- arrow::write_parquet
write_parquet <- function(x, p) {
  arrow::write_parquet(x, p, compression='gzip', compression_level=5)
}

crsp_begin_date <- "1950-01-01"
crsp_end_date   <- "2020-12-31"



# Log into wrds -----------------------------------------------------------

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
