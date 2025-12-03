library(terra)
library(data.table)


## -- local path

aviris <- "/path_to_aviris_folder"

exfold <-"/path_to_output_folder"
dir.create(exfold, recursive=TRUE, showWarnings=FALSE)

sampl <- "/path_to/groundref.csv"

itcpath <- "/path_to_/itc.shp"

## -- load data

## -- Field points
ts <- fread(sampl, sep = ",")[, -1] # "sp" "id" "TreeID" "x" "y"
setDT(ts)

## -- Clean it (drop unwanted levels of sp if they are still presents in the dataframe)
ts[, sp := as.factor(sp)]
ts[, sp := droplevels(sp)]


## Convert it to spatial object
tsp <- vect(ts, geom=c("x", "y"), crs = "EPSG:2056")

## -- read AVIRIS-NG images

wrapped <- c(list.files(aviris, pattern = "\\.dat$", full.names = TRUE),
             list.files(aviris, pattern = "\\.tif$", full.names = TRUE))

## -- Load Individual Tree Crowns

itc_list <- list.files(itcpath, pattern = "\\.shp$", full.names = TRUE)

## -- Initialize object to store relevant crowns
polygons <- NULL  


## STEP 1: Find tree crowns containing field points
print(paste("Start time:", Sys.time()))
for (i in seq_along(itc_list)) {
  print(i)
  
  ## -- Load subset of tree crowns
  itc <- vect(itc_list[i])
  
  ## -- Identify which crowns contain field points
  # return the indices (itc in x and tsp in y) of the case where requested relation is true
  index <- relate(itc, tsp, "intersects", pairs=TRUE, na.rm=TRUE)
  
  if (nrow(index) == 0) {
    print("No matching crowns. Next...")
    next
  }
  
  ipoly <- index[,1]
  ipoints <- index[,2]
  
  selected <- itc[ipoly]
  
  ## -- Add 'sp', 'x' and 'y' from matching field points
  selected$sp <- tsp$sp[ipoints]
  selected$x <- ts$x[ipoints]
  selected$y <- ts$y[ipoints]
  
  print(paste("Adding", nrow(selected), "new crowns."))
    
  ## -- Merge results
  polygons <- if (is.null(polygons)) selected else rbind(polygons, selected)
  print("Done. Next...")
}

print(paste("Tree crown selection complete. Found", nrow(polygons), "crowns."))
print("Step1 completed")

# Tree crown selection complete. Found 747 crowns.

## STEP 2: Extract Mean Reflectance

# free up some space
rm(itc)
rm(selected)
gc()

# initialize the output data frame
df_list <- list()

for (i in seq_along(wrapped)){ 
  
  ## load AVIRIS-NG flightline 
  line <- rast(wrapped[i])
  
  ## -- Extract mean reflectance for each tree crown polygon
  extr<-extract(line, polygons, fun = mean, na.rm = TRUE)
  
  ## -- Merge with crown information
  info <- as.data.frame(polygons[, c('sp','x', 'y')])
  extr <- cbind(info, extr) 
  
  extr[extr == "NaN"] <- NA
  extr[extr<0] <- NA
  
  fl<-na.omit(extr)
  
  colnames(fl)<-sub(".*rfl_", "", as.vector(colnames(fl)))
  
  df_list[[i]] <-fl
  
  print(paste("Reflectance extraction is done on",i,"flightlines. Process done at",round((i*100/length(wrapped)),3),"%"))
}

## -- Remove double extractions based on ID

df <- do.call(rbind, df_list)

df<-df[!duplicated(df$ID), ]

## -- drop noisy bands aka bands 1:7, 187:217, 281:330, and 408:425

df <- df[,-c(5:11,191:221,285:334,412:429)]

print("Step2 completed")

print(paste0(nrow(df)," points have been extracted"))

## -- save extraction results
nam <- paste0("HSI_ITC_extract_all_", Sys.Date(), ".rds")
saveRDS(df, file.path(exfold, nam))

print(paste("End time :",Sys.time()))

print("Completed")