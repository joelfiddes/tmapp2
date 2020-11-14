#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)
require(sp)

#SOURCE
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
n=as.numeric(args[1])
s=as.numeric(args[2])
e=as.numeric(args[3])
w=as.numeric(args[4])
out=args[5]
grid=args[6]


aoi <- as(raster::extent(w, e, s, n), "SpatialPolygons")
proj4string(aoi) <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
#shapefile(aoi, out, overwrite=TRUE)

rst = raster(grid) # crop era5 footprint grid to domain

eraExtent=crop(rst,aoi, snap='out')
ncells=ncell(eraExtent)
idRst = setValues(eraExtent , 1:ncells )
poly = rasterToPolygons(idRst)
shapefile(poly, out, overwrite=TRUE)



# library(raster)
# e <- aoient( c(4304916, 4305325, 365216, 365439) )
# p <- as(e, 'SpatialPolygons')
# crs(p) <- "+proj=utm +zone=18 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"
# shapefile(p, 'file.shp')
