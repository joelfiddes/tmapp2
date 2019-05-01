#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)



#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]

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
slp=terrain(dem, opt="slope", unit="degrees", neighbors=8, filename='')
asp=terrain(dem, opt="aspect", unit="degrees", neighbors=8, filename='')

#====================================================================
# WRITE OUTPUTS
#====================================================================

writeRaster(round(slp,0), "predictors/slp.tif", overwrite=TRUE) #write and reduce precision
writeRaster(round(asp,0), "predictors/asp.tif", overwrite=TRUE) #write and reduce precision


ndvi=raster('predictors/ndvi.tif')
ndvi2 = crop(ndvi,dem)
writeRaster(ndvi2, "predictors/ndvi.tif", overwrite=TRUE)
