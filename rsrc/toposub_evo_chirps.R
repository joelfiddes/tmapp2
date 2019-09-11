#====================================================================
# SETUP
#====================================================================
#INFO
# new toposub May 2019: uses presribed coffs based on observation that these do not vary much from domain yet are costly to generate using informed routines
# drop sin(asp) (eastness) as predictor - cos(asp) is enough (northness)
# compute sin(asp) required to compute mean aspect for listpoints.txt

#DEPENDENCY
require(raster)
require(FNN)
#SOURCE
source("./rsrc/toposub_src.R")
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
gridpath=args[1]
Nclust=as.numeric(args[2])
svfCompute=args[3]
lowmem=args[4]
#Nclust=args[2] #'/home/joel/sim/topomap_test/grid1' #

#====================================================================
# PARAMETERS FIXED
#====================================================================
#====================================================================
# PARAMETERS FIXED
#====================================================================
#nFuzMem=10 #number of members to retain
iter.max=50	# maximum number of iterations of clustering algorithm
nRand=100000	# sample size
#fuzzy.e=1.4 	# fuzzy exponent
nstart1=10 	# nstart for sample kmeans [find centers]
nstart2=1 	# nstart for entire data kmeans [apply centers]
thresh_per=0.001 # needs experimenting with
samp_reduce=FALSE
algo="Hartigan-Wong"#"MacQueen" # ("Hartigan-Wong", "Lloyd", "Forgy",
#====================================================================
#			TOPOSUB PREPROCESSOR INFORMED SAMPLING		
#====================================================================
setwd(gridpath)

#set tmp directory for raster package
#setOptions(tmpdir=paste(gridpath, '/tmp', sep=''))

setwd(paste0(gridpath,'/predictors'))
predictors=list.files( pattern='*.tif$')

print(predictors)
rstack=stack(predictors)
if(nRand>ncell(rstack) ){nRand<-ncell(rstack)} # check for small ncell (eg era5 and 100m SRTM has only 9^4 cells < nRAND!)
if(Nclust>ncell(rstack) ){Nclust<-ncell(rstack)} # check for small ncell and force Nclust to be less than Ncell
gridmaps<- as(rstack, 'SpatialGridDataFrame')

#decompose aspect
res=aspect_decomp(gridmaps$asp)
gridmaps$aspC<-res$aspC # just add northness to reduce variables now we use chirps
gridmaps$aspS<-res$aspS # need to keep here to calculate mean aspect at end of routine

# remove unecessary dimensions
gridmaps$asp<-NULL
gridmaps$surface<-NULL

#define new predNames (aspC, aspS)
allNames<-names(gridmaps@data)

# use two predname as we dont want to cluster on long and lat but we want the mean attributes of each sample
# filter predictors we get mean attributes for in lsp
predNames1 <- allNames[which(allNames!='surface'&allNames!='asp')]

# filter predictors we put into kmeans
predNames2 <- allNames[which(allNames!='surface'&allNames!='asp'&allNames!='latRst'&allNames!='lonRst')] # remove aspS here

#read coeffs file (prescribed)
weightsMean<-read.table(paste(gridpath,"/coeffs.txt",sep=""), sep=",",header=T)
	
samp_dat<-sampleRandomGrid( nRand=nRand, predNames=predNames2)

#use original samp_dat
informScaleDat1=informScale(data=samp_dat, pnames=predNames2,weights=weightsMean)

#remove NA's from dataset (not tolerated by kmeans)
informScaleDat_samp=na.omit(informScaleDat1)

#kmeans on sample
print(dim(informScaleDat_samp))
print((Nclust))
clust1=Kmeans(scaleDat=informScaleDat_samp,iter.max=iter.max,centers=Nclust, nstart=nstart1)

#scale whole dataset
informScaleDat2=informScale(data=gridmaps@data, pnames=predNames2,weights=weightsMean)

#remove NA's from dataset (not tolerated by kmeans)
informScaleDat_all=na.omit(informScaleDat2)
#kmeans whole dataset
#clust2=Kmeans(scaleDat=informScaleDat_all,iter.max=iter.max,centers=clust1$centers, nstart=nstart2)

if (lowmem==FALSE){
print("Running full Kmeans on entire dataset....")
#clust2=Kmeans(scaleDat=scaleDat_all2,iter.max=iter.max,centers=clust1$centers, nstart=nstart2)
clust2 <- kmeans(x=informScaleDat_all, centers=clust1$centers, iter.max = iter.max, nstart = nstart2, trace=FALSE,algorithm = algo)
#clust2 <-bigkmeans(x=scaleDat_all2, centers=clust1$centers, iter.max = iter.max, nstart = nstart2, dist = "euclid")
#http://stackoverflow.com/questions/21382681/kmeans-quick-transfer-stage-steps-exceeded-maximum
}

