require(raster)
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
rasters1 <- list.files(wd,pattern="*.tif",full.names=TRUE, recursive=FALSE)
rast.list <- list()
  for(i in 1:length(rasters1)) { rast.list[i] <- raster(rasters1[i]) }

# And then use do.call on the list of raster objects
rast.list$fun <- mean
rast.mosaic <- do.call(mosaic,rast.list)
rst<-rast.mosaic
writeRaster(rst, paste0(rasters1[1],"_ALL_OUT.tif"))
