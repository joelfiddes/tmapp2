#====================================================================
# SETUP
#====================================================================
#INFO
# remove these scaling parameters?

#DEPENDENCY
require(raster)

#SOURCE



#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
simdir=args[1] #'/home/joel/sim/topomap_test/grid1' #

#====================================================================
# Horizon functiom
#====================================================================

	hor<-function(listPath){
	#reads listpoints at 'listPath' - writes hor dir and files to listPath

		listpoints<-read.table(paste(listPath,'/listpoints.txt', sep=''), header=T, sep=',')
		ID=listpoints$id
		ID<-formatC(ID,width=4,flag="0")
		
		slp=listpoints$slp
		svf=listpoints$svf
		
		(((acos(sqrt(svf))*180)/pi)*2)-slp ->hor.el
		round(hor.el,2)->>hor.el
		dir.create(paste(listPath,'/hor',sep=''), showWarnings = TRUE, recursive = FALSE)
		n<-1 #initialise ID sequence
		for (hor in hor.el){
			IDn<-ID[n]
			Angle=c(45,135,225,315)
			
			Height=rep(round(hor,2),4)
			
			hor=data.frame(Angle, Height)
			write.table(hor, paste(listPath,'/hor/hor_point',IDn,'.txt',sep=''),sep=',', row.names=FALSE, quote=FALSE)
			
			n<-n+1
		}}

#===========================================================================
#				POINTS
#===========================================================================
mf=read.csv(paste0(simdir,'/listpoints.txt'))
npoints=dim(mf)[1]

	for(i in 1:npoints)
	{
		#create directories for sims
		simindex=paste0(simdir,'/c',formatC(i, width=5,flag='0'))
		dir.create(simindex, recursive=TRUE)
		dir.create(paste0(simindex,'/out'), recursive=TRUE)
		dir.create(paste0(simindex,'/rec'), recursive=TRUE)

		met = read.csv(paste0(simdir,"/forcing/meteoc",i,".csv.gtp"))
		write.table(met, paste(simindex,'/meteo0001.txt', sep=''), sep=',', row.names=F, quote=FALSE)

		listp=mf[i,]

		# round while excluding string column name
		listp=round(mf[,which(names(mf)!='name')],5)
		
		# readd name
		listp$name<-mf$name
		#names(listp)<-c('id', 'ele', 'asp', 'slp', 'svf')
		write.table(listp[i,], paste0(simindex, '/listpoints.txt', sep=''), sep=',',row.names=F)

		hor(listPath=simindex)
		}


	
