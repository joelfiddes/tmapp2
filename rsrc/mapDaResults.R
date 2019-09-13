# generate output results
args = commandArgs(trailingOnly=TRUE)
home = args[1]
nens = as.numeric(args[2])
file=args[3] # "surface" or "ground"
param=args[4]
day = as.numeric(args[5]) # 212 = March 31 on non leap year

require(raster)
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

# weights file
w= read.csv(paste0(home,"/ensemble/weights.txt"))

varr <- aperm(array(w$x, dim = c(dim(ensembRes)[3], dim(ensembRes)[1], dim(ensembRes)[2])), perm = c(2L, 3L, 1L))


x= ensembRes*varr
y=apply(x, MARGIN=c(1,2), FUN=sum)
lf=raster(paste0(home,"/landform.tif"))

# day 212 = 31 March on a non leap year
l2 =data.frame(cbind((1:dim(ensembRes)[2]), y[day,] ))

rst = subs(lf,l2 ,by=1, which=2)
writeRaster(rst, paste0(home, param,"_da.tif"))