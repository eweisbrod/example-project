# Setup ------------------------------------------------------------------------

# Load Libraries [i.e., packages]
library(modelsummary)
library(kableExtra)
library(formattable)
library(lubridate)
library(glue)
library(haven)
library(fixest)
library(forcats)
library(tidyverse) # I like to load tidyverse last to avoid package conflicts

#load helper scripts
source("src/-Global-Parameters.R")
source("src/utils.R")


# read in the data from the previous step --------------------------------------

#read in the winsorized data
regdata <- read_dta(glue("{data_path}/regdata-R.dta")) |> 
  select(gvkey,datadate,calyear,roa,roa_lead_1,loss,at,mve,rd,FF12,ff12num) 


# Losses by Industry -----------------------------------------------------------


fig <- regdata |> 
  group_by(FF12) |> 
  summarize(pct_loss = sum(loss, na.rm = T)/n()) |> 
  #Next line reorders the FF12 industries to make them appear in order of %loss
  mutate(FF12 = forcats::fct_reorder(factor(FF12), (pct_loss))) |> 
  ggplot(aes(x = FF12, y= pct_loss)) + 
  geom_col(fill = "#0051ba") +
  # Fill color = Kansas Blue from : https://brand.ku.edu/guidelines/design/color
  scale_y_continuous(name = "Freq. of Losses", labels = scales::percent) +
  scale_x_discrete(name = "Fama-French Industry") +
  coord_flip() +
  #base_family = serif sets font to times new roman
  theme_bw(base_family = "serif") 

#Look at it in R  
fig

#For Latex output you might want to output to PDF
ggsave(glue("{data_path}/output/ff12_fig.pdf"), fig, width = 7, height = 6)

#For Word output you might want to output to an image such as .png
ggsave(glue("{data_path}/output/ff12_fig.png"), fig, width = 4.2, height = 3.6)


# Losses by Size Quintile Over Time --------------------------------------------


fig <- regdata |> 
  group_by(calyear) |> 
  #create size quintiles by calyear
  mutate(size_qnt = factor(ntile(mve,5))) |> 
  group_by(calyear, size_qnt) |> 
  summarize(pct_loss = sum(loss, na.rm = T)/n()) |> 
  ggplot(aes(x = calyear, y= pct_loss, color = size_qnt, linetype = size_qnt)) + 
  geom_line() + geom_point() + 
  scale_y_continuous(name = "Freq. of Losses", labels = scales::percent) +
  scale_x_continuous(name = "Year", breaks = seq(1970,2025,5)) +
  #If you give these scales the same name they will appear in the same legend
  scale_color_discrete(name = "Size Quintile") +
  scale_linetype_discrete(name = "Size Quintile") +
  theme_bw(base_family = "serif") 

#Look at it in R  
fig

#For Latex
ggsave(glue("{data_path}/output/size_year.pdf"), fig, width = 7, height = 6)

#For Word
ggsave(glue("{data_path}/output/size_year.png"), fig, width = 7, height = 6)


# Correlation Matrix Plot ------------------------------------------------------

#optional package you need to install if you want to try this example
library(corrplot)


corrdata <- regdata |> 
  select(`ROA_{t+1}` = roa_lead_1,
         `ROA_t` = roa, 
         `LOSS` = loss,
         `R\\&D` = rd,
         `TA` = at,
         `SIZE` = mve)

corrdata

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


# Annual Regressions with confidence bands -------------------------------------

# bonus example just for fun

figdata <- regdata |>
  #nest the regressions by year and loss
  nest_by(calyear,loss) |> 
  # fit the regressions
  mutate(
    fit = list(lm(roa_lead_1 ~ roa, data = data))
  ) |> 
  # use the broom package to tidy the regressions
  #option conf.int outputs the confidence intervals so we can plot them
  reframe(broom::tidy(fit, conf.int = TRUE)) |> 
  #I don't plan to plot the intercept so i will drop it from the data
  filter(term !="(Intercept)") 

#can also use this setup to do Fama-Macbeth regressions, etc. 
#can also use pmg package for Fama-Macbeth

#now make a ggplot object from the data
fig <- figdata |> 
  mutate(loss = factor(loss)) |> 
  ggplot(aes(x=calyear,y=estimate))  +
  geom_ribbon(aes(ymin = conf.low, ymax=conf.high, 
                  group = loss),
                  fill = "grey80") + 
  geom_line(aes(color=loss)) +
  geom_point(aes(color=loss)) +
  theme_bw(base_family = "serif") 

#Look at it in R  
fig

#For Latex
ggsave(glue("{data_path}/output/coef_year.pdf"), fig, width = 7, height = 6)

#For Word
ggsave(glue("{data_path}/output/coef_year.png"), fig, width = 7, height = 6)

