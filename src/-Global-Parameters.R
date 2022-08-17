##Define Global Parameters

#run this to set your dropbox path in your .Renviron
#usethis::edit_r_environ('project')
#example for .Renviron below
#DATA_PATH = "D:/Dropbox/FDP Comparison/Data"
# Notice the slashes go the other way from Windows! 

#load the data path from the project environment
#each person can point to the dropbox folder on their computer
data_path <- Sys.getenv('DATA_PATH')