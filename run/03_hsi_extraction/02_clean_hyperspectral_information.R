library(terra)
library(devtools)
library(ggplot2)
library(dplyr)


## -- local path

dir <-"/path_to_wd"

refpath <-  "/path_to_ref_flightlines/ang20210710t082017_rfl.tif"

hsi_path <- "/path_to/hsi.rds"

## -- Load HSI
hsi <- readRDS(file.path(dir, hsi_path))

## -- Clean HSI extraction
## compute some metrics (sd) in order to remove ouliers

## 1) Pre-process data

## -- load a flightline as template
print(paste("Start time:", Sys.time()))

fl <- rast(refpath)

# Get the wavelengths 
print("Get the wavelengths and remove noisy bands")

wavelengths <- as.numeric(sub(" Nanometers", "", names(fl)))
wavelengths <- round(wavelengths, 2)

# Remove noisy wavelengths 

if (length(wavelengths) == 425) {
  wv <- wavelengths[-c(1:7, 187:217, 281:330, 408:425)]
  wv_cover <- c(wavelengths[8], wavelengths[186], wavelengths[218], wavelengths[280], wavelengths[331], wavelengths[407])
} else {
  stop("Error : Check dimension of hsi data frame.")
}


# set names in the new data frame 

names(hsi) <- c("sp", "x", "y", "ID", wv)


## 2) Remove outliers
print("Remove outliers")

# custom function to remove outliers

remove_outliers <- function(x) {
  Q1 <- quantile(x, 0.25, na.rm=TRUE) 
  Q3 <- quantile(x, 0.75, na.rm=TRUE)  
  IQR <- Q3 - Q1
  
  # threshold to define outliers
  lower_bound <- Q1 - 1.5 * IQR
  upper_bound <- Q3 + 1.5 * IQR
  
  # keep only non-outliers
  x[x < lower_bound | x > upper_bound] <- NA
  return(x)
}

# list of species factors
species <- c("AA", "AP", "FE", "FS", "PA")

# 'for' loop through species
for (sp in species) {
  print(paste("start for:", sp))
  # keep data for the species 'sp'
  subset_data <- subset(hsi, hsi$sp == sp)
  
  # Aplly cleaning function on reflectance values' columns 
  subset_cleaned <- subset_data
  subset_cleaned[, 5:ncol(subset_data)] <- lapply(subset_data[, 5:ncol(subset_data)], remove_outliers)
  print("Ok.")
}

# removing outliers
hsiclean <- na.omit(subset_cleaned)

# save results
nam <- paste0("HSI_pts_extract_clean_IQR_", Sys.Date(), ".rds")
saveRDS(hsiclean, file.path(dir, nam))

print(paste("End time :",Sys.time()))
print("Completed")