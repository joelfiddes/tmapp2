require(GSODR) #https://docs.ropensci.org/GSODR/reference/get_GSOD.html
wd="/home/joel/sim/barandunPaper/"
YEARS=1979:2018
country="TJ"
eleFilter=2000
# latest inventory
inventory <- get_inventory()
gsod <- get_GSOD(years = 2014, country=country) # only works for single years
stat=unique(gsod$NAME[which(gsod$ELEVATION>eleFilter)])
ele=unique(gsod$ELEVATION[which(gsod$ELEVATION>eleFilter)])
STNID = unique(gsod$STNID[which(gsod$ELEVATION>eleFilter)])
s =shapefile("/home/joel/sim/barandunPaper/sim/spatial/TJ1981over2000.shp")

gdir=3




# DOWNLOADED  VERSION

par(mfrow=c(5,5))

gsodDate=list()
gsodSnow=list()
gsodTA=list()

for (gdir in c(1:11)){
print(gdir)
gsod <- get_GSOD(years = YEARS, station=STNID[gdir])
	gsod_snow=gsod$SNDP#[gsod$NAME==stat[i]]
	#if(length(is.na(T)[is.na(T)==TRUE])==length(T)){print("skip");next}

	gsod_dates=gsod$YEARMODA


inDir=paste0("/home/joel/sim/barandunPaper/sim/sim/g",gdir,"/out/FSM/")
fsm = read.csv(paste0(inDir,"/meteoc1.csv",13,"out.txt"), header=F,sep='')



	#mycol=cols[i]
	fsm_hs=c(fsm$V6)
	fsm_dates=as.Date(paste(fsm$V1,fsm$V2,fsm$V3 ,sep='-'))
	#plot(fsm_dates,fsm_hs*100, col="green",lwd=1)
start="1979-11-01"
end="2018-08-31"
# cut gsod to fsm length
#start_gsod = which(gsod_dates==start)
#end_gsod = which(gsod_dates==end)

start_fsm = which(fsm_dates==start)
end_fsm = which(fsm_dates==end)
scalefact=100

plot(fsm_dates[start_fsm:end_fsm],fsm_hs[start_fsm:end_fsm]*scalefact, col="green",lwd=3, type='l', main=paste(stat[gdir] ,ele[gdir]), ylim=c(0,max(gsod_snow/10, na.rm=T)))

# plot(dates,fsm_hs, col='red', lwd=3, lty=lty, type='l', ylim=c(0,200), main="Snow height HY2014", ylab="HS [cm]", xlab='DOY')
# lines(dates,obs$HS, col='black', lwd=3, lty=lty)
# lines(dates,gt_hs/10 ,col='blue', lwd=3, lty=lty)
for (i in 1:32){
	
	fsm = read.csv(paste0(inDir,"/meteoc1.csv",i-1,"out.txt"), header=F,sep='')
	fsm_hs=c(fsm$V6)
	lines(fsm_dates[start_fsm:end_fsm],fsm_hs[start_fsm:end_fsm]*scalefact, col="green",lwd=1)
	#if(i==14){lines(fsm_dates[start_fsm:end_fsm],fsm_hs[start_fsm:end_fsm]*factor, col="orange",lwd=4)}
}


lines(gsod_dates,gsod_snow/10, col="black",lwd=3, type='l', main=stat[gdir])


#mete
met=read.csv(paste0("/home/joel/sim/barandunPaper/sim/sim/g",gdir,"/forcing/meteoc1.csv"))
date = substr(met$datetime,1,10)
TAMEAN = aggregate(met$TA, list(date), mean, na.rm=T)
fsm_ta =TAMEAN$x-273.15 

mydates = as.Date(unique(date))   

gsod_ta= gsod$TEMP

#plot(mydates ,TAMEAN$x-273.15 , type='l', col='red' )
#lines(gsod_dates, TAgsod)

s = (mydates%in%gsod_dates)
d =(gsod_dates%in%mydates)
plot(fsm_ta[s] , gsod_ta[d], ylim=c(min(gsod_ta[d], na.rm=T), max(gsod_ta[d], na.rm=T)), xlim=c( min(gsod_ta[d], na.rm=T), max(gsod_ta[d],na.rm=T) ) ) 
abline(0,1)


gsodDate[[gdir]]<-gsod_dates
gsodSnow[[gdir]]<-gsod_snow
gsodTA[[gdir]]<-gsod_ta





}

#save(gsodDate, file = paste0(wd,"/gsodDate"))
#save(gsodSnow, file = paste0(wd, "/gsodSnow"))
save(gsodTA, file = paste0(wd, "/gsodTA"))



