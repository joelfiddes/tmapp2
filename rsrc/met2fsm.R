args = commandArgs(trailingOnly=TRUE)
file=args[1]


# FSM converter
# spec here: https://github.com/RichardEssery/FSM
# Variable	Units	Description
# year	years	Year
# month	months	Month of the year
# day	days	Day of the month
# hour	hours	Hour of the day
# SW	W m-2	Incoming shortwave radiation
# LW	W m-2	Incoming longwave radiation
# Sf	kg m-2 s-1	Snowfall rate
# Rf	kg m-2 s-1	Rainfall rate
# Ta	K	Air temperature
# RH	RH	Relative humidity
# Ua	m s-1	Wind speed
# Ps	Pa	Surface air pressure


dat =read.csv(file)
myDateformat = "%Y-%m-%d %H:%M"
d=strptime(dat$datetime, myDateformat, tz=" ")
year = format(d, format="%Y")
month = format(d, format="%m")
day = format(d, format="%d")
hour = format(d, format="%H")


SW <- round(dat$ISWR, 1)
LW <- round(dat$ILWR, 1)
Sf<- round(dat$Sf, 1)/(60*60) # prate in mm/hr to kgm2/s
Rf<- round(dat$Rf, 1)/(60*60) # prate in mm/hr to kgm2/s
TA<- round(dat$TA, 1)
RH <- round(dat$RH*100, 1) # smet 0-1 to geotop 0-100
RH[RH < 0] <- 0
RH[RH>100] <-100
Ua <- round(dat$VW, 1)
Ps<- round(dat$P, 1)
#Prec <- round(dat$PINT, 3)

fmet<- data.frame(year,month,day, hour, SW, LW, Sf, Rf, TA, RH, Ua, Ps)
write.table(fmet, paste0(file,"_fsm.txt"),row.names=FALSE, quote=FALSE, col.names=FALSE, sep='\t')
