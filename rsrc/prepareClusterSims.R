require(raster)
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
grid = args[2]

rst = raster(grid)
aoi=shapefile(paste0(wd,"/spatial/extent.shp"))
eraExtent=crop(rst,aoi, snap='out')
ncells=ncell(eraExtent)
idRst = setValues(eraExtent , 1:ncells )
poly = rasterToPolygons(idRst)
shapefile(poly, paste0(wd,"/spatial/idPoly.shp"), overwrite=TRUE)

pdf(paste0(wd,"/spatial/idPoly.pdf"))
plot(poly)
text(coordinates(poly)[,1],coordinates(poly)[,2], poly$era5_gp)
dev.off()

nensembles=10
for (j in 1:nensembles){
	jc=formatC(j, width=4, flag='0')
	
	for (i in 1:ncells){
	setwd(wd)
	ic=formatC(i, width=5, flag='0')
	simdir=paste0('c',ic,'e',jc)
	dir.create(paste0(wd,"/sim/",simdir), showWarnings=FALSE)
	dir.create(paste0(wd,"/sim/",simdir,"/predictors"), showWarnings=FALSE)
	setwd(paste0(wd,'/predictors'))
	predictors=list.files(pattern='*.tif$')
	Npreds=length(predictors)


	if (j==1){
		# only cookiecut predicors on ensemble=1
		
		for (p in 1:Npreds){
			setwd(paste0(wd,'/predictors'))	
			rst=crop(raster(predictors[p]) ,poly[poly$era5_gp==1,])
			setwd(paste0(wd,'/sim/', simdir,"/predictors"))
			writeRaster(rst, predictors[p], overwrite=TRUE)
			removeTmpFiles(h=0)
				}
			}
		
		if(j>1){ 
		# cp cut predictors from ensemble 1 to ensemble n to save time
		simdir1 =paste0('c',ic,'e0001')
		system(paste0("cp -r ",paste0(wd,'/sim/', simdir1,"/predictors" )," ", paste0(wd,'/sim/', simdir) ) )
		}
	}

}

