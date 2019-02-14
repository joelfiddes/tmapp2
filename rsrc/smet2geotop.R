require(RSMET)
skip = 12
geotop = TRUE
file = "WFJ_optimaldataset_v7.smet"
#tz=as.numeric(mysmet@header$tz)*-1
tz="CET"
timestep = 0.5


mysmet = smet(file)
fields = mysmet@header$fields
dat = read.csv(file, skip=skip, sep=' ',header=FALSE)
names(dat) <- fields
smetDateformat = "%Y-%m-%dT%H:%M"
geotopDateformat = "%d/%m/%Y %H:%M" 
myDateformat = "%Y-%m-%d %H:%M"

d=strptime(dat$timestamp, smetDateformat, tz=tz)# append CET/CEST but does not shift dates which is good!

geotoptime=format(d, '%d/%m/%Y %H:%M')

# map Date,Tair,RH,Wd,Ws,SW,LW,Prec
Date <- geotoptime
Tair<- dat$TA -273.15 # K to C
RH <- dat$RH*100
Wd <- dat$DW
Ws <- dat$VW
SW <- dat$ISWR
LW <- dat$ILWR
Prec <- dat$PSUM/timestep # convert psum to mm/hr

geotop_met <- data.frame(Date, Tair, RH, Wd, Ws, SW, LW, Prec)
write.csv(geotop_met, "meteo0001.txt",row.names=FALSE, quote=FALSE)

