##Define Global Parameters

#run this to set your dropbox path in your .Renviron
#usethis::edit_r_environ('project')
#example for .Renviron below
#DATA_PATH = "E:/Dropbox/CODE EXAMPLES/R/example-project-data"
# Notice the slashes go the other way from Windows! 

#load the data path from the project environment
#each person can point to the dropbox folder on their computer
data_path <- Sys.getenv('DATA_PATH')

#example parameters
# beg_year and end_year to define the sample period
beg_year <- 1970
# the assignment arrow is an R grammar style, but equal signs work too
end_year = 2021