require(raster)
# grids and members are numbered stating at 1 and increasing monotonically
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
basin = args[2]

basin = shapefile(basin)

# rst = raster(grid) # crop era5 footprint grid to domain
# #aoi=shapefile(paste0(wd,"/spatial/extent.shp"))
# #aoi=raster(paste0(wd,"/predictors/ele.tif"))
# aoi=raster(paste0(wd,"/forcing/SURF.nc")) # defines domain
# eraExtent=crop(rst,aoi, snap='out')
# ncells=ncell(eraExtent)
# idRst = setValues(eraExtent , 1:ncells )
# poly = rasterToPolygons(idRst)
# shapefile(poly, paste0(wd,"/spatial/idPoly.shp"), overwrite=TRUE)

pdf(paste0(wd,"/spatial/idPoly.pdf"))
plot(basin)
#text(coordinates(poly)[,1],coordinates(poly)[,2], poly$era5_gp)
dev.off()

for (i in 1:length(basin)){
	setwd(wd)
#formatC(i, width=5, flag='0')
	simdir=paste0('g',i)
	dir.create(paste0(wd,"/sim/",simdir), showWarnings=FALSE)
	dir.create(paste0(wd,"/sim/",simdir,"/predictors"), showWarnings=FALSE)
	setwd(paste0(wd,'/predictors'))
	predictors=list.files(pattern='*.tif$')
	Npreds=length(predictors)



		# only cookiecut predicors on ensemble=1
		
		for (p in 1:Npreds){
			setwd(paste0(wd,'/predictors'))	
			rst1=crop(raster(predictors[p]) ,basin[i,])
			#rst = mask(raster(predictors[p]) ,basin[i,]) v slow!
			rst <- trim(rasterize(basin[i,], rst1, mask=TRUE))  # fast

			setwd(paste0(wd,'/sim/', simdir,"/predictors"))
			writeRaster(rst, predictors[p], overwrite=TRUE)
			removeTmpFiles(h=0)
				}
			}
		







