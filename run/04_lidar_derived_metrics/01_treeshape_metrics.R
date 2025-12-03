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
library(moments)
library(stats)


##--1) Set up local path and parameters
print(">>> Set up local path and parameters")

# Load local paths

scratch <- "/path_to_folder/lidar"

dir <- file.path(scratch, "reclass")

tempdir <- file.path(scratch, "shape")
dir.create(tempdir, recursive=TRUE, showWarnings=FALSE)

exdir <- file.path(scratch, "lidar_metrics")
dir.create(exdir, recursive=TRUE, showWarnings=FALSE)

print(">>> read directory : ok")

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

# List files in each 'origin' and 'process' folders
origin_files <- list.files(dir)
process_files <- list.files(tempdir)

# Extract the base names (without suffix)
process_basenames <- sub("_shape\\.tif$", "", process_files)
origin_basenames <- tools::file_path_sans_ext(origin_files)

# Find the indices of files in 'origin' that are not in the base names of 'process'
missing_indices <- which(!(origin_basenames %in% process_basenames))

ldir <- list.files(dir, full.names=TRUE)[missing_indices]
nlas <- readLAScatalog(ldir)
projection(nlas) <- st_crs(2056)

print(">>> Load normalized LAS files into LAS catalog: ok")

##--3) LiDAR derived metrics 
print(">>> LiDAR derived metrics")
# https://www.sciencedirect.com/science/article/pii/S030324341830504X#sec0010

# Set up parallel processing using 'future'
plan(multicore, workers = ncpus)

print(">>> parallel plan set : ok")

# Standard metrics computation at the pixel level
opt_output_files(nlas) <- file.path(tempdir, "{*}_shape")
#opt_chunk_size(nlas) <- 1000
pxl_metrics <- pixel_metrics(nlas, func=.stdshapemetrics, res=resolution)

print(">>> compute pixels metrics : ok")

writeRaster(pxl_metrics, file.path(exdir, "treeshape_pxlmetrics.tif"), overwrite=TRUE)

print(">>> Completed")