#todo: 
# get nens  auto
# use resultsCube.R ??


args = commandArgs(trailingOnly=TRUE)
home = args[1]
nens = as.numeric(args[2])
file=args[3] # "surface" or "ground"
param=args[4]

#===============================================================================
#			get results matrix
#===============================================================================
library(raster)

rstStack=stack()
for (i in 1: nens){ #python index
	resMat=c()
	simpaths =list.files(paste0(home,"/ensemble/ensemble",i-1), pattern="c0*")

	for (j in simpaths){ 
		#simindex=paste0('S',formatC(j, width=5,flag='0'))
		dat = read.table(paste0(home,"/ensemble/ensemble",i-1,"/", j,"/out/",file,".txt"), sep=',', header=T)
		tv <- dat[param]
		resMat = cbind(resMat,tv[,1]) # this index collapse 1 column dataframe to vector
		rst=raster(resMat)
	}
rstStack=stack(rstStack, rst)
ensembRes = as.array(rstStack)
}
save(ensembRes, file = paste0(home, "/ensembRes.rd"))
#keep ensembRes swe
# ensembRes_swe <- ensembRes

# # compute sca results
# ensembRes[ensembRes<=sdThresh]<-0
# ensembRes[ensembRes>sdThresh]<-1