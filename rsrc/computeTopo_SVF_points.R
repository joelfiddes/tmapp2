# we dowwnload a section of dem per point
# for each dem generate asp, slp and svf
args = commandArgs(trailingOnly=TRUE)
home = args[1]
angles = as.numeric(args[2])
dist = as.numeric(args[3])

 require(raster)

# rasters1 <- list.files(home,pattern="ele.tif",full.names=TRUE, recursive=TRUE)
# rast.list <- list()
# for(i in 1:length(rasters1)) { rast.list[i] <- raster(rasters1[i]) }

# # And then use do.call on the list of raster objects
# rast.list$fun <- mean
# rast.mosaic <- do.call(mosaic,rast.list)
# rst<-rast.mosaic
# writeRaster(rst, paste0(home, "/predictors/ele.tif"), overwrite=TRUE)

 require(horizon)


#if(!file.exists(paste0(home, "/predictors/svf.tif"))){ In case of restart this causes possible mising slp/asp - needs to check for all files

		ele=raster(paste0(home, "/predictors/ele.tif"))
		s <- svf(ele, nAngles=angles, maxDist=dist, ll=TRUE)
		slp=terrain(ele, opt="slope", unit="degrees", neighbors=8, filename='')
		asp=terrain(ele, opt="aspect", unit="degrees", neighbors=8, filename='')

		writeRaster(round(s,2), paste0(home, "/predictors/svf.tif"), overwrite=TRUE) #write and reduce precision
		writeRaster(round(slp,0), paste0(home, "/predictors/slp.tif"), overwrite=TRUE) #write and reduce precision
		writeRaster(round(asp,0),paste0(home, "/predictors/asp.tif"), overwrite=TRUE) #write and reduce precision

		#}

