#====================================================================
# SETUP
#====================================================================
#INFO

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
Nclust=args[2]
targV=args[3]
svfCompute=args[4]
lowmem=args[5]
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

#read listpoint
listpoints=read.csv(paste(gridpath,'/listpoints.txt',sep=''))


setwd(paste0(gridpath,'/predictors'))
predictors=list.files( pattern='*.tif$')

print(predictors)
rstack=stack(predictors)

gridmaps<- as(rstack, 'SpatialGridDataFrame')

#decompose aspect
res=aspect_decomp(gridmaps$asp)
gridmaps$aspC<-res$aspC
gridmaps$aspS<-res$aspS

# remove unecessary dimensions
gridmaps$asp<-NULL
gridmaps$surface<-NULL

#define new predNames (aspC, aspS)
allNames<-names(gridmaps@data)
predNames2 <- allNames[which(allNames!='surface'&allNames!='asp')]



#initialise file to write to
pvec<-rbind(predNames2)
x<-cbind("tv",pvec,'r2')
write.table(x, paste(gridpath,"/coeffs.txt",sep=""), sep=",",col.names=F, row.names=F)
write.table(x, paste(gridpath,"/decompR.txt",sep=""), sep=",",col.names=F, row.names=F)

# read mean values of targV
meanX=read.table( paste(gridpath, '/meanX_', targV,'.txt', sep=''), sep=',')

# compute coeffs of linear model
coeffs=linMod2(meanX=meanX,listpoints=listpoints, predNames=predNames2,col=targV, svfCompute=svfCompute) #linear model

if(sum(as.numeric(coeffs),na.rm=TRUE) == 0){stop("inform targetV variable all zero counts in obs period (tip: are you using SWE in summer for informed scaling routine?) or does preprocessed era in eraDat/all etc match set time period in ini file?")} # This catches the case where targV does not have values in simulation period eg. using snow water equivalent in summer sim period, also case where forcing meteo has been recyldced for another simulation but the preprocessed time slice left in place. forcing and simulation period then do not overlap. First simulation runs without errors but inform will not work.

write(coeffs, paste(gridpath,"/coeffs.txt",sep=""),ncolumns=7, append=TRUE, sep=",") # 6 cols if no svf
weightsMean<-read.table(paste(gridpath,"/coeffs.txt",sep=""), sep=",",header=T)

#==========mean coeffs table for multiple preds ================================
#coeffs_vec=meanCoeffs(weights=weights, nrth=nrth) #rmove nrth
##y<-rbind(predNames)
#y <- cbind(y,'r2')
#write.table(y, paste(egridpath,"/coeffs_Mean.txt",sep=""), sep=",",col.names=F, row.names=F)
#write(coeffs_vec, paste(egridpath,"/coeffs_Mean.txt",sep=""),ncolumns=(length(predNames)+1), append=TRUE, sep=",")
#weightsMean<-read.table(paste(egridpath,"/coeffs_Mean.txt",sep=""), sep=",",header=T)	
	
samp_dat<-sampleRandomGrid( nRand=nRand, predNames=predNames2)

#use original samp_dat
informScaleDat1=informScale(data=samp_dat, pnames=predNames2,weights=weightsMean)

#remove NA's from dataset (not tolerated by kmeans)
informScaleDat_samp=na.omit(informScaleDat1)

#kmeans on sample
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

samp_mean <- aggregate(gridmaps@data[predNames2], by=list(gridmaps$landform), FUN='mean',na.rm=TRUE)
samp_sd <- aggregate(gridmaps@data[predNames2], by=list(gridmaps$landform), FUN='sd',na.rm=TRUE)
samp_sum <- aggregate(gridmaps@data[predNames2], by=list(gridmaps$landform), FUN='sum',na.rm=TRUE)

#replace asp with correct mmean asp
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
members<-mem$ele
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


print("TOPOSUB INFORM COMPLETE!")





