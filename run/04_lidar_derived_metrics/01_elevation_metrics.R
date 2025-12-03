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

tempdir <- file.path(scratch, "elev")
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
process_basenames <- sub("_z\\.tif$", "", process_files)
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

mySelectedMetrics_pxl <- function(z) {
  
  # Metrics derived from stdmetrics_z (related to height/elevation "z")
  nz <- length(z)
  zq <- stats::quantile(z, probs = c(0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95))
  zmean = mean(z)

  metrics <- list(
    zmax = max(z), 
    zmean = zmean, 
    zsd = sd(z), 
    zskew = skewness(z), 
    zkurt = kurtosis(z),
    pzabovezmean = sum(z > zmean) / nz * 100,
    pzabove2 = sum(z > 2) / nz * 100, 
    zq5 = zq[1], 
    zq25 = zq[3], 
    zq50 = zq[4], 
    zq75 = zq[5], 
    zq95 = zq[7]
   )
  
   return(metrics) 
}


# Create a shortcut with default values for dz, th, zmin, and pass selected metrics
.mySelectedMetrics_pxl <- ~mySelectedMetrics_pxl(Z) 

# Set up parallel processing using 'future'
plan(multicore, workers = ncpus)

print(">>> parallel plan set : ok")

# Standard metrics computation at the pixel level
opt_output_files(nlas) <- file.path(tempdir, "{*}_z")
#opt_chunk_size(nlas) <- 1000
pxl_metrics <- pixel_metrics(nlas, func=.mySelectedMetrics_pxl, res=resolution)

print(">>> compute pixels metrics : ok")

writeRaster(pxl_metrics, file.path(exdir, "elevation_pxlmetrics.tif"), overwrite=TRUE)

print(">>> Completed")