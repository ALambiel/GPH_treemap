library(data.table)
library(tools)

# Load local paths 
scratch<-"/path_to_scratch"
las_urls<-"/path_to_urls.csv"

zipdir <- file.path(scratch, "zip_files")
lasdir <- file.path(scratch, "las_data")

# Create folders if needed
dir.create(zipdir, showWarnings=FALSE, recursive=TRUE)
dir.create(lasdir, showWarnings=FALSE, recursive=TRUE)

# Read table with urls of .las file
files<-fread(las_urls, header=FALSE)
# remove eventually duplicated rows
files <- unique(files)

# set timeout option to prevent download errors
options(timeout = 1000)

# Cutsom function to downlaod and unzip .las file
download_and_unzip <- function(url, zip, out) {
    filename <- basename(url)
    nam <- unlist(strsplit(filename, '[_-]'))
    check <- paste0(nam[3], "_", nam[4], ".las")
    if(!file.exists(file.path(out, check))){
        download.file(url, file.path(zip, filename))
        unzip(file.path(zip, filename), exdir = out)
        }
    }

# Applying the function to all URLs
mapply(function(x){download_and_unzip(url=x, zip=zipdir, out=lasdir)}, files$V1)