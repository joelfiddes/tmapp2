# generate output results
args = commandArgs(trailingOnly=TRUE)
home = args[1]
nens = as.numeric(args[2])
file=args[3] # "surface" or "ground"
param=args[4]
day = as.numeric(args[5]) # 212 = March 31 on non leap year

require(raster)



# rstStack_main=stack()
# for (FSMID in 1:32){
# #for (FSMID in 1){
# 	FSMID2 = formatC(FSMID-1,width=2, flag="0")
# 	rstStack=stack()
# 	for (i in 1: nens){ #python index
# 		resMat=c()
# 		idpad =formatC(i-1, width=3, flag='0')
# 		simpaths =list.files(paste0(home,"/ensemble/ensemble",idpad), pattern=paste0("*_",FSMID2,".txt"), full.names=T)

# 		for (j in simpaths){ 
# 			#simindex=paste0('S',formatC(j, width=5,flag='0'))
# 			dat = read.table(j, sep='', header=F)
# 			tv <- dat$V7 
# 			resMat = cbind(resMat,tv) # this index collapse 1 column dataframe to vector
# 			rst=raster(resMat)
# 		}
# 	rstStack=stack(rstStack, rst)

# 	}
# 	rstStack_main=stack(rstStack_main, rstStack)

# }
# ensembRes = as.array(rstStack_main)




ensembRes = read.csv(paste0(home, "//ensembRes.csv"), header=F)
v=as.vector(t(ensembRes))
# make 3d array days, samples, ensembles
ensembRes2 <- array(v, dim = c(dim(ensembRes)[2],dim(ensembRes)[1]/nens, nens))


# weights file
w= read.csv(paste0(home,"/ensemble/weights.txt"))
varr <- aperm(array(w$x, dim = c(dim(ensembRes2)[3], dim(ensembRes2)[1], dim(ensembRes2)[2])), perm = c(2L, 3L, 1L))


x= ensembRes2*varr
y=apply(x, MARGIN=c(1,2), FUN=sum)
lf=raster(paste0(home,"/landform.tif"))

# day 212 = 31 March on a non leap year
l2 =data.frame(cbind((1:dim(ensembRes2)[2]), y[day,] ))

rst = subs(lf,l2 ,by=1, which=2)
writeRaster(rst, paste0(home, "/",param,"_da.tif"))