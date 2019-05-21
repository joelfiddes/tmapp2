# generate output results
args = commandArgs(trailingOnly=TRUE)
home = args[1]
nens = as.numeric(args[2])
file=args[3] # "surface" or "ground"
param=args[4]
day = as.numeric(args[5]) # 212 = March 31 on non leap year


#lp= read.csv(paste0(home, "/listpoints.txt"))
lf=raster(paste0(home,"/landform.tif"))

resMat=c()
simpaths =list.files(paste0(home), pattern="c00*")

for (j in simpaths){ 
	#simindex=paste0('S',formatC(j, width=5,flag='0'))
	dat = read.table(paste0(home,"/", j,"/out/",file,".txt"), sep=',', header=T)
	tv <- dat[param]
	resMat = cbind(resMat,tv[,1]) # this index collapse 1 column dataframe to vector
	rst=raster(resMat)
}

#swe
# Vect = lp$members
# varr <- aperm(array(Vect, dim = c(dim(resMat)[2], dim(resMat)[1])), perm = c(2L, 1L))
# arr <- varr * resMat

# day 212 = 31 March on a non leap year
l2 =data.frame(cbind((1:dim(resMat)[2]), resMat[day,] ))

rst = subs(lf,l2 ,by=1, which=2)
writeRaster(rst, paste0(home, param,"_ol.tif"))

# find and plot merged files


da=list.files(wd, "*_da.tif" , recursive=T,full.names=TRUE)
rast.list <- list()
  for(i in 1:length(da)) { rast.list[i] <- raster(da[i]) }

# And then use do.call on the list of raster objects
rast.list$fun <- mean
rast.mosaic <- do.call(mosaic,rast.list)
dam<-rast.mosaic


da=list.files(wd, "*_ol.tif" , recursive=T,full.names=TRUE)
rast.list <- list()
  for(i in 1:length(da)) { rast.list[i] <- raster(da[i]) }

# And then use do.call on the list of raster objects
rast.list$fun <- mean
rast.mosaic <- do.call(mosaic,rast.list)
olm<-rast.mosaic