if (lowmem==TRUE){
	print("Running lowmem Fast k-nearest neighbor search")
	# https://www.rdocumentation.org/packages/FNN/versions/1.1.3/topics/get.knn
	clust2 <- get.knnx(clust1$center, informScaleDat_all, 1)$nn.index[,1]
}

#**CLEANUP**

rm(informScaleDat_all)
rm(clust1)
gc()

#remove small samples, redist to nearestneighbour attribute space
#if(samp_reduce==TRUE){
#clust3=sample_redist(pix= length(clust2$cluster),samples=Nclust,thresh_per=thresh_per, clust_obj=clust2)# be careful, samlple size not updated only clust2$cluster changed
#}else{clust2->clust3}

#confused by these commented out lines
#gridmaps$clust <- clust3$cluster
#write.asciigrid(gridmaps["landform"], paste(egridpath,"/landform_",Nclust,".tif",sep=''),na.value=-9999)

#make map of clusters 

# new method to deal with NA values 
#vector of non NA index
n2=which(is.na(informScaleDat2$aspC)==FALSE & is.na(informScaleDat2$svf)==FALSE)
#make NA vector
vec=rep(NA, dim(informScaleDat2)[1])
#replace values
#vec[n2]<-as.factor(clust3$cluster)

if (lowmem==FALSE){
	vec[n2]<-as.factor(clust2$cluster)
}
if (lowmem==TRUE){
	vec[n2]<-as.factor(clust2)
}


#**CLEANUP**
rm (informScaleDat2)
gc()

#gridmaps$landform <- as.factor(clust3$cluster)
gridmaps$landform <-vec
#writeRaster(raster(gridmaps["landform"]), paste(spath,"/landform_",Nclust,".tif",sep=''),NAflag=-9999,overwrite=T)
rst=raster(gridmaps["landform"])
writeRaster(rst, paste0(gridpath,"/landform.tif"),NAflag=-9999,overwrite=T)

samp_mean <- aggregate(gridmaps@data[predNames1], by=list(gridmaps$landform), FUN='mean',na.rm=TRUE)
samp_sd <- aggregate(gridmaps@data[predNames1], by=list(gridmaps$landform), FUN='sd',na.rm=TRUE)
samp_sum <- aggregate(gridmaps@data[predNames1], by=list(gridmaps$landform), FUN='sum',na.rm=TRUE)

#replace asp with correct mmean asp
#df=na.omit(as.data.frame(gridmaps))

asp=meanAspect(dat=gridmaps@data, agg=gridmaps$landform)
samp_mean$asp<-asp
#issue with sd and sum of aspect - try use 'circular'

#remove this unecessary (?) I/O
#write to disk for cmeans(replaced by kmeans 2)
#write.table(samp_mean,paste(spath, '/samp_mean.txt' ,sep=''), sep=',', row.names=FALSE)
#write.table(samp_sd,paste(spath, '/samp_sd.txt' ,sep=''), sep=',', row.names=FALSE)

#make driving topo data file	
#lsp <- listpointsMake(samp_mean=samp_mean, samp_sum=samp_sum)


#construct listpoints table
mem<-samp_sum[2]/samp_mean[2]
members<-mem[,1]
colnames(samp_mean)[1] <- "id"
lsp<-data.frame(members,samp_mean)

# Add long lat of gridbox for each sample (which are positionless) in order to satisfy toposcale_sw.R (FALSE)-> solarCompute()
e=extent(rst)
lonbox=e@xmin + (e@xmax-e@xmin)/2
latbox=e@ymin + (e@ymax-e@ymin)/2
lsp$lat <-rep(latbox,dim(lsp)[1])
lsp$lon <-rep(lonbox,dim(lsp)[1])
lsp$surfRough = rep(1e-3,dim(lsp)[1])
lsp$tz = rep(0,dim(lsp)[1])
write.csv(round(lsp,2),paste0(gridpath, '/listpoints.txt'), row.names=FALSE)

pdf(paste0(gridpath,'/landformsInform.pdf'))
plot(rst)
dev.off()

pdf(paste0(gridpath,'/lonlatdist.pdf'))
plot(raster(paste0(gridpath,'/predictors/ele.tif')))
points(samp_mean$lonRst, samp_mean$latRst, col='green', cex=2)
dev.off()


print("TOPOSUB INFORM COMPLETE!")





