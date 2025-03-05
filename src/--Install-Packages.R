# This script uses an R package called pacman to check if the other packages
# used in this example are installed on your machine. If not, it installs them.

#this line checks for the pacman package, and installs it if needed.
if (!require("pacman")) install.packages("pacman")

#this line uses pacman to install all of the other packages in the project. 
#not all of the packages are crucial but I have put them all here anyways.
#for now.
#You may see a lot of warnings as the packages install but that is ok.
pacman::p_load(tidyverse, 
                dbplyr,
                RPostgres,
                DBI,
                glue,
                arrow,
                haven,
                tictoc, 
                lubridate,
                modelsummary,
                kableExtra,
                formattable,
                fixest,
                flextable,
                officer,
                corrplot,
                equatags,
                broom,
                usethis,
                scales,
                forcats,
                sjlabelled
               )


# Log into wrds to check if you have connectivity ------------------------------

# just in case, check to make sure there is not already a connection open
if(exists("wrds")){
  dbDisconnect(wrds)  
}

#now log on, it will prompt for your WRDS username and password
wrds <- dbConnect(Postgres(),
                  host='wrds-pgdata.wharton.upenn.edu',
                  port=9737,
                  user=rstudioapi::askForSecret("WRDS user"),
                  password=rstudioapi::askForSecret("WRDS pw"),
                  sslmode='require',
                  dbname='wrds')

# Run the below line. If you are connected you should see something 
# like the below output in your console:
# <PqConnection> wrds@wrds-pgdata.wharton.upenn.edu:9737
wrds  

#if the above two commands time out, you may be stuck behind a firewall etc.


# close the connection after testing
if(exists("wrds")){
  dbDisconnect(wrds)  
}

