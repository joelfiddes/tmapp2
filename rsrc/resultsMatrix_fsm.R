#todo: 
# get nens  auto
# use resultsCube.R ??


args = commandArgs(trailingOnly=TRUE)
home = args[1]
nens = as.numeric(args[2])
FSMID = args[3]
#param=args[3] # V7 =snd V8 = SWE



# | Variable | Units  | Description       |
# |----------|--------|-------------------|
# | year     | years  | Year              |
# | month    | months | Month of the year |
# | day      | days   | Day of the month  |
# | hour     | hours  | Hour of the day   |
# | alb      | -      | Effective albedo  |
# | Rof      | kg m<sup>-2</sup> | Cumulated runoff from snow    |
# | snd      | m      | Average snow depth                       |
# | SWE      | kg m<sup>-2</sup> | Average snow water equivalent |
# | Tsf      | &deg;C | Average surface temperature              |
# | Tsl      | &deg;C | Average soil temperature at 20 cm depth  |


#===============================================================================
#			get results matrix fsm
#===============================================================================

library(raster)


rstStack_main=stack()
for (FSMID in 1:32){
#for (FSMID in 1){
	FSMID2 = formatC(FSMID-1,width=2, flag="0")
	rstStack=stack()
	for (i in 1: nens){ #python index
		resMat=c()
		idpad =formatC(i-1, width=3, flag='0')
		simpaths =list.files(paste0(home,"/ensemble/ensemble",idpad), pattern=paste0("*_",FSMID2,".txt"), full.names=T)

		for (j in simpaths){ 
			#simindex=paste0('S',formatC(j, width=5,flag='0'))
			dat = read.table(j, sep='', header=F)
			tv <- dat$V7 
			resMat = cbind(resMat,tv) # this index collapse 1 column dataframe to vector
			rst=raster(resMat)
		}
	rstStack=stack(rstStack, rst)

	}
	rstStack_main=stack(rstStack_main, rstStack)

}
ensembRes = as.array(rstStack_main)
save(ensembRes, file = paste0(home, "/ensembRes.rd"))
