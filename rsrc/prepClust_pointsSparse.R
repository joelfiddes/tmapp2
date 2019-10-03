require(raster)
# grids and members are numbered stating at 1 and increasing monotonically
args = commandArgs(trailingOnly=TRUE)
wd=args[1]

dir.create(paste0(wd,"/sim/"), showWarnings=FALSE)

nfiles=list.files(paste0(wd, "/predictors/"), pattern='ele')

ndvi = raster(paste0(wd, "/predictors/ndvi.tif"))



for (file in 1:length(nfiles)){

	ele=raster(paste0(wd,"/predictors/ele",file,".tif"))
	simdir=paste0('g',file)
	dir.create(paste0(wd,"/sim/",simdir), showWarnings=FALSE)
	dir.create(paste0(wd,"/sim/",simdir,"/predictors"), showWarnings=FALSE)
	setwd(paste0(wd,'/sim/', simdir,"/predictors"))
	writeRaster(ele, 'ele.tif', overwrite=TRUE)

	ndvicut=crop(ndvi,ele)
	writeRaster(ndvicut, 'ndvi.tif', overwrite=TRUE)

			
	}
		






