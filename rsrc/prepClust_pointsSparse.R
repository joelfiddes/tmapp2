require(raster)
# grids and members are numbered stating at 1 and increasing monotonically
args = commandArgs(trailingOnly=TRUE)
wd=args[1]

dir.create(paste0(wd,"/sim/"), showWarnings=FALSE)

nfiles=list.files(paste0(wd, "/predictors/"), pattern='ele')

for (file in 1:length(nfiles)){

	ele=raster(paste0(wd,"/predictors/ele",file,".tif"))
	ic=i #formatC(i, width=5, flag='0')
	simdir=paste0('g',ic)
	dir.create(paste0(wd,"/sim/",simdir), showWarnings=FALSE)
	dir.create(paste0(wd,"/sim/",simdir,"/predictors"), showWarnings=FALSE)
	setwd(paste0(wd,'/sim/', simdir,"/predictors"))
	writeRaster(ele, 'ele.tif', overwrite=TRUE)
			
	}
		






