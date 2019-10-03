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
simdir=args[3]
#====================================================================
# PARAMETERS FIXED
#====================================================================

setwd(paste0(wd,'/predictors'))
shpIndex = as.numeric(unlist(strsplit(simdir,'g'))[2])


predictors=list.files( pattern=paste0('*.tif$'))
print(predictors)
rstack=stack(predictors)
shp <- shapefile(shp.in)
lp = extract(rstack,shp[shpIndex,])
lon = shp@coords[shpIndex,1]
lat = shp@coords[shpIndex,2]

if (length(shp$Name[shpIndex]) >0){name=shp$Name[shpIndex]}
#id= 1:length(shp@coords[,1])
name=shpIndex
id = shpIndex
if (length(shp$Name[shpIndex]) >0){name=shp$Name[shpIndex]}
if (length(shp$IMIS_ST[shpIndex]) >0){name=shp$IMIS_ST[shpIndex]}
surfRough=0.002
tz=0
lp = data.frame(id,lp, lon,lat, surfRough,tz, name)
lp = na.omit(lp)

write.csv(lpvec, '../listpoints.txt', row.names=FALSE)

# if there is no point in gridbox, remove it
# if (length(lon) < 1){

# 	print ("[makelistpoints2.R] Grid contains no points, removing grid directory")
#     system(paste0('rm -r ', wd))
# }



