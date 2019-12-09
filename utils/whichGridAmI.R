# returns grid ids (ordered by row) of validation points

# eg. joel@mountainsense:~/src/tmapp2/utils$ Rscript whichGridAmI\?.R /home/joel/sim/barandunPaper/amu_grid/ /home/joel/sim/barandunPaper/amu_points/spatial/TJ1981over2000.shp 
require(raster)
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
valPoints=args[2]
delete=args[3]
#wd="/home/joel/sim/barandunPaper/amu_grid"
#valPoints="/home/joel/sim/barandunPaper/amu_points/spatial/TJ1981over2000.shp"


wgai = function (wd, valPoints, delete=FALSE){
valPoints =shapefile(valPoints)
grid=shapefile(paste0(wd,"/spatial/idPoly.shp"))

 g =extract(grid, valPoints)
 df=data.frame(g$point.ID, g$poly.ID)

 if (delete==TRUE){

alldirs = list.dirs(path = paste0(wd,"/sim/"), recursive=F)
dirs2keep = paste0(wd,"/sim/g", g$poly.ID) 

newdir=paste0(wd, "/sims2")
olddir=paste0(wd, "/sim")
system(paste0("mkdir ",newdir))

for(i in 1: length(dirs2keep) ){
system(paste0("mv ", dirs2keep[i]," ",newdir))
}

system(paste0("rm -r ",olddir))
system(paste0("mv ", newdir," ",olddir))

 }

 return(df)
}

wgai(wd, valPoints, delete=FALSE)