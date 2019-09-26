wd="/home/joel/data/tscale3DIMIS_results/out/"
dir.create(paste0(wd,"/processed"))
strReverse <- function(x)
        sapply(lapply(strsplit(x, NULL), rev), paste, collapse = "")

fullfiles=list.files(wd, full.names=T)
files = list.files(wd)
dates = strReverse(substr(strReverse(files),1,14))
ids = strReverse(substr(strReverse(files),15,nchar(files)))

ids2process= unique(ids)

for (i in 1:length(ids2process)){

fileIndex = which(ids == ids2process[i])

myfiles = fullfiles[fileIndex]

df=c()
for( j in myfiles){
dat = read.csv(j)
df=rbind(df,dat)
}
write.csv(df, paste0(wd,"/processed/",ids2process[i],".csv" ), row.names=F, quote=F)
}
