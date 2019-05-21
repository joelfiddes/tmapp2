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

resultsVec <- c()

for (i in 1:Nclust){

# returns datapoint given sampleN and date and targV
datpoint = sampleResultsNow(gridpath = home, sampleN = i, targV = targV, date = date)
resultsVec <- c(resultsVec, datpoint)	
}

landform<-raster(paste0(home, "/landform.tif")	)
rst = crispSpatialNow(resultsVec, landform)
writeRaster(rst, paste0(home, "/", targV, date,".tif"))