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

#nens= nens*32
 
 # RUN: gridDA_FSM.R '/home/joel/sim/barandunPaper/amu_basin/sim/g1' 1000 "2013-09-01" "2014-09-01" "2013-09-01" "2014-09-01"
 # home='/home/joel/sim/barandunPaper/amu_basin/sim/g1' 
 # nens = 1000 #100#50
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
doystart=60
doyend =270
param="snow_water_equivalent.mm." # for deterministic plot
file="surface" # for determoinistic plot

# load files

landform = raster(paste0(home,"/landform.tif"))
dem = raster(paste0(home,"/predictors/ele.tif"))
lp= read.csv(paste0(home, "/listpoints.txt"))



# area of domain in km2
aod = cellStats(area(landform), sum) 

# read in basin for masking
basin=shapefile("/home/joel/sim/tmapp_val/basins/sim3/basins/basins.shp")

basin = basin[1,]


#=================================================================
# PREPARE OBS
#=================================================================

if (!file.exists(paste0(home,"/fsca_stack.tif"))){

# run this inline with main code
# 
    startY= "2014" #start of snowmelt season dd-mm
    endY = "2014"   #end snowmelt season dd-mm

    modisRepo="/home/joel/data/modis/barandun_2013/modis"
    out_wd=home # '/home/joel/sim/barandunPaper/amu_basin/sim/g2/'
    landform=raster(paste0(out_wd, "/landform.tif"))
    setwd(modisRepo)
    mypattern="Snow_Cover"
    modfiles= list.files(pattern = mypattern, recursive=T)
    mydate = c()
    rast.list <- list()
    i=1
        for (modfile in modfiles) {  
            filename= unlist(strsplit(modfile,'/'))[length(unlist(strsplit(modfile,'/')))]


            # parse date
            date=substr(unlist(strsplit(filename,'_'))[2],2,8)
            year=substr(date,1,4)    
            doy=as.numeric(substr(date,5,7) )
                dd = strptime(paste(year, doy), format = "%Y %j")


            if (year >= startY & year <=endY){
                if (doy > doystart & doy <doyend){
    print(filename)
        mydate = c(mydate, as.character(dd))
                rast.list[i] <- crop(raster(modfiles[i]),landform) 
                i=i+1
            }
        }
        }

    write.csv(mydate, paste0(out_wd, "/fsca_dates.csv"), row.names = FALSE)
    rstack=stack(rast.list)  
    writeRaster(rstack , paste0(out_wd, "/fsca_stack.tif"), overwrite=TRUE)

}

rstack = brick(paste0(home,"/fsca_stack.tif"))
obsTS = read.csv(paste0(home,"/fsca_dates.csv"))
#====================================================================
#	Load ensemble results matrix
#====================================================================
#Load ensemble results matrix (days,samples, ensemble, )

#load(paste0(home, "//ensembRes.rd"))
ensembRes = read.csv(paste0(home, "//ensembRes.csv"), header=F)

# make vector from df
v=as.vector(t(ensembRes))
# make 3d array days, samples, ensembles
ensembRes2 <- array(v, dim = c(dim(ensembRes)[2],dim(ensembRes)[1]/nens, nens))
# sequence of results
totalTS <- seq(as.Date(startSim), as.Date(endSim)-1, 1) # minus one because results from fsm are always one day shorter than defind start-endDAte
da_dates <- totalTS[which(totalTS %in% as.Date(obsTS$x))]
mod_da_dates_index <- which(totalTS %in% as.Date(obsTS$x))

ensembRes2 <- ensembRes2[mod_da_dates_index, , ]

# convert swe > sdThresh to snowcover = TRUE/1
ensembRes2[ ensembRes2 <= sdThresh ] <- 0
ensembRes2[ ensembRes2 > sdThresh ] <- 1

# compute weighted  fsca by memebership
#https://stackoverflow.com/questions/34520567/r-multiply-second-dimension-of-3d-array-by-a-vector-for-each-of-the-3rd-dimension
Vect = lp$members

# dimension that contains data first in making array, then reorder array using 'perm'
varr <- aperm(array(Vect, dim = c(dim(ensembRes2)[2], dim(ensembRes2)[1], dim(ensembRes2)[3])), perm = c(2L, 1L, 3L))
arr <- varr * ensembRes2


# compute mean MOD fSCA per sample
HX <- apply(arr, FUN = "sum", MARGIN = c(1,3)) / sum(lp$members)


#===============================================================================
#	mean obs routine based on cloud free - HIGH MEMORY USE!!!!
#===============================================================================

# memory safe implementation
print("doing memory bit")


# obs dates that exist in cut sim dates ( a sinle melt season)
obs_da_dates_index = which(as.Date(obsTS$x) %in% da_dates) 
#obs_cut = obs[obs_da_dates_index]

#agg landform to modis
lf_agg = aggregate(landform, fact=c((dim(landform)[1]/dim(rstack)[1]),(dim(landform)[2]/dim(rstack)[2])) ,methpd='ngb')
lf_resamp=resample(lf_agg, rstack[[1]])

# compute NAs in cloud free situation (due to scene border)
countNa_cloudfree <-  sum(  getValues(is.na(lf_agg))  )/ncell(lf_agg)  

# loop through obs compute mean fsca for basin area

# nNa=c()
# obs=c()
# for (myindex in obs_da_dates_index[1]){
# print(myindex)

# rcrop = crop(rstack[[myindex]], lf_resamp)
# rmask=mask(rcrop,lf_resamp)
# newobs <- cellStats(rmask, 'mean') /100    
# countNa <-  sum(  getValues(is.na(rmask))  )/ncell(rmask) 
# obs=c(obs,newobs)
# nNa = c(nNa, countNa)
# }



nNa=c()
obs=c()
for (myindex in obs_da_dates_index){
print(myindex)
rcrop = crop(rstack[[myindex]], trim(lf_resamp),  snap='out')

tryCatch(
    expr = {
        rmask =trim(rasterize(basin, rcrop, mask=TRUE) )
        newobs <- cellStats(rmask, 'mean', na.rm=T) /100  
        
    },
    error = function(e){ 
        print("All NAs found , skipping this ")

    },
    warning = function(w){
        # (Optional)
        # Do this if an warning is caught...
    },
    finally = {
        countNa <-  sum(  getValues(is.na(rmask))  )/ncell(rmask) 
        #newobs <-0
obs=c(obs,newobs)
nNa = c(nNa, countNa)
next
    }
)

# rmask <- trim(rasterize(basin, rcrop, mask=TRUE) ) # fast
# newobs <- cellStats(rmask, 'mean', na.rm=T) /100    
# countNa <-  sum(  getValues(is.na(rmask))  )/ncell(rmask) 
# obs=c(obs,newobs)
# nNa = c(nNa, countNa)
}


         #   rst1=crop(raster(predictors[p]) ,basin[i,], snap='out')
         
          #  rst <- trim(rasterize(basin[i,], rst1, mask=TRUE))  # fast


# remove percentage of scene due to border, in case of no cloud free scenes then none will be avvailbel for DA anyway as wont pass cloudthreshold test
nNa2 = nNa-min(nNa)   

# find highNA scenes and set to NA

cloudthreshold = 0.01
index = which(nNa2 > 0.1)
obs[index] <- NA

	
#===============================================================================
#		PARTICLE FILTER
#===============================================================================	
OBS<-obs
obsind = which (!is.na(obs))
#obsind <- obsind[obsind > DSTART & obsind < DEND] # defind before
naind = which (is.na(obs))	
weight = PBS(HX[obsind,], OBS[obsind], R)
	
write.csv(as.vector(weight), paste0(home,"/ensemble/weights.txt"), row.names=FALSE)
	
#===============================================================================
#		Deterministic runs
#===============================================================================	
# simpaths =list.files(paste0(home), pattern="c00*")

# for (j in simpaths){ 
# 	#simindex=paste0('S',formatC(j, width=5,flag='0'))
# 	dat = read.table(paste0(home,"/", j,"/out/",file,".txt"), sep=',', header=T)
# 	tv <- dat[param]
# 	resMat = cbind(resMat,tv[,1]) # this index collapse 1 column dataframe to vector
# 	rst=raster(resMat)
# }
resMat=c()
FSMID=1
FSMID2 = formatC(FSMID-1,width=2, flag="0")
simpaths =list.files(paste0(home,"/out/FSM/"), pattern=paste0("_",FSMID2,".txt"), full.names=T)

        for (j in simpaths){ 
            #simindex=paste0('S',formatC(j, width=5,flag='0'))
            dat = read.table(j, sep='', header=F)
            tv <- dat$V7 
            resMat = cbind(resMat,tv) # this index collapse 1 column dataframe to vector
            rst=raster(resMat)
        }


# #swe
 Vect = lp$members
 varr <- aperm(array(Vect, dim = c(dim(resMat)[2], dim(resMat)[1])), perm = c(2L, 1L))
 arr <- varr * resMat
 hx_determ_swe <- apply(arr, FUN = "sum", MARGIN = c(1)) / sum(lp$members)

# # fsca
##  convert swe > sdThresh to snowcover = TRUE/1
 resMat[ resMat <= sdThresh ] <- 0
 resMat[ resMat > sdThresh ] <- 1

 Vect = lp$members
 varr <- aperm(array(Vect, dim = c(dim(resMat)[2], dim(resMat)[1])), perm = c(2L, 1L))
 arr <- varr * resMat
 hx_determ_fsca <- apply(arr, FUN = "sum", MARGIN = c(1)) / sum(lp$members)
#===============================================================================
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
uq=0.9

#		PLOTTING fSCA
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
date=da_dates
#  xlim=c(date[182],date[355])
plot(date,high.pri, col=NULL, type='l', main=paste('(A) fSCA'), ylab="fSCA (0-1)",xlab='', ylim=c(0,1))
#lines(low.pri, col='red')
lines(date,med.pri, col='red', lwd=3)
#lines(high.post, col='blue')
#lines(low.post, col='blue')
lines(date,med.post, col='blue', lwd=3)

# posterior blue
y = c(low.post ,rev(high.post))
x=c(date,rev(date))
polygon (x,y, col=rgb(0, 0, 1,0.5),border='NA')

# prior red
y = c(low.pri ,rev(high.pri))
x=c(date,rev(date))
polygon (x,y, col=rgb(1, 0, 0,0.5),border='NA')

lines(date,med.pri, col='red', lwd=3)
#lines(high.post, col='blue')
#lines(low.post, col='blue')
lines(date,med.post, col='blue', lwd=3)
points(date,OBS2PLOT, col='black', pch=3, lwd=4)
lines(date, hx_determ_fsca[mod_da_dates_index ], col='green', lwd=3)
legend("topright", c("prior", "posterior", "obs", "open-loop") , col=c("red", "blue", "black", "green"), lty=c(1,1,NA),pch=c(NA,NA, 3))
#abline(v=DSTART)
#abline(v=DEND)
#dev.off()

abline(v=DSTART, lty=3)
abline(v=DEND, lty=3)
#====================================================================
#	# Now plot SWE (or HS)
#====================================================================



#if(mode=='hs'){load(paste0(home, "//ensembRes_HS.rd")) ; ensembRes <- ensembResHS}
#if (mode=='swe'){load(paste0(home, "//ensembRes.rd"))}

ensembRes = read.csv(paste0(home, "//ensembRes.csv"), header=F)


v=as.vector(t(ensembRes))
# make 3d array days, samples, ensembles
ensembRes2 <- array(v, dim = c(dim(ensembRes)[2],dim(ensembRes)[1]/nens, nens))

# compute weighted  fsca by memebership
#https://stackoverflow.com/questions/34520567/r-multiply-second-dimension-of-3d-array-by-a-vector-for-each-of-the-3rd-dimension
Vect = lp$members
varr <- aperm(array(Vect, dim = c(dim(ensembRes2)[2], dim(ensembRes2)[1], dim(ensembRes2)[3])), perm = c(2L, 1L, 3L))
arr <- varr * ensembRes2


# compute mean MOD swe per sample
HX2 <- apply(arr, FUN = "sum", MARGIN = c(1,3)) / sum(lp$members)


OBS2PLOT <-OBS
OBS2PLOT[naind]<-NA
prior =HX2
weight = as.vector(weight)
ndays = dim(HX2)[1]



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
date = seq(as.Date(startda), as.Date(endda)-1,by='day')
#date=da_dates
cfact=1
#,xlim=as.Date(c(date[100],date[355]))

plot(date,  high.pri*cfact, col=NULL, type='l', main=paste('(B) SWE'), ylab="Mean basin SWE (mm)" , xlab="")
#lines(low.pri*cfact, col='red')
lines(date, med.pri*cfact, col='red', lwd=3)
#lines(high.post*cfact, col='blue')
#lines(low.post*cfact, col='blue')
lines( date, med.post*cfact, col='blue', lwd=3)

# posterior blue
#y = c(low.post*cfact ,rev(high.post*cfact))

#x = c(1:length(low.post), rev(1:length(high.post)) )

y = c(low.post*cfact ,rev(high.post*cfact))
x=c((date),rev(date))

polygon (x,y, col=rgb(0, 0, 1,0.5),border='NA')

# prior red
#y = c(low.pri*cfact ,rev(high.pri*cfact))
#x = c(1:length(low.pri), rev(1:length(high.pri)) )
y = c(low.pri*cfact ,rev(high.pri*cfact))
x=c((date),rev(date))

polygon (x,y, col=rgb(1, 0, 0,0.5),border='NA')
#lines(high.pri*cfact, col='red')
#lines(low.pri*cfact, col='red')
lines(date,med.pri*cfact, col='red', lwd=3)
#lines(high.post*cfact, col='blue')
#lines(low.post*cfact, col='blue')
lines(date, med.post*cfact, col='blue', lwd=3)
#points(OBS2PLOT, col='green', lwd=4)

lines(date, hx_determ_swe*cfact, col='green', lwd=3)

legend("topright", c("prior", "posterior", "open-loop") , col=c("red", "blue", "green"), lty=1)



dev.off()



w=read.csv(paste0(home,"/ensemble/weights.txt"))
best_ensemb = which(w==max(w)) 
print(best_ensemb )
print(w$x[best_ensemb])



