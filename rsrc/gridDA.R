# file origin PBSgrid2.R
# dependency


source("./rsrc/PBS.R") 
require(raster) 
require(zoo)
args <- 	commandArgs(trailingOnly=TRUE)
home <- args[1]
nens <-as.numeric(args[2])
startSim <- 	args[3]
endSim <- 	args[4]
startda <- 	args[5]
endda <- 	args[6]

 # home='/home/joel/sim/amu_evo//sim/g80/'
 # nens = 20 #100#50
 # startSim="2013-09-01"
 # endSim="2014-09-01"
 # startda="2013-09-01"
 # endda="2014-09-01"

# constants
mode = "swe" # 'swe'
sdThresh=13
R=0.016
DSTART =  240
DEND =  330
param="snow_water_equivalent.mm." # for deterministic plot
file="surface" # for determoinistic plot

# load files
rstack = brick(paste0(home,"/fsca_stack.tif"))
obsTS = read.csv(paste0(home,"/fsca_dates.csv"))
landform = raster(paste0(home,"/landform.tif"))
dem = raster(paste0(home,"/predictors/ele.tif"))
lp= read.csv(paste0(home, "/listpoints.txt"))

# total number of MODIS pixels
npix = ncell( rstack)

# area of domain in km2
aod = cellStats(area(landform), sum) 

#====================================================================
#	Crop fsca here
#====================================================================
fscacrop = paste0(home, "/fsca_crop.tif")
if (!file.exists(fscacrop)) {

    # cut temporal length of dates vector to startda/endda
    startda.index <- which(obsTS$x == startda)
    endda.index <- which(obsTS$x == endda)

    # subset rstack temporally
    print(paste0("subset rstack temporally:", startda," to ",endda))
    rstack = rstack[[startda.index:endda.index]]

    # subset dates vector to current year
    obsTScut <- obsTS$x[startda.index:endda.index]
    write.csv(obsTScut, paste0(home, "/fsca_dates_cut.csv"), row.names = FALSE)

    # analyse missing days
    actualDays <- seq(as.Date(startda), as.Date(endda), 1)
    NactualDays <- length(actualDays)
   writeRaster(rstack, fscacrop, overwrite = TRUE)

    # crop spatial
    rstack =crop(rstack,landform)

    # write out
    writeRaster(rstack, fscacrop, overwrite = TRUE)

} else {
    print(paste0(fscacrop, " already exists."))
    rstack <- stack(fscacrop)
}

#====================================================================
#	Load ensemble results matrix
#====================================================================
#Load ensemble results matrix
load(paste0(home, "//ensembRes.rd"))

# subset temporally
totalTS <- seq(as.Date(startSim), as.Date(endSim), 1)
start.index <- which(totalTS == startda)
end.index <- which(totalTS == endda)
ensembRes <- ensembRes[start.index:end.index, , ]
print(paste0("ensembRes cut to: ", startda, " to ", endda))



# convert swe > sdThresh to snowcover = TRUE/1
ensembRes[ ensembRes <= sdThresh ] <- 0
ensembRes[ ensembRes > sdThresh ] <- 1

# compute weighted  fsca by memebership
#https://stackoverflow.com/questions/34520567/r-multiply-second-dimension-of-3d-array-by-a-vector-for-each-of-the-3rd-dimension
Vect = lp$members

# dimension that contains data first in making array, then reorder array using 'perm'
varr <- aperm(array(Vect, dim = c(dim(ensembRes)[2], dim(ensembRes)[1], dim(ensembRes)[3])), perm = c(2L, 1L, 3L))
arr <- varr * ensembRes


# compute mean MOD fSCA per sample
HX <- apply(arr, FUN = "sum", MARGIN = c(1,3)) / sum(lp$members)


#===============================================================================
#	mean obs routine based on cloud free - HIGH MEMORY USE!!!!
#===============================================================================

# memory safe implementation
print("doing memory bit")
s = rstack
r = landform

obs=c()
for (i in 1:nlayers(rstack)){
    print(i)
dstack=disaggregate(rstack[[i]], fact=c(round(dim(r)[1]/dim(s)[1]),round(dim(r)[2]/dim(s)[2])), method='') #fact equals r/s for cols and rows
estack=resample(dstack, landform,  method="ngb")
newobs <- cellStats(estack, 'mean') /100	
obs=c(obs,newobs)
}


#obs <- cellStats(estack, 'mean') /100
nNa=c()
for ( i in 1:nlayers(rstack) ) {
x=rstack[[i]]
countNa <-  sum(  getValues(is.na(x))  )/ncell(x) 

nNa = c(nNa, countNa)
}

