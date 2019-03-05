args = commandArgs(trailingOnly=TRUE)
file=args[1]

dat =read.csv(file)
geotopDateformat = "%d/%m/%Y %H:%M" 
myDateformat = "%Y-%m-%d %H:%M"

d=strptime(dat$datetime, myDateformat, tz=" ")
gtime=format(d, '%d/%m/%Y %H:%M')


# map Date,Tair,RH,Wd,Ws,SW,LW,Prec
Date <- gtime
Tair<- round(dat$TA -273.15, 1) # K to C
RH <- round(dat$RH, 1)
Wd <- round(dat$WD, 1)
Ws <- round(dat$WS, 1)
SW <- round(dat$SWIN, 1)
LW <- round(dat$LWIN, 1)
Prec <- round(dat$PRATE, 3)

gmet<- data.frame(Date, Tair, RH, Wd, Ws, SW, LW, Prec)
write.csv(gmet, file,row.names=FALSE, quote=FALSE)

