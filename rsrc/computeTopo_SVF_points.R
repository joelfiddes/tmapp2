# we dowwnload a section of dem per point
# for each dem generate asp, slp and svf
args = commandArgs(trailingOnly=TRUE)
gridpath = args[1]
angles = as.numeric(args[2])
dist = as.numeric(args[3])

require(horizon)
nfiles=list.files(paste0(gridpath, "/predictors/"), pattern='ele')

for (file in 1:length(nfiles)){
#if(!file.exists(paste0(gridpath, "/predictors/svf.tif"))){
print(file)
	ele=raster(paste0(gridpath, "/predictors/ele",file,".tif"))
	s <- svf(ele, nAngles=angles, maxDist=dist, ll=TRUE)
	slp=terrain(ele, opt="slope", unit="degrees", neighbors=8, filename='')
	asp=terrain(ele, opt="aspect", unit="degrees", neighbors=8, filename='')

	writeRaster(round(s,2), paste0(gridpath, "/predictors/svf",file,".tif"), overwrite=TRUE) #write and reduce precision
	writeRaster(round(slp,0), paste0(gridpath, "/predictors/slp",file,".tif"), overwrite=TRUE) #write and reduce precision
	writeRaster(round(asp,0),paste0(gridpath, "/predictors/asp",file,".tif"), overwrite=TRUE) #write and reduce precision

	}