# find highNA scenes and set to NA
index = which(nNa > 0.1)
obs[index] <- NA



#glaciers = min(obs,na.rm=T)
#obs = obs - glaciers


	
#===============================================================================
#		PARTICLE FILTER
#===============================================================================	
OBS<-obs
obsind = which (!is.na(obs))
obsind <- obsind[obsind > DSTART & obsind < DEND]
naind = which (is.na(obs))	
weight = PBS(HX[obsind,], OBS[obsind], R)
	
write.csv(as.vector(weight), paste0(home,"/ensemble/weights.txt"), row.names=FALSE)
	
#===============================================================================
#		Deterministic runs
#===============================================================================	
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
Vect = lp$members
varr <- aperm(array(Vect, dim = c(dim(resMat)[2], dim(resMat)[1])), perm = c(2L, 1L))
arr <- varr * resMat
hx_swe <- apply(arr, FUN = "sum", MARGIN = c(1)) / sum(lp$members)

# fsca
# convert swe > sdThresh to snowcover = TRUE/1
resMat[ resMat <= sdThresh ] <- 0
resMat[ resMat > sdThresh ] <- 1

Vect = lp$members
varr <- aperm(array(Vect, dim = c(dim(resMat)[2], dim(resMat)[1])), perm = c(2L, 1L))
arr <- varr * resMat
hx_fsca <- apply(arr, FUN = "sum", MARGIN = c(1)) / sum(lp$members)
#===============================================================================
#		PLOTTING fSCA
#===============================================================================
gridname=unlist(strsplit(home,"/"))[length(unlist(strsplit(home,"/")))]
png(paste0(home,"/ensemble/daplot_",gridname,".png"), width=800, height=400)
par(mfrow=c(1,2))

OBS2PLOT <-OBS
OBS2PLOT[naind]<-NA
prior =HX

weight = as.vector(weight)
ndays = length(obs)
lq=0.1
uq=0.85

# ======================= posterior = ==========================================

# median
med.post = c()
for ( days in 1:ndays){
print(days)
mu = prior[ days, ]
w = weight
wfill <- weight

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.5,rule=2)
med.post = c(med.post, med$y)
}

# low
low.post = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = weight
wfill <- weight

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=lq, rule=2)
low.post = c(low.post, med$y)
}

# high
high.post = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = weight
wfill <- weight

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=uq, rule=2)
high.post = c(high.post, med$y)
}



# ======================= prior = ==========================================

# median
med.pri = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = rep((1/nens),nens)
wfill <- w

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.5)
med.pri = c(med.pri, med$y)
}

# low
low.pri = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = rep((1/nens),nens)
wfill <- w

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=lq)
low.pri = c(low.pri, med$y)
}

# high
high.pri = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = rep((1/nens),nens)
wfill <- w

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=uq)
high.pri = c(high.pri, med$y)
}


date = seq(as.Date(startda), as.Date(endda),by='day')

#  xlim=c(date[182],date[355])
plot(date,high.pri, col=NULL, type='l', main=paste('fSCA'), ylab="fSCA (0-1)",xlab='')
#lines(low.pri, col='red')
lines(date,med.pri, col='red', lwd=3)
#lines(high.post, col='blue')
#lines(low.post, col='blue')
lines(date,med.post, col='blue', lwd=3)

# posterior blue
#y = c(low.post ,rev(high.post))
#x = c(1:length(low.post), rev(1:length(high.post)) )

y = c(low.post ,rev(high.post))
x = c(date[1]:date[length(low.post)], rev(date[1]:date[length(high.post)]) )

polygon (x,y, col=rgb(0, 0, 1,0.5),border='NA')

# prior red
#y = c(low.pri ,rev(high.pri))
#x = c(1:length(low.pri), rev(1:length(high.pri)) )
y = c(low.pri ,rev(high.pri))
x = c(date[1]:date[length(low.pri)], rev(date[1]:date[length(high.pri)]) )

polygon (x,y, col=rgb(1, 0, 0,0.5),border='NA')
#lines(high.pri, col='red')
#lines(low.pri, col='red')
lines(date,med.pri, col='red', lwd=3)
#lines(high.post, col='blue')
#lines(low.post, col='blue')
lines(date,med.post, col='blue', lwd=3)
points(date,OBS2PLOT, col='black', pch=3, lwd=4)
lines(date, hx_fsca, col='green', lwd=3)
legend("topright", c("prior", "posterior", "obs", "open-loop") , col=c("red", "blue", "black", "green"), lty=c(1,1,NA),pch=c(NA,NA, 3))
#abline(v=DSTART)
#abline(v=DEND)
#dev.off()

