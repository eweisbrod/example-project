## Define Global Parameters ----------------------------------------------------

# 1 - Setup the Data Folder Path -----------------------------------------------

# A USEFUL TRICK FOR SHARING CODE WITH COAUTHORS
# is to store the path to your local data folder 
# in your project-level R environment file (.Renviron)

# Step 1:
#Uncomment and run the below line to edit your .Renviron file
#usethis::edit_r_environ('project')

#Step 2: 
#Uncomment and paste the below line into the .Renviron file
#The .Renviron file should be open in a separate tab in Rstudio
#if you ran the above line correctly.

#DATA_PATH = "D:/Dropbox/example-project"

# Replace the quoted directory name in the example with the path
# to whatever folder you would like to store your data in
# Notice the slashes go the other way from Windows! 
# It is recommended to not store your data in the Git project folder
# Github is designed for hosting code, not data.
# I use a separate folder, usually in Dropbox if there is enough
# space on Dropbox.

#Step 3: 
# Comment out the code you ran to set up your Renviron and then
# restart R. You should only have to do these steps once any time 
# you start a new project or download a project to a new computer.

#The below line loads the data path from the project environment.
#The benefit of this is that you now only need one version of the code no 
# matter which coauthor is running the code. The same code should work for all
# coauthors or work the same way whether you are on your laptop or desktop, etc.
data_path <- Sys.getenv('DATA_PATH')

#If the above is too complicated and you don't have coauthors you can just set
#data_path manually by deleting everything above and uncommenting the below:
#data_path <- "D:/Dropbox/example-project"

#You would then replace "D:/example-project" with your own data path. 

# 2 - Setup any project-specific parameters ------------------------------------

# For example, you might want to define sample years here and then you can 
# refer to them throughout the code as needed, there are many use-cases.

#example parameters
# beg_year and end_year to define the sample period
beg_year <- 1970
# the assignment arrow is an R grammar style, but equal signs work too
end_year = 2022