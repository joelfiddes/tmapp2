library(raster)
source("./rsrc/toposub_src.R")
args <- 	commandArgs(trailingOnly=TRUE)
gridpath <- args[1]
mode <-	args[2]
targV <- 	args[3]
beg <- 		args[4] #"%Y-%m-%d"
end <- 		args[5] #"%Y-%m-%d"

# gridpath <-"/home/joel/sim/tsub_PCLUST/sim/g1"
# mode <- "average" or instant
# targV <- 	"X100.000000"#"snow_water_equivalent.mm."
# beg <- 		"2013-09-01"
# end <- 		"2014-09-01" #"%Y-%m-%d"

	


if(targV == "snow_water_equivalent.mm."){file1 <- "surface.txt"}
if(targV == "snow_depth.mm."){file1 <- "surface.txt"}
if(targV == "X100.000000"){file1 <- "ground.txt"}
lp=read.csv(paste0(gridpath, "/listpoints.txt"))
Nclust= length(lp[,1])






if(mode=="average"){
d=strptime(beg, format="%Y-%m-%d", tz=" ")
geotopStart=format(d, "%d/%m/%Y %H:%M")

d=strptime(end, format="%Y-%m-%d", tz=" ")
geotopEnd=format(d, "%d/%m/%Y %H:%M")
#====================================================================
# TOPOSUB POSTPROCESSOR 2		
#====================================================================


setwd(gridpath)
outfile <- paste('meanX_',targV,'.txt',sep='')
file.create(outfile)

for ( i in 1:Nclust){
	#gsimindex=formatC(i, width=5,flag='0')
	simindex <- paste0('c',formatC(i, width=5,flag='0'))

	#read in lsm output
	sim_dat <- read.table(paste(simindex,'/out/',file1,sep=''), sep=',', header=T)

	#cut timeseries
	sim_dat_cut <- timeSeriesCut( sim_dat=sim_dat, beg=geotopStart, end=geotopEnd)	

	#mean annual values
	#timeSeries2(spath=gridpath,colP=targV, sim_dat_cut=sim_dat_cut,FUN=mean)

	#compute mean value of target variable for sample
	meanX<-	tapply(sim_dat_cut[,targV],sim_dat_cut$IDpoint, FUN=mean)

	#append to master file
	write(meanX, paste(gridpath, '/meanX_', targV,'.txt', sep=''), sep=',',append=T)
	}

	landform<-raster("landform.tif")	
	crispSpatial2(col=targV,Nclust=Nclust,esPath=gridpath, landform=landform)

}

if(mode=="instant"){

date=paste0(unlist(strsplit(beg,"-"))[3],"/",unlist(strsplit(beg,"-"))[2],"/",unlist(strsplit(beg,"-"))[1]," 00:00")



resultsVec <- c()

for (i in 1:Nclust){
print(i)
# returns datapoint given sampleN and date and targV
#datpoint = sampleResultsNow(gridpath = home, sampleN = i, targV = targV, date = date)

	#gsimindex=formatC(i, width=5,flag='0')
	simindex <- paste0(gridpath, '/c',formatC(i, width=5,flag='0'))

	#read in lsm output
	sim_dat <- read.table(paste(simindex,'/out/',file1,sep=''), sep=',', header=T)

	# Get last data point
	dateIndex = which(sim_dat$Date12.DDMMYYYYhhmm.== date)
	
	dat <- sim_dat[dateIndex,targV]

resultsVec <- c(resultsVec, dat)	
}

landform<-raster(paste0(gridpath, "/landform.tif")	)
rst = crispSpatialNow(resultsVec, landform)
writeRaster(rst, paste0(gridpath, "/", targV, "_",beg,".tif"), overwrite=TRUE)

}
