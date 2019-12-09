
for (sampid in 1:100){
samp = formatC(sampid,width=3, flag="0")
samp="059"
fsmout=paste0('/home/joel/sim/barandunPaper/amu_grid/sim/g466/out/FSM/fsm',samp,'.txt_00.txt')
fsm = read.csv(fsmout, header=F,sep='')



#mycol=cols[i]
fsm_swe=c(fsm$V7)#swe
fsm_hs=c(fsm$V6)#swe
fsm_dates=as.Date(paste(fsm$V1,fsm$V2,fsm$V3 ,sep='-'))

plot(fsm_dates, fsm_swe, typ='l')
Sys.sleep(2)
}

for (FSMID in 0:31){
print(FSMID)
FSMID2 = formatC(FSMID,width=2, flag="0")
fsmout=paste0('/home/joel/sim/barandunPaper/amu_grid/sim/g466/out/FSM/fsm059.txt_',FSMID2,'.txt')
fsm = read.csv(fsmout, header=F,sep='')



#mycol=cols[i]
fsm_swe=c(fsm$V7)#swe
fsm_hs=c(fsm$V6)#swe
fsm_dates=as.Date(paste(fsm$V1,fsm$V2,fsm$V3 ,sep='-'))

lines(fsm_dates, fsm_swe, col='green')
}