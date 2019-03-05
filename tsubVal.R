# test to compare toposub lowmem to toposub original.

require(raster)
require(hydroGOF)

#wd="/home/joel/mnt/myserver/sim/wfj_era5/grid1/"

# norm
wd = "/home/joel/sim/topomapptest/sim/g1m1/"
landform = raster(paste0(wd,"landformInformOrig.tif"))
lp = read.csv(paste0(wd,"listpointsInformOrig.txt"))
ele = raster(paste0(wd,"predictors/ele.tif"))

latest <- lp$ele

l<-length(latest)
s = seq(1,l,1)

latestdf <- data.frame(s,latest)
rst = subs(landform, latestdf,by=1, which=2)
rst=round(rst,2)

# lowmem
landform = raster(paste0(wd,"landform.tif"))
lp = read.csv(paste0(wd,"listpoints.txt"))
ele = raster(paste0(wd,"predictors/ele.tif"))
latest <- lp$ele

l<-length(latest)
s = seq(1,l,1)

latestdf <- data.frame(s,latest)
rst2 = subs(landform, latestdf,by=1, which=2)
rst2=round(rst2,2)



rmse(getValues(rst2),getValues(ele))
rmse(getValues(rst),getValues(ele))

par(mfrow=c(1,3))
plot(rst, main="original")
plot(rst2,main="lowmem")
plot(ele)
#cor(getValues(ele), getValues(rst))
#plot(getValues(ele), getValues(rst))
#writeRaster(rst, paste(esPath,'/crispINST_',col,'_','.tif', sep=''),overwrite=T)


