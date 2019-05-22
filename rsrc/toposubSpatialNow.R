#DEPENDENCY
require(raster)
#SOURCE
source("./rsrc/toposub_src.R")
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args <- 	commandArgs(trailingOnly=TRUE)
home <- args[1]
Nclust <-args[2]
targV <- 	args[3]
date <- 	args[4]

# Nclust <- 10
# targV <- "snow_depth.mm."
# date <- "21/05/2014 00:00"
# home="/home/joel/sim/amu_evo//sim/g80/"
	if(targV == "snow_water_equivalent.mm."){file1 <- "surface.txt"}
	if(targV == "snow_depth.mm."){file1 <- "surface.txt"}
	if(targV == "X100.000000"){file1 <- "ground.txt"}

resultsVec <- c()

for (i in 1:Nclust){
print(i)
# returns datapoint given sampleN and date and targV
#datpoint = sampleResultsNow(gridpath = home, sampleN = i, targV = targV, date = date)

	#gsimindex=formatC(i, width=5,flag='0')
	simindex <- paste0(home, '/c',formatC(i, width=5,flag='0'))

	#read in lsm output
	sim_dat <- read.table(paste(simindex,'/out/',file1,sep=''), sep=',', header=T)

	# Get last data point
	dateIndex = which(sim_dat$Date12.DDMMYYYYhhmm.== date)
	
	dat <- sim_dat[dateIndex,targV]

resultsVec <- c(resultsVec, dat)	
}

landform<-raster(paste0(home, "/landform.tif")	)
rst = crispSpatialNow(resultsVec, landform)
writeRaster(rst, paste0(home, "/", targV, "maxSWE.tif"), overwrite=TRUE)