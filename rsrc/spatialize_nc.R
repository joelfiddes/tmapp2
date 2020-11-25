require(raster)

args = commandArgs(trailingOnly=TRUE)
tsub_root = args[1]
meanVar= args[2]
nclust = as.numeric(args[3])
outname = args[4]
ngrid=args[5]
outroot = args[6]

gridseq =1:ngrid

meanswe =read.csv(paste0(outroot,meanVar) ,head=F )


	for (i in 1:length(gridseq)){
		print(i)
		grid = gridseq[i]
		sample_indexes = (i-1)*nclust+(1:nclust)

		swe =meanswe[sample_indexes,2]
		s <- 1:length(swe)
		df <- data.frame(s,swe)
		landform=raster(paste0(tsub_root,"/sim/g",grid,"/landform.tif"))

		rst <- subs(landform, df,by=1, which=2)
		writeRaster(rst, paste0(outroot,outname, "g",grid,"_swe.tif"),overwrite=TRUE)
		}





require(raster)



rasters1 <- list.files(outroot, pattern=paste0(outname,"g"),full.names=TRUE, recursive=TRUE) # just looks for indiv grids
rast.list <- list()
for(i in 1:length(rasters1)) { rast.list[i] <- raster(rasters1[i]) }

# And then use do.call on the list of raster objects
rast.list$fun <- mean
rast.mosaic <- do.call(mosaic,rast.list)
hist<-rast.mosaic
# plot(hist,zlim=zlim, col=mycol, main= "1980-2000 Hist ")
# writeRaster(hist, paste0(outroot,outname,"_map.nc"),overwrite=TRUE, format="CDF",     varname="HS", varunit="m",    longname="Snow height", xname="Longitude",   yname="Latitude", zname="Time")

hist_agg = aggregate(hist, fact=9,mean)
writeRaster(hist_agg, paste0(outroot,outname,"_map.tif"),overwrite=TRUE)

for (i in 1:length(rasters1)){
	system(paste0("rm ",rasters1[i]))
	}


# call ncat
# setwd(outroot)
# system(paste0("cdo -b F64 -f nc2 mergetime *map.nc ", tsub_root,"/spatial/",column,"_COMPLETE.nc"))