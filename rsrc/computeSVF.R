args = commandArgs(trailingOnly=TRUE)
gridpath = args[1]
angles = as.numeric(args[2])
dist = as.numeric(args[3])

require(horizon)

if(!file.exists(paste0(gridpath, "/predictors/svf.tif"))){
	ele=raster(paste0(gridpath, "/predictors/ele.tif"))
	s <- svf(ele, nAngles=angles, maxDist=dist, ll=TRUE)
	s[is.na(s)==T]<-1 # changes boundary NAs as 1 - this prevenets white bounday line of NA in lanform.tif (from toposub ) and therfore results. This is Ok as boundaries (basin) likely to be riges/peaks with svf=1 or close to 1.
	s=mask(crop(s ,ele),ele) # bit of a hack as creates boundary effect better compute on crop of basin then mask to basin shape, snap='out' cuased failures here no idea why

	writeRaster(round(s,2), paste0(gridpath, "/predictors/svf.tif"), overwrite=TRUE) #write and reduce precision
	}
