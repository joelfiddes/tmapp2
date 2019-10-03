#====================================================================
# SETUP
#====================================================================
#INFO
#make horizon files MOVED TO SEPERATE SCRISPT
#hor(listPath=wd)
#MODISoptions() controls settings

#DEPENDENCY
#require('MODIS') # https://cran.r-project.org/web/packages/MODIS/MODIS.pdf
require('rgdal') #dont understand why need to load this manually
require(raster)
#SOURCE
#source("/home/joel/src/TOPOMAP/toposubv2/workdir/toposub_src.R")

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
home=args[1]
ndviThreshold=as.numeric(args[2])#threshold to distinguish between veg and non-veg



#====================================================================
# PARAMETERS FIXED
#====================================================================


#PARAMETERS TO BOECKLI 2012 SLOPE MODEL
smin=35
smax=55
#introduce parameter for debris/bedrock class split




#**********************  SCRIPT BEGIN *******************************

nfiles=list.files(paste0(home, "/predictors/"), pattern='ele')

for (file in 1:length(nfiles)){
	if(!file.exists(paste0(home,'/predictors/surface',file,'.tif'))){
#====================================================================
#	fetch and compute MODIS NDVI
#====================================================================
ndvi = raster(paste0(home, "/predictors/ndvi.tif"))
myextent=raster(paste0(home,'/predictors/ele',file,'.tif')) # output is projected and clipped to this extent
ndvi=crop(ndvi,myextent)

from=c(0, ndviThreshold)
to=c(ndviThreshold, 1)
becomes=c(0,1)
rcl= data.frame(from, to, becomes)
meanNDVIReclass = reclassify(ndvi, rcl) #1=veg 0=no veg
#====================================================================
#	compute bedrock debris slope model (Boeckli 2012)
#====================================================================

slp=raster(paste0(home,'/predictors/slp',file,'.tif'))
slpModel = calc(slp, fun=function(x){(x - smin) / (smax-smin)})

#crisp classes ie split by 45 degree slope
from=c(-9999, 0.5)
to=c(0.5, 9999)
becomes=c(1,2)
rcl= data.frame(from, to, becomes)
slpModelReclass = reclassify(slpModel, rcl)

#====================================================================
#	combine rock model and veg map
#====================================================================
subsdf=data.frame(1,0)
reclassVeg=subs(x=meanNDVIReclass,  y=subsdf, by=1, which=2, subsWithNA=TRUE) #values 1 (veg) become 2 , values 0 (no veg) become NA


surf= resample(reclassVeg, slpModelReclass, method='ngb') #resample done on main ndvi layer now to avoid geometry issues in basin clips

surfaceModel=cover(surf, slpModelReclass) #0= veg, 1=debris , 2=steep bedrock

#====================================================================
#	output
#====================================================================

writeRaster(surfaceModel, paste0(home,'/predictors/surface',file,'.tif'), overwrite=TRUE)


#pdf(paste0(home,'/surfaceClassMap.pdf'), width=6, height =12)
#par(mfrow=c(2,1))
#arg <- list(at=seq(0,2,1), labels=c("Vegetation (0)","Debris (1)","Steep bedrock (2)")) #these are the class names
#color=c("lightgreen","grey","red") #and color representation
#plot(surfaceModel, col=color, axis.arg=arg, main='Surface class distribution')
#hist(surfaceModel, main='Surface class frequency')
#dev.off()
}
}
#====================================================================
#	zonal stats
#====================================================================

# zones=raster('landform.tif')
# zoneStats=zonal(surfaceModel,zones, modal,na.rm=T)
# write.table(zoneStats, 'landcoverZones.txt',sep=',', row.names=F)
# print(zoneStats)
