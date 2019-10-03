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

nfiles=list.files(paste0(wd, "/predictors/"), pattern='ele')
lpvec=c()
for (file in 1:length(nfiles)){


predictors=list.files( pattern=paste0('*',file,'.tif$'))
print(predictors)
rstack=stack(predictors)
shp <- shapefile(shp.in)
lp = extract(rstack,shp[file,])
lon = shp@coords[file,1]
lat = shp@coords[file,2]

if (length(shp$Name[file]) >0){name=shp$Name[file]}
id= 1:length(shp@coords[,1])
name=id[file]
id = id[file]
if (length(shp$Name[file]) >0){name=shp$Name[file]}
if (length(shp$IMIS_ST[file]) >0){name=shp$IMIS_ST[file]}
surfRough=0.002
tz=0
lp = data.frame(id,lp, lon,lat, surfRough,tz, name)
lp = na.omit(lp)
names(lp)<-c('id','asp','ele','slp','svf', 'lon','lat', 'surfRough','tz', 'name')
lpvec=rbind(lpvec,lp)
}

lpvec$svf <- round(lpvec$svf,2)

write.csv(lpvec, '../listpoints.txt', row.names=FALSE)

# if there is no point in gridbox, remove it
# if (length(lon) < 1){

# 	print ("[makelistpoints2.R] Grid contains no points, removing grid directory")
#     system(paste0('rm -r ', wd))
# }



