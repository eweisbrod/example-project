# Setup -------------------------------------------------------------------

library(dbplyr)
library(RPostgres)
library(DBI)
library(tidyverse)



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
