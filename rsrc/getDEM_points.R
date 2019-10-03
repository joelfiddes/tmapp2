# this routine is used if dataset is a sparse set of point (eg mongolia) download is done on point + buffer to avoid huge datsets, especially important for svf calc
# even if points are clustered it is efficient in download as recognises if tiles are already downloaded and does not redownload
# therefore in clustered points usually no additional download require4d 
# is not slower than full download in the grid case as no grid is dowloaded more than once.
# merging and cropping functions are redundant in tightly clustered points but i think we can live with that

#DEPENDENCY
require(raster)

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
demDir=args[2]
myshp=args[3]
demRes=args[4]
buffer=args[5]# how much to pad the point in lon/lat degrees

#buffer should be computed dymnamically based on 'maxdist' from svf. Complicated as varies depending on lat

#====================================================================
# PARAMETERS FIXED
#====================================================================
#parse credentials file to get user/pwd: https://urs.earthdata.nasa.gov/profile
#to create ~/.netrc credentials file run lpdaacLogin() (install.package('MODIS')
SERVICE=unlist(strsplit(readLines("~/.netrc")[[1]]," "))[2]
print(paste0('using credentials for: ', SERVICE))
USER=unlist(strsplit(readLines("~/.netrc")[[2]]," "))[2]
PWD=unlist(strsplit(readLines("~/.netrc")[[3]]," "))[2]


#====================================================================
# DEM retrieval based on set of points or polygon:
#====================================================================
dir.create(paste0(wd,'/predictors'), showWarnings=FALSE)
dir.create(paste0(wd,'/spatial'), showWarnings=FALSE)

setwd(demDir)
shp=shapefile(myshp)


# loop through points
for (mypoint in 1:length(shp$lat)){
print(mypoint)
eraExtent = extent(shp[mypoint,])+(buffer*2)


# extent in whole degrees for dem download to completely cover eragrid cell
demExtent = floor(eraExtent)

# get range of ll corners for dem download -1 term prevents neighbouring grid being downloaded
lon = c(demExtent@xmin: (demExtent@xmax -1) )
lat = c(demExtent@ymin: (demExtent@ymax -1) )

# if dimensions are different then replication will occur - watch this
if ( length(lon) == length(lat) ){
df= expand.grid(data.frame(lon,lat))
} else {

latmat = matrix(rep(lat, length(lon)),ncol=length(lon),nrow=length(lat))
lonmat = matrix(rep(lon, length(lat)),ncol=length(lon),nrow=length(lat),byrow=TRUE)
lat=as.vector(latmat)
lon = as.vector(lonmat)
df= data.frame(lon,lat)
}

	ngrids=length(df[,1])
	print (paste0("Retrieving ",ngrids, " SRTM30 grids (1x1 deg)"))
	#clean up
	system("rm SRTMDAT*")
	system("rm *.hgt")

	for (i in 1:(dim(df)[1])){
		if (sign(df$lat[i])==-1){LATVAL<-"S"}
		if (sign(df$lat[i])==1){LATVAL<-"N"}
		if (sign(df$lon[i])==-1){LONVAL<-"W"}
		if (sign(df$lon[i])==1){LONVAL<-"E"}
		lon_pretty=formatC(abs(df$lon[i]),width=3,flag="0")
		#get tile
		filetoget=paste0(LATVAL,abs(df$lat[i]),LONVAL,lon_pretty,".SRTMGL",demRes,".hgt.zip")
		filetogetUNZIP=paste0(LATVAL,abs(df$lat[i]),LONVAL,lon_pretty,".hgt")

	if (file.exists(filetoget)){ #dont download again
	   print(paste0(filetoget, " exists"))
	   	system(paste0("unzip ", filetoget))
		system(paste0("gdal_translate -q -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=2 ", filetogetUNZIP, " SRTMDAT",i,".tif"))
		} else {
		 
			system(paste0("wget --user ", USER ,  " --password " ,PWD, " http://e4ftl01.cr.usgs.gov//MODV6_Dal_D/SRTM/SRTMGL",demRes,".003/2000.02.11/",filetoget))
			# extract
			system(paste0("unzip ", filetoget))
			system(paste0("gdal_translate -q -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=2 ", filetogetUNZIP, " SRTMDAT",i,".tif"))
		}
	}

#====================================================================
# MERGE RASTER
#====================================================================
demfiles=list.files(pattern="SRTMDAT*")
if(length(demfiles)>1){
rasters1 <- list.files(pattern="SRTMDAT*",full.names=TRUE, recursive=FALSE)
rast.list <- list()
  for(i in 1:length(rasters1)) { rast.list[i] <- raster(rasters1[i]) }

# And then use do.call on the list of raster objects
rast.list$fun <- mean
rast.mosaic <- do.call(mosaic,rast.list)
dem<-rast.mosaic
}else{
	dem <- raster(demfiles)
}
#setwd(wd)

# crop merged raster to eraExtent
ele <- crop(dem, eraExtent)

#outputs
writeRaster(ele, paste0(wd, '/predictors/ele',mypoint,'.tif'), overwrite=TRUE)
}

