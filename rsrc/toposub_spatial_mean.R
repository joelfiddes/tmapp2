#!/usr/bin/env Rscript

#====================================================================
# SETUP
#====================================================================
#INFO
# Genrates mean annual maps
# example: joel@mountainsense:~/src/tmapp2$ Rscript rsrc/toposub_spatial_mean.R /home/joel/sim/paiku/sim 100 X100.000000 2000-09-01 2005-09-01

# generates mean annual temp at 10m
#.libPaths("/home/caduff/R/x86_64-redhat-linux-gnu-library/3.3")
#DEPENDENCY

 a=R.Version()

print( a$version.string)
library(raster)
#SOURCE
source("./rsrc/toposub_src.R")

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args <- 	commandArgs(trailingOnly=TRUE)
gridpath <- args[1]
Nclust <-	args[2]
targV <- 	args[3]
beg <- 		args[4] #"%Y-%m-%d"
end <- 		args[5] #"%Y-%m-%d"
#====================================================================
# PARAMETERS FIXED
#====================================================================
# Timeformats: This needs to be aligned with main time input
#beg <- "01/07/2010 00:00:00"
#end <- "01/07/2011 00:00:00"
	crisp <- TRUE #other options as separate functions]
	fuzzy <- FALSE
	VALIDATE <- FALSE

	if(targV == "snow_water_equivalent.mm."){file1 <- "surface.txt"}
	if(targV == "snow_depth.mm."){file1 <- "surface.txt"}
	if(targV == "X100.000000"){file1 <- "ground.txt"}

#========================================================================
#		FORMAT DATE
#========================================================================
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

if(crisp==TRUE){
	##make crisp maps
	landform<-raster("landform.tif")	
	crispSpatial2(col=targV,Nclust=Nclust,esPath=gridpath, landform=landform)
	}

# ============== NEW FUNCTIONS NEEDED ======================
#make fuzzy maps
if(fuzzy==TRUE){
	mask=raster(paste('/mask',predFormat,sep=''))
	#fuzSpatial(col=targV, esPath=gridpath, format=predFormat, Nclust=Nclust,mask=mask)
	fuzSpatial_subsum(col=targV, esPath=gridpath, format=predFormat, Nclust=Nclust, mask=mask)
	}

if(VALIDATE==TRUE){
	dat <- read.table(paste('/meanX_',targV,'.txt',sep=''), sep=',',header=F)
	dat<-dat$V1
	fuzRes <- calcFuzPoint(dat=dat,fuzMemMat=fuzMemMat)
	write.table(fuzRes, '/fuzRes.txt', sep=',', row.names=FALSE)
	}



