# Setup ------------------------------------------------------------------------

# Load Libraries [i.e., packages]
library(modelsummary)
library(kableExtra)
library(formattable)
library(lubridate)
library(glue)
library(haven)
library(fixest)
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


# Correlation Matrix Plot ------------------------------------------------------

library(corrplot)


corrdata <- regdata |> 
  select(`ROA_{t+1}` = roa_lead_1,
         `ROA_t` = roa, 
         `LOSS` = loss,
         `R\\&D` = rd,
         `TA` = at,
         `SIZE` = mve)

corrdata

library(corrplot)
correlation = cor(corrdata)
col2 = colorRampPalette(c('red', 'white', 'blue'))  

pdf(file=glue("{data_path}/output/corr_fig.pdf"))
corrplot(correlation, method = 'square', 
         addCoef.col = 'black', 
         diag = FALSE,
         tl.col='black', 
         type = 'full',
         tl.cex = 1,
         tl.srt = 0,
         tl.offset = 1,
         number.cex = 0.7,
         cl.ratio = 0.1,
         cl.pos = "r",
         col=col2(20),
         win.asp = .8)
dev.off()