abline(v=DSTART, lty=3)
abline(v=DEND, lty=3)
#====================================================================
#	# Now plot SWE (or HS)
#====================================================================



if(mode=='hs'){load(paste0(home, "//ensembRes_HS.rd")) ; ensembRes <- ensembResHS}
if (mode=='swe'){load(paste0(home, "//ensembRes.rd"))}
# compute weighted  fsca by memebership
#https://stackoverflow.com/questions/34520567/r-multiply-second-dimension-of-3d-array-by-a-vector-for-each-of-the-3rd-dimension
Vect = lp$members
varr <- aperm(array(Vect, dim = c(dim(ensembRes)[2], dim(ensembRes)[1], dim(ensembRes)[3])), perm = c(2L, 1L, 3L))
arr <- varr * ensembRes


# compute mean MOD fSCA per sample
HX2 <- apply(arr, FUN = "sum", MARGIN = c(1,3)) / sum(lp$members)


OBS2PLOT <-OBS
OBS2PLOT[naind]<-NA
prior =HX2
weight = as.vector(weight)
ndays = length(obs)



# ======================= posterior = ==========================================

# median
med.post = c()
for ( days in 1:ndays){

mu = prior[ days, ]
w = weight
wfill <- weight

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.5, rule=2)
med.post = c(med.post, med$y)
}

# low
low.post = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = weight
wfill <- weight

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=lq, rule=2)
low.post = c(low.post, med$y)
}

# high
high.post = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = weight
wfill <- weight

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=uq, rule=2)
high.post = c(high.post, med$y)
}



# ======================= prior = ==========================================

# median
med.pri = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = rep((1/nens),nens)
wfill <- w

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.5, rule=2)
med.pri = c(med.pri, med$y)
}

# low
low.pri = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = rep((1/nens),nens)
wfill <- w

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=lq, rule=2)
low.pri = c(low.pri, med$y)
}

# high
high.pri = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = rep((1/nens),nens)
wfill <- w

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=uq, rule=2)
high.pri = c(high.pri, med$y)
}

# conversion of mean mm swe to basin wide km3
 # aod in km2 / #mm in km
#pdf(paste0(wd,"/swe_grid.pdf"))

if(mode=='swe'){cfact = aod/1000000}
if (mode=="hs"){cfact=1}

# ADD DATE
date = seq(as.Date(startda), as.Date(endda),by='day')

#,xlim=as.Date(c(date[100],date[355]))
plot(date,  high.pri*cfact, col=NULL, type='l', main=paste('SWE'), ylab="Total domain SWE (km3)" , xlab="")
#lines(low.pri*cfact, col='red')
lines(date, med.pri*cfact, col='red', lwd=3)
#lines(high.post*cfact, col='blue')
#lines(low.post*cfact, col='blue')
lines( date, med.post*cfact, col='blue', lwd=3)

# posterior blue
#y = c(low.post*cfact ,rev(high.post*cfact))
#x = c(1:length(low.post), rev(1:length(high.post)) )

y = c(low.post*cfact ,rev(high.post*cfact))
x = c(date[1]:date[length(low.post)], rev(date[1]:date[length(high.post)]) )

polygon (x,y, col=rgb(0, 0, 1,0.5),border='NA')

# prior red
#y = c(low.pri*cfact ,rev(high.pri*cfact))
#x = c(1:length(low.pri), rev(1:length(high.pri)) )
y = c(low.pri*cfact ,rev(high.pri*cfact))
x = c(date[1]:date[length(low.pri)], rev(date[1]:date[length(high.pri)]) )

polygon (x,y, col=rgb(1, 0, 0,0.5),border='NA')
#lines(high.pri*cfact, col='red')
#lines(low.pri*cfact, col='red')
lines(date,med.pri*cfact, col='red', lwd=3)
#lines(high.post*cfact, col='blue')
#lines(low.post*cfact, col='blue')
lines(date, med.post*cfact, col='blue', lwd=3)
#points(OBS2PLOT, col='green', lwd=4)

#abline(v=DSTART)
#abline(v=DEND)
#print(max(med.pri) )
#print(max(med.post))





lines(date, hx_swe*cfact, col='green', lwd=3)

legend("topright", c("prior", "posterior", "open-loop") , col=c("red", "blue", "green"), lty=1)



dev.off()









