args = commandArgs(trailingOnly=TRUE)
gridpath = args[1]
angles = as.numeric(args[2])
dist = as.numeric(args[3])

require(horizon)

if(!file.exists(paste0(gridpath, "/predictors/svf.tif"))){
	ele=raster(paste0(gridpath, "/predictors/ele.tif"))
	s <- svf(ele, nAngles=angles, maxDist=dist, ll=TRUE)
	writeRaster(round(s,2), paste0(gridpath, "/predictors/svf.tif"), overwrite=TRUE) #write and reduce precision
	}
