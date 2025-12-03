library(terra)

setwd("/path_to_wd")

fold<-"/path_to_metrics_folder"

exdir <- "/path_to_output_folder"
dir.create(exdir, recursive=TRUE, showWarnings=FALSE)


x<-list.files(fold, pattern="\\.tif$", full.names = TRUE)

z<-list(c(101:200))

for(i in z){
  y<-x[i]
  
  tiles<-vrt(y,paste("tiles_raster_",i[1],".vrt",sep=""), overwrite=T)
  
  print(i[1])
  
  writeRaster(tiles,paste(exdir, "/tiles_raster_",i[1],".tif",sep=""),overwrite=T)
  
  print(paste(i[1]," written",sep=""))
  
  
}
print("Completed")