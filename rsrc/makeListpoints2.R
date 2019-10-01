#====================================================================
# SETUP
#====================================================================
#INFO
# A listpoints file has pk, lon, lat order of cols

#DEPENDENCY
require(raster)

#SOURCE

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1] 
shp.in=args[2]

#====================================================================
# PARAMETERS FIXED
#====================================================================

setwd(paste0(wd,'/predictors'))
predictors=list.files( pattern='*.tif$')
print(predictors)
rstack=stack(predictors)
shp <- shapefile(shp.in)
lp = extract(rstack,shp)
lon = shp@coords[,1]
lat = shp@coords[,2]

if (length(shp$Name) >0){name=shp$Name}
id= 1:length(lat)
name=id
if (length(shp$Name) >0){name=shp$Name}
if (length(shp$IMIS_ST) >0){name=shp$IMIS_ST}
surfRough=0.002
tz=0
lp = data.frame(id,lp, lon,lat, surfRough,tz, name)
lp = na.omit(lp)
write.csv(lp, '../listpoints.txt', row.names=FALSE)

# if there is no point in gridbox, remove it
# if (length(lon) < 1){

# 	print ("[makelistpoints2.R] Grid contains no points, removing grid directory")
#     system(paste0('rm -r ', wd))
# }



