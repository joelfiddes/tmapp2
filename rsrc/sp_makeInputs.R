source("./rsrc/gt_control.R")

# variables
#in_ini = "/home/joel/src/tmapp2/snowpack/mio.ini"
#meteopath = '/home/joel/sim/tmapp_sp/sim/g1/forcing/'
#station1 = 'meteoc2.csv'

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
sp_master=args[1]
meteopath=args[2] #"/home/joel/sim/topomap_test/grid1" #
station1=args[3]
startDate=args[4]
lpname=args[5]

in_ini=paste0(sp_master,"/snowpack.ini")
in_sno = paste0(sp_master,"/snowpack.sno")
basename=unlist(strsplit(station1, "[.]"))[1]
CSV_NAME=basename
CSV_ID= basename
out_ini = paste0(meteopath, basename, ".ini")
out_sno = paste0(meteopath, basename, ".sno")
#system(paste0("cp ",baseINI, out_ini))


# make INI file
fs=readLines(in_ini) 

#datetime
mpath=gt.par.fline(fs=fs, keyword="METEOPATH") 
s1=gt.par.fline(fs=fs, keyword="STATION1") 
csvn=gt.par.fline(fs=fs, keyword="CSV_NAME") 
csvi=gt.par.fline(fs=fs, keyword="CSV_ID") 
sp=gt.par.fline(fs=fs, keyword="SNOWPATH") 
exp=gt.par.fline(fs=fs, keyword="EXPERIMENT") 

fs=gt.par.wline(fs=fs,ln=mpath,vs=meteopath)
fs=gt.par.wline(fs=fs,ln=s1,vs=station1)
fs=gt.par.wline(fs=fs,ln=csvn,vs=CSV_NAME)
fs=gt.par.wline(fs=fs,ln=csvi,vs=CSV_ID)
fs=gt.par.wline(fs=fs,ln=sp,vs=meteopath)
fs=gt.par.wline(fs=fs,ln=exp,vs=lpname)

con <- file(out_ini, "w")  # open an output file connection
cat(fs, file = con,sep="\n")
close(con)

# make sno file

fs=readLines(in_sno) 

mpath=gt.par.fline(fs=fs, keyword="station_id ") 
s1=gt.par.fline(fs=fs, keyword="station_name") 
pdate=gt.par.fline(fs=fs, keyword="ProfileDate") 
fs=gt.par.wline(fs=fs,ln=mpath,vs=CSV_NAME)
fs=gt.par.wline(fs=fs,ln=s1,vs=CSV_ID)
fs=gt.par.wline(fs=fs,ln=pdate,vs=startDate)

con <- file(out_sno, "w")  # open an output file connection
cat(fs, file = con,sep="\n")
close(con)

