
args <- 	commandArgs(trailingOnly=TRUE)
wd <- args[1]
nens <-as.numeric(args[2])



# FIXED
openloop = read.table(paste0(wd, "/openloopMean.csv"))
openloop=openloop$V1
HX <- as.matrix(read.table(paste0(wd, "/ensemble/HX")))
obs <- read.table(paste0(wd, "/ensemble/obs"))
obs=obs$V1
fsca= read.csv(paste0(wd, "/meanSCA.csv"))
fsca_dates = read.csv(paste0(wd,"/fsca_dates.csv"))
fsca = fsca$meanvec
weight = read.csv(paste0(wd, "/ensemble/weights.txt"), header=F)
weight = weight$V2
ndays = length(obs)
lq=0.3
uq=0.85

# code
png(paste0(wd,"/ensemble/daplot.png"), width=800, height=400)
par(mfrow=c(1,2))

# median
med.post = c()
for ( days in 1:ndays){
print(days)
mu = HX[ days, ]
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

mu = HX[ days, ]
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

mu = HX[ days, ]
w = weight
wfill <- weight

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=uq, rule=2)
high.post = c(high.post, med$y)
}



# ======================= HX = ==========================================

# median
med.pri = c()
for ( days in 1: ndays){

mu = HX[ days, ]
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

mu = HX[ days, ]
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

mu = HX[ days, ]
w = rep((1/nens),nens)
wfill <- w

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=uq)
high.pri = c(high.pri, med$y)
}


#date = seq(as.Date(startda), as.Date(endda),by='day')
date=1:length(obs)

#  xlim=c(date[182],date[355])
plot(date,high.pri, col=NULL, type='l', main=paste('(A) fSCA'), ylab="fSCA (0-1)",xlab='', ylim=c(0,0.2))
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
points(date,obs, col='black', pch=3, lwd=4)
#lines(date, hx_determ_fsca[mod_da_dates_index ], col='green', lwd=3)
legend("topright", c("prior", "posterior", "obs", "open-loop") , col=c("red", "blue", "black", "green"), lty=c(1,1,NA),pch=c(NA,NA, 3))
#abline(v=DSTART)
#abline(v=DEND)
#dev.off()

#abline(v=date[DSTART], lty=3)
#abline(v=date[DEND], lty=3)
#====================================================================
#   # Now plot SWE (or HS)
#====================================================================



#if(mode=='hs'){load(paste0(home, "//ensembRes_HS.rd")) ; ensembRes <- ensembResHS}
#if (mode=='swe'){load(paste0(home, "//ensembRes.rd"))}




# compute mean MOD swe per sample
HX2 <- as.matrix(read.table(paste0(wd, "/ensemble/HX_swe")))


#OBS2PLOT <-OBS
#OBS2PLOT[naind]<-NA
prior =HX2





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

#if(mode=='swe'){cfact = aod/1000000}
#if (mode=="hs"){cfact=1}
cfact=1 # FIXED

# ADD DATE
#date = seq(as.Date(obsTS$x[1]), as.Date(obsTS$x[250]),by='day')
date=1:length(obs)

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

lines(date, openloop, col='green', lwd=3)

legend("topright", c("prior", "posterior", "open-loop") , col=c("red", "blue", "green"), lty=1)


dev.off()
















































