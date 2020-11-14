require(raster)
# grids and members are numbered stating at 1 and increasing monotonically
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
#grid = args[2]
domain = args[2]

# rst = raster(grid) # crop era5 footprint grid to domain

# # what do you want to define domain? ERA5? DEM? This will extract the required ERA5 gridcells
# #aoi=shapefile(paste0(wd,"/spatial/domain.shp"))
# aoi=raster(paste0(wd,"/predictors/ele.tif"))
# #aoi=raster(paste0(wd,"/forcing/SURF.nc")) # defines domain BUT maybe NOT!
# eraExtent=crop(rst,aoi, snap='out')
#ncells=ncell(domain)
# idRst = setValues(domain , 1:ncells )
# poly = rasterToPolygons(idRst)
# shapefile(poly, paste0(wd,"/spatial/idPoly.shp"), overwrite=TRUE)
ngridsSeq = domain@data[,1]
pdf(paste0(wd,"/spatial/idPoly.pdf"))
plot(domain)
text(coordinates(domain)[,1],coordinates(domain)[,2], ngridsSeq)
dev.off()

for (ic in ngridsSeq){
	setwd(wd)
	#formatC(i, width=5, flag='0')
	simdir=paste0('g',ic)
	dir.create(paste0(wd,"/sim/",simdir), showWarnings=FALSE)
	dir.create(paste0(wd,"/sim/",simdir,"/predictors"), showWarnings=FALSE)
	setwd(paste0(wd,'/predictors'))
	predictors=list.files(pattern='*.tif$')
	Npreds=length(predictors)



		# only cookiecut predicors on ensemble=1
		
		for (p in 1:Npreds){
			if (!file.exists(paste0(wd,'/sim/', simdir,predictors[p]))){
			setwd(paste0(wd,'/predictors'))	
			rst=crop(raster(predictors[p]) ,domain[ic,])
			setwd(paste0(wd,'/sim/', simdir,"/predictors"))
			writeRaster(rst, predictors[p], overwrite=TRUE)
			removeTmpFiles(h=0)
			}
			}
			}
		






