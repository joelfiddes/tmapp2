# validates basin points or grids at specific stations
require(raster)
require(maptools)
myshp="~/sim/tmapp_val/master_files/shps/imis_sub.shp"
simDir="/home/joel/sim/tmapp_val/grids/sim1/sim/g18"
# validation points
shp<- readShapePoints(myshp)
ele = raster(paste0(simDir, "/predictors/ele.tif"))
shpcrop = crop(shp, ele)
print(shpcrop$Name)


