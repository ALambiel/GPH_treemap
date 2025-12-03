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

dir <- "/path_to/seg"

exdir <- "/path_to_exdir"
dir.create(exdir, showWarnings=FALSE, recursive=TRUE)

print(">>> read and create directories : ok")

##--0) Load packages

# Parameters
min_crown_area <- 12 # in square meter
min_height <- 2 # in meter https://www.tandfonline.com/doi/full/10.1080/15481603.2023.2171706#d1e315

subset <- c(1:100)
subnam <- "1_100"

# set the date for outputs name
date <- Sys.Date()

print(">>> set parameters : ok")

##--2) Load the segmented LAS files into a LAS catalog
print(">>> Load the LAS files into a LAS catalog")

seg <- readLAScatalog(dir)
projection(seg) <- st_crs(2056)

print(">>> Load normalized LAS files into LAS catalog: ok")


##--3) Metrics related to tree and individual tree crown delineation
print(">>> Individual tree crown delineation")

opt_progress(seg) <- FALSE

seg$processed <- FALSE
seg$processed[subset] <- TRUE

tree.hulls <- lidR::delineate_crowns(seg, func = .stdtreemetrics, type = "concave", attribute = "treeID")

# filtering to small crown
itc <- tree.hulls[tree.hulls$convhull_area>= min_crown_area,]
itc <- vect(itc)
terra::crs(itc) <- "epsg:2056"

# Save results as vector layers 
writeVector(itc, file.path(exdir, paste0(date, "_ITC_", subnam, ".shp")), overwrite=TRUE)

print(">>> Completed")