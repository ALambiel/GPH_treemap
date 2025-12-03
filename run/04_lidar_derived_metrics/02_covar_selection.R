library(terra)
library(PerformanceAnalytics)
library(ade4)
library(factoextra)
library(purrr)
library(caret)


## -- local path
dfold <-"/path_to_lidar_metrics_folder"

exfold <- "/path_to_exfold"
dir.create(exfold, recursive=TRUE, showWarnings=FALSE)

## -- parameters
# max correlation threshold
thr <- 0.60

# -- load lidar derived metrics

metrics<- rast(list.files(dfold, pattern = "\\.tif$", full.names=TRUE))


# -- Extract covariates values for some random spatial points
print(paste("Start time:", Sys.time()))
print("Start extraction")

set.seed(12)
extr <- spatSample(metrics, size = 1000, method="random", as.points=TRUE)

# convert it in data frame
extr <- as.data.frame(extr)
extr <- na.omit(extr)

print("Extraction done")

## 1) -- Explore covariates
# compute correlation matrix and do a PCA
print("Start correlation analysis")
M <-cor(extr)

## 2) -- Remove variables that are too much correlated (eg. cor > thr)
print(paste("Remove variables too much correlated, cor >", thr))

# old version
M[lower.tri(M)] <- 0
diag(M) <- 0
ndf <- extr[, !apply(M, 2, function(x) any(abs(x) > thr, na.rm = TRUE))]

# with package caret
#highlyCor <- findCorrelation(M, cutoff=thr)
#ndf <- extr[ ,-highlyCor, drop=FALSE]

print(paste("Done. Following variables will be exported:", c(names(ndf))))

## 3) -- Export selected covariates 

# Create a custom function to export each 'layer' from a 'stack' in a 'directory'

extract_raster <- function(layer, stack, directory) {
  if (!(layer %in% names(stack))) {
    warning(paste(layer, "does not exist in stack raster"))
    return(NULL)
  }
  
  print(paste("Processing:", layer))
  r <- subset(stack, layer)
  output_path <- file.path(directory, paste0(layer, ".tif"))
  
  writeRaster(r, output_path, overwrite=TRUE)
  print(paste("Saved:", output_path))
  
  return(r)
}

valid_layers <- names(metrics)[names(metrics) %in% names(ndf)]
raster_list <- map(valid_layers, extract_raster, stack = metrics, directory = exfold)

print(paste("End time :",Sys.time()))
print("Completed")

