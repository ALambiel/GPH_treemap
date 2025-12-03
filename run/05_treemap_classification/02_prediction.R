library(terra)
library(ranger)
library(caret)


####
#-------- 1) Local paths and variables
####

# - Local paths

input_folder <- "/path_to_aviris_folder"

# Output folder and subfolders
output_folder <- "/path_to_output_folder"

# Model Files
pca_model_path <- "/path_to/pca_model.rds"
rf_model_path <- "/path_to/rf_model.rds"

# Covariates folder if needed
covar_folder <- "" #"/srv/beegfs/scratch/users/l/lambiela/lidar/covar"



classification_folder <- file.path(output_folder, "classification")
probability_folder <-file.path(output_folder, "probabilities")

dir.create(classification_folder, recursive=TRUE, showWarnings = FALSE)
dir.create(probability_folder, recursive=TRUE, showWarnings = FALSE)

# Read Models
pca_model <- readRDS(pca_model_path)
rf_model <- readRDS(rf_model_path)

# List AVIRIS-NG images
wrapped_files <- list.files(input_folder, pattern = "\\.(dat|tif)$", full.names = TRUE)

####
#-------- 2) Tree species prediction
####


# Prediction Loop
start <- Sys.time()
message("Starting processing...")

for (i in seq_along(wrapped_files)) {
  # Load and preprocess data
  band <- rast(wrapped_files[i])
  band <- band[[-c(1:7, 187:217, 281:330, 408:425)]] # Remove noisy bands
  names(band) <- rownames(pca_model$rotation)
  band_name <- tools::file_path_sans_ext(basename(wrapped_files[i]))
  
  # Apply PCA
  pca_result <- predict(band, pca_model)
  message(paste("PCA applied on", band_name))
  
  # Check and read covariates rasters if available
  covar_files <- list.files(covar_folder, full.names = TRUE)
  use_covar <- length(covar_files) > 0
  
  if (use_covar) {
    stck <- c(rast(covar_files))
    stck <- crop(stck, pca_result)
    stck <- resample(stck, pca_result, method="bilinear")
    stck <- mask(stck, pca_result)
    predictors <- c(pca_result, stck)
    message("Covariates loaded successfully.")
  } else {
    predictors <- pca_result
    message("No covariates found. Proceeding without covariates.")
  }
  
  # Predict Tree Species and Probabilities
  tree_class <- predict(predictors, rf_model, na.rm = TRUE) # 1 band raster, with the final predicted class
  tree_prob <- predict(predictors, rf_model, type = "prob", na.rm = TRUE) # 5 bands raster, one for each possible class and the associated probability of prediction

  # Save Intermediate Outputs (raw predictions)
  writeRaster(tree_class, file.path(classification_folder, paste0(band_name, "_class.tif")), overwrite = TRUE)
  writeRaster(tree_prob, file.path(probability_folder, paste0(band_name, "_prob.tif")), overwrite = TRUE)
  
  gc()
  
  message(paste0("Classification complete for band: ", band_name))
}

end <- Sys.time()
message("Classification complete. Total time elapsed: ", round(difftime(end, start, units = "mins"), 2), " minutes.")




