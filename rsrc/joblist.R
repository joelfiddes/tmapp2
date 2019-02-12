args = commandArgs(trailingOnly=TRUE)
# setup joblist for cluster runs
wd=args[1]

jobs = list.files(paste0(wd,"/sim/") )
batchfile=paste('joblist.txt',sep='')
file.create(batchfile)
write('#!/bin/bash',file=batchfile,append=T)

for (job in jobs){
write(paste("python tmapp_run.py", wd, job, "&"), file=batchfile,append=T)
}

# permissions
system(paste('chmod 777 ','joblist.txt',sep=''))
