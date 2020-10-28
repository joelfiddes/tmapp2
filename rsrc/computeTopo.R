#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
suppressPackageStartupMessages({
require(raster)
})


#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
#chirpsP=args[2]
#====================================================================
# PARAMETERS FIXED
#====================================================================
rasterOptions(tmpdir=wd)
#**********************  SCRIPT BEGIN *******************************
setwd(wd)
dem=raster('predictors/ele.tif')


#====================================================================
# EXTRACT SLP/ASP
#================================================================= ==
if (!file.exists("predictors/slp.tif")){
	slp=terrain(dem, opt="slope", unit="degrees", neighbors=8, filename='')
	slp[is.na(asp)==T]<-0 # pads raster with 0 so dimension of valid vals same as dem (eg when passed to trim in generating sim files dimension remain the same)
	writeRaster(round(slp,0), "predictors/slp.tif", overwrite=TRUE) #write and reduce precision
	}

if (!file.exists("predictors/asp.tif")){
	asp=terrain(dem, opt="aspect", unit="degrees", neighbors=8, filename='')
	asp[is.na(asp)==T]<-0
	writeRaster(round(asp,0), "predictors/asp.tif", overwrite=TRUE) #write and reduce precision
	}
#====================================================================
# WRITE OUTPUTS
#====================================================================
if (!file.exists("predictors/ndvi.tif")){
	ndvi=raster('predictors/ndvi_modis.tif')
	ncrop = crop(ndvi,dem, snap='out')
	nresamp = resample(ncrop,dem) # resample to ensure no geometry issues in basin cookiecuts
	writeRaster(nresamp, "predictors/ndvi.tif", overwrite=TRUE)
	}
# if (chirpsP==TRUE){
# 	chirps=raster('predictors/chirps.tif')
# if(res(chirps)[1]!=res(dem)[1]){ # in case resampling already done

# 	myfact = res(chirps)[1]/res(dem)[1]
# 	ncrop = crop(chirps,dem, snap='out')
# 	chirps_dis = disaggregate(ncrop,fact=myfact, 'bilinear')	
# 	nresamp = resample(chirps_dis,dem) # resample to ensure no geometry issues in basin cookiecuts
# 	writeRaster(nresamp, "predictors/chirps.tif", overwrite=TRUE)
# }
# coord=coordinates(dem)
# lonRst = setValues(dem,coord[,1])
# latRst = setValues(dem,coord[,2])
# writeRaster(lonRst, "predictors/lonRst.tif", overwrite=TRUE)
# writeRaster(latRst, "predictors/latRst.tif", overwrite=TRUE)
# }