# LOADED FROM FILE VERSION

par(mfrow=c(4,3))

load(paste0(wd,"/gsodDate"))
load(paste0(wd, "/gsodSnow"))
load(paste0(wd, "/gsodTA"))
for (gdir in c(1:11)){
print(gdir)

	
	gsod_snow=gsodSnow[[gdir]]
	gsod_dates=gsodDate[[gdir]]
	gsod_ta=gsodTA[[gdir]]

if (stat[gdir]%in% c("MADRUSHKAT" ,"KARAKUL" ,   "MURGAB",     "ISHKASHIM" )){
	gsod_snow[gsod_snow>500]<-NA
	}



inDir=paste0("/home/joel/sim/barandunPaper/sim/sim/g",gdir,"/out/FSM/")
fsm = read.csv(paste0(inDir,"/meteoc1.csv",13,"out.txt"), header=F,sep='')



	#mycol=cols[i]
	fsm_hs=c(fsm$V6)
	fsm_dates=as.Date(paste(fsm$V1,fsm$V2,fsm$V3 ,sep='-'))
	#plot(fsm_dates,fsm_hs*100, col="green",lwd=1)
start="1979-11-01"
end="2018-08-31"
# cut gsod to fsm length
#start_gsod = which(gsod_dates==start)
#end_gsod = which(gsod_dates==end)

start_fsm = which(fsm_dates==start)
end_fsm = which(fsm_dates==end)
scalefact=100

plot(fsm_dates[start_fsm:end_fsm],fsm_hs[start_fsm:end_fsm]*scalefact, col="green",lwd=3, type='l', main=paste(stat[gdir] ,ele[gdir]), ylim=c(0,max(gsod_snow/10, na.rm=T)))

# plot(dates,fsm_hs, col='red', lwd=3, lty=lty, type='l', ylim=c(0,200), main="Snow height HY2014", ylab="HS [cm]", xlab='DOY')
# lines(dates,obs$HS, col='black', lwd=3, lty=lty)
# lines(dates,gt_hs/10 ,col='blue', lwd=3, lty=lty)
for (i in 1:32){
	
	fsm = read.csv(paste0(inDir,"/meteoc1.csv",i-1,"out.txt"), header=F,sep='')
	fsm_hs=c(fsm$V6)
	lines(fsm_dates[start_fsm:end_fsm],fsm_hs[start_fsm:end_fsm]*scalefact, col="green",lwd=1)
	#if(i==14){lines(fsm_dates[start_fsm:end_fsm],fsm_hs[start_fsm:end_fsm]*factor, col="orange",lwd=4)}
}


lines(gsod_dates,gsod_snow/10, col="black",lwd=3, type='l', main=stat[gdir])

#scatter
s = (fsm_dates%in%gsod_dates)
d =(gsod_dates%in%fsm_dates)
#plot(fsm_hs[s]*scalefact, gsod_snow[d]/10, ylim=c(0, max(gsod_snow[d]/10, na.rm=T)), xlim=c(0, max(gsod_snow[d]/10,na.rm=T) ) ) 
#abline(0,1)


#mete
met=read.csv(paste0("/home/joel/sim/barandunPaper/sim/sim/g",gdir,"/forcing/meteoc1.csv"))
date = substr(met$datetime,1,10)
TAMEAN = aggregate(met$TA, list(date), mean, na.rm=T)
gsod_ta =TAMEAN$x-273.15 

mydates = as.Date(unique(date))   

TAgsod = gsod$TEMP
s = (mydates%in%gsod_dates)
d =(gsod_dates%in%mydates)
plot(gsod_ta[s] , TAgsod[d], ylim=c(min(TAgsod[d], na.rm=T), max(TAgsod[d], na.rm=T)), xlim=c( min(TAgsod[d], na.rm=T), max(TAgsod[d],na.rm=T) ) ) 
abline(0,1)


}







~

par(mfrow=c(4,3))

for (i in c(1:3,5:7)){

gdir=i


inDir=paste0("/home/joel/sim/barandunPaper/sim/sim/g",gdir,"/out/FSM/")
fsm = read.csv(paste0(inDir,"/meteoc1.csv",13,"out.txt"), header=F,sep='')

	#mycol=cols[i]
	fsm_hs=c(fsm$V6)
	fsm_dates=as.Date(paste(fsm$V1,fsm$V2,fsm$V3 ,sep='-'))
	plot(fsm_dates,fsm_hs*100, col="green",lwd=1, main = stat[i])
}