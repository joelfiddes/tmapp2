source("./rsrc/PBS.R") 

wd = "/home/caduff/sim/ch_tmapp_50"
startSim <-   "1979-08-01" 
endSim <-   "2019-09-30"

# fixed
nens=8
sdThresh=13
R=0.016
lp= read.csv(paste0(wd, "/listpoints.txt"))
fsca= read.csv(paste0(wd, "/meanSCA.csv"))
obsTS = read.csv(paste0(wd,"/fsca_dates.csv"))
fsca_dates= read.csv(paste0(wd, "/listpoints.txt"))
ensembRes = read.csv(paste0(wd, "/ensembRes.csv"), header=F)
fsca = fsca$meanvec

# make vector from df
v=as.vector(t(ensembRes))
# make 3d array days, samples, ensembles
ensembRes2 <- array(v, dim = c(dim(ensembRes)[2],dim(ensembRes)[1]/nens, nens))

# sequence of results
totalTS <- seq(as.Date(startSim), as.Date(endSim), 1) # minus one because results from fsm are always one day shorter than defind start-endDAte
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

# compute mean MOD fSCA per sample. HX is now T x Ens
HX <- apply(arr, FUN = "sum", MARGIN = c(1,3)) / sum(lp$members)


obs=fsca[1:250]/100
sim=HX[1:250,]
weight = PBS(sim, obs, R)
#weight = PBS(HX[(DSTART:DEND)[obsind],], OBS[obsind], R)
write.csv(as.vector(weight), paste0(wd,"/ensemble/weights.txt"), row.names=FALSE)
write.csv(HX, paste0(wd,"/ensemble/HX.txt"), row.names=FALSE)

write.csv(as.vector(weight), paste0(home,"/ensemble/weights.txt"), row.names=FALSE)


OBS2PLOT <-obs
#OBS2PLOT[naind]<-NA
prior =sim

weight = as.vector(weight)
ndays = 1:250
lq=0.3
uq=0.85


png(paste0(home,"/ensemble/daplot.png"), width=800, height=400)
par(mfrow=c(1,2))

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
high.pri<-high.pri
med.pri<-med.pri
low.pri<-low.pri
high.post<-high.post
med.post<-med.post
low.post<-low.post
#  xlim=c(date[182],date[355])
plot(date,high.pri, col=NULL, type='l', main=paste('(A) fSCA'), ylab="fSCA (0-1)",xlab='', ylim=c(0,1))
#lines(low.pri, col='red')
lines(date,med.pri ,col='red', lwd=3)
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

abline(v=date[DSTART], lty=3)
abline(v=date[DEND], lty=3)
#====================================================================
#   # Now plot SWE (or HS)
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


#OBS2PLOT <-OBS
#OBS2PLOT[naind]<-NA
prior =HX2[1:250]
weight = as.vector(weight)
ndays = dim(HX2)[1]



# ======================= posterior = ==========================================
#png(paste0(home,"/ensemble/daplot_",gridname,".png"), width=800, height=400)
#par(mfrow=c(1,2))

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
cfact=1 # FIXED

# ADD DATE
date = seq(as.Date(obsTS$x[1]), as.Date(obsTS$x[250]),by='day')
#date=da_dates

#,xlim=as.Date(c(date[100],date[355]))
ymax = max(c(max(high.post), max(high.pri)))
plot(date,  high.pri*cfact, col=NULL, type='l', main=paste('(B) SWE'), ylab="Mean basin SWE (mm)" , xlab="", ylim=c(0,ymax))
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

#lines(date, hx_determ_swe*cfact, col='green', lwd=3)

legend("topright", c("prior", "posterior", "open-loop") , col=c("red", "blue", "green"), lty=1)


dev.off()
















































