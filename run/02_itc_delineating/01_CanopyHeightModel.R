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

chmdir <- file.path(scratch, "chm")
dir.create(chmdir, showWarnings = FALSE, recursive=TRUE)


exdir <- file.path(scratch, "lidar_metrics")
dir.create(exdir, recursive=TRUE, showWarnings=FALSE)


print(">>> read and create directories : ok")

# Parameters
# Resolution for output rasters (meter)
resolution <- 2

# set the date for outputs name
date <- Sys.Date()

# number of CPUs allocated in SLURM
ncpus <- 10

print(">>> set parameters : ok")

##--2) Load the LAS files into a LAS catalog
print(">>> Load the LAS files into a LAS catalog")

nlas <- readLAScatalog(dir)
projection(nlas) <- st_crs(2056)

print(">>> Load normalized LAS files into LAS catalog: ok")

##--3) Canopy Height Model
print(">>> Canopy Height Model")

# set up parallel processing 
plan(multicore, workers=ncpus)

print(">>> parallel plan set : ok")

# create a CHM stored on disk and returned as a light virtual raster

opt_output_files(nlas) <- file.path(chmdir, "{*}_chm")
chm <- rasterize_canopy(las = nlas, 
                        res = resolution, 
                        algorithm = pitfree(c(0,2,5,10,15),c(0,1.5)))
gc()

# write it in output folder
names(chm) <- "CHM"
writeRaster(chm, file.path(exdir, paste0(date, "_CanopyHeightModel.tif")),overwrite=TRUE)

print(">>> compute and save CHM : ok")
print(">>> Completed")