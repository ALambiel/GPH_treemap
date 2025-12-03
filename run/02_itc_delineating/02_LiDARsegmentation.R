##--0) Load packages

library(data.table)
library(raster)
library(terra)
library(sp)
library(sf)
library(dplyr)
library(purrr)
library(lidR)
library(future)


##--1) Set up local path and parameters
print(">>> Set up local path and parameters")

# Load local paths

scratch <- "/path_to_scratch"

dir <- file.path(scratch, "reclass")

chmpath <- "/path_to/CanopyHeightModel.tif"

exdir <- file.path(scratch, "seg") 
dir.create(exdir, showWarnings=FALSE, recursive=TRUE)

print(">>> read and create directories : ok")


# set the date for outputs name
date <- Sys.Date()

# number of CPUs allocated in SLURM
ncpus <- 10
options(future.globals.maxSize = 1.5 * 1024^3)  # Set global max size to 1.5 GB

print(">>> set parameters : ok")

##--2) Load the LAS files into a LAS catalog
print(">>> Load the LAS files into a LAS catalog")

nlas <- readLAScatalog(dir)
projection(nlas) <- st_crs(2056)

print(">>> Load normalized LAS files into LAS catalog: ok")

##--3) Load Canopy Height Model raster
print(">>> Load Canopy Height Model")

chm <- rast(chmpath)

##--4) Tree segmentation
# set up parallel processing 
plan(multicore, workers=ncpus)

print(">>> parallel plan set : ok")

#print(">>> Tree segmentation")

# compute the seeds by finding the trees
opt_output_files(nlas) <- ""
ttops<-locate_trees(nlas,lmf(ws=5), uniqueness = "bitmerge")

# remove duplicated treeID
ttops<-ttops %>% distinct(treeID, .keep_all = TRUE)

print(">>> find trees : ok")

# Tree segmentation using chm and ttops as seeds
opt_output_files(nlas) <- file.path(exdir, "{*}_seg")

algo <- dalponte2016(chm,
                     ttops,
                     th_tree = 2,
                     th_seed = 0.45,
                     th_cr = 0.55,
                     max_cr = 10,
                     ID = "treeID")

seg <- segment_trees(nlas, algo)

print(">>> segmentation : ok")

print(">>> Completed")