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

print(">>> load packages : ok")

##--1) Set up local path and parameters
# Parameters

# Resolution for output rasters (meter)
resolution <- 2

# number of CPUs allocated in SLURM
ncpus <- 4


print(">>> set parameters : ok")

# Load local paths
scratch <- "/path_to_scratch"
dir <- file.path(scratch, "las_data")

dtmdir <- file.path(scratch, "dtm")
dir.create(dtmdir, showWarnings = FALSE, recursive=TRUE)

reclassdir <- file.path(scratch, "reclass")
dir.create(reclassdir, showWarnings = FALSE, recursive=TRUE)

normdir <- file.path(scratch, "norm")
dir.create(normdir, showWarnings = FALSE, recursive=TRUE)

print(">>> read and create directories : ok")


##--2) Load the LAS files into a LAS catalog
print(">>> Load the LAS files into a LAS catalog")

ldir <- list.files(dir, full.name=TRUE)
las <- readLAScatalog(ldir)

projection(las) <- st_crs(2056)

print(">>> Load LAS files into LAS catalog: ok")

##--3) Normalise LAS Catalog 
print(">>> Normalise LAS Catalog")

# set up parallel processing using 'future' 
plan(multicore, workers = ncpus)

print(">>> parallel plan set : ok")

# Compute Digital Terrain Model
opt_chunk_buffer(las) <- 30
opt_output_files(las) <- file.path(dtmdir, "{*}_dtm") # default is ''
dtm <- rasterize_terrain(las, res = resolution, algorithm = knnidw(k = 6L, p = 2))

gc()
print(">>> compute DTM : ok")

# Normalize height based on the previously computed DTM
opt_output_files(las) <- file.path(normdir, "{*}_norm")

nlas <- normalize_height(las, dtm)

print(">>> normalize LAS : ok")

# Function to reclassify Z values to 0 for specific classifications
reclassify_z <- function(cluster) {
  las <- readLAS(cluster) # Read the LAS data from the cluster
  if (is.empty(las)) return(NULL) # Skip empty clusters
  
  # Reclassify Z values for points with classifications 1, 6, or 17
  las@data[["Z"]][las@data[["Classification"]] %in% c(1, 6, 17)] <- 0
  
  return(las) # Return the modified LAS object
}

# Apply the reclassification function to each tile in the catalog
opt_output_files(nlas) <- file.path(reclassdir, "{*}_reclass")
opt_chunk_buffer(nlas) <- 0
catalog_apply(nlas, reclassify_z)

print(">>> reclassified Z values for specified classes : ok")

print(">>> Completed")