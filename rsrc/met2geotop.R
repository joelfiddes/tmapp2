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
RH <- round(dat$RH*100, 1) # smet 0-1 to geotop 0-100
RH[RH < 0] <- 0
RH[RH>100] <-100

Wd <- round(dat$DW, 1)
Ws <- round(dat$VW, 1)
SW <- round(dat$ISWR, 1)
LW <- round(dat$ILWR, 1)
Prec <- round(dat$PINT, 3)

gmet<- data.frame(Date, Tair, RH, Wd, Ws, SW, LW, Prec)
write.csv(gmet, paste0(file,".gtp"),row.names=FALSE, quote=FALSE)

