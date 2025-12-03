# load packages
library(dplyr)
library(sf)
library(terra)
library(raster)

# set up local path

cfiles_path <- "/path_to/classification"
pfiles_path <- "/path_to/probabilities"


exfold <- "/path_to_output_dir"
dir.create(exfold, recursive = TRUE, showWarnings = FALSE)

polygons_path <- "/path_to/itc.gpkg"

outlines_path <- "/path_to_flightlines_outlines"

# files list

outlines_list <- list.files(outlines_path, full.names=TRUE, pattern="\\.shp$")

cfiles_list <- list.files(cfiles_path, full.names = TRUE, pattern = "\\.tif$")
pfiles_list <- list.files(pfiles_path, full.names = TRUE, pattern = "\\.tif$")

start <- Sys.time()
print(paste("Start time : ",start))

# load polygon layer
poly <- st_read(polygons_path)

print("Loading polygon layer: ok")

# Custom function to apply zonal statistic for each polygons and clean final raster according to proba of prediction
process_raster <- function(classif_path, proba_path, outline_path, poly, exfold) {
  nam <- basename(classif_path)
  nam <- sapply(strsplit(nam,"_"),"[",1)
  print(paste0("Start processing ", nam))
  
  # read raster maps
  rc <- rast(classif_path)
  rp <- rast(proba_path)
  print("Load raster maps: ok")
  
  # keep only maximum probability
  rp_max <- app(rp, max)
  
  # combine raster maps
  r <- c(rc, rp_max)
  names(r) <- c("class", "prob")
  print("Combine raster maps: ok")
  
  # crop polygon layer with raster extent
  poly_crop <- st_crop(poly, ext(r)+5)
  if(nrow(poly_crop)==0){
    print(paste0(nam, " is not covered by ITC. Next"))
    return(NULL)
  } else {
    poly_crop$index <- c(1:nrow(poly_crop)) # indexing each polygon
    print("Crop polygon layer: ok")
    
    # Get a raster mask with each tree as a patch
    msk <- rasterize(poly_crop, r, field = "index")

    #Mask it with the ouline flightline
    outline <- vect(outline_path)
    msk <- mask(msk, outline)
    print("Rasterize mask: ok")
    
    # Compute zonal statistics
    majority_class <- zonal(r[[1]], msk, "modal", na.rm = TRUE)
    print("Majority class: ok")
    
    mean_prob <- zonal(r[[2]], msk, "mean", na.rm = TRUE)
    print("Mean probability: ok")
    
    # Create final raster with unique class and mean probability
    r2 <- classify(msk, majority_class)
    r2 <- c(r2, classify(msk, mean_prob))
    names(r2) <- c("class", "prob")
    print("Reclassify with unique class and mean probability: ok")
    
    # Re-ranking maps according to the probability of prediction: 
    # 0 for all tree with a probability lower than the fixed thr  
    prob_df <- data.frame(index = mean_prob[, 1], prob = mean_prob[, 2])
    thr <- quantile(prob_df$prob, probs = 0.07, na.rm = TRUE)
    print(paste0("Threshold for re-ranking is fixed at p = ", thr))
    
    # Reclass "Class" by 0 when "prob" =< thr
    r2$class[r2$prob <= thr] <- 0 
    print("Re-ranking: ok")
    
    # save final raster
    output <- r2$class
    output_path <- file.path(exfold, paste0(nam, "_vf.tif"))
    writeRaster(output, output_path, overwrite = TRUE, NAflag=-9999)
    print(paste0(nam, " : Done."))
    
    return(output_path)
  }
}

# Apply custom function
results <- mapply(process_raster, cfiles_list, pfiles_list, outlines_list, MoreArgs = list(poly = poly, exfold = exfold))


end <- Sys.time()
print(end-start)

print("Completed")