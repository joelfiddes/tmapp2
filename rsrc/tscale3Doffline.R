# Prepares a tscale3Ddir
# then run slurm_tscale.sh  in tscalev2/toposcale

# aggregates listpoiunts from all nodes generates megaListpoints - 
# runs tscale3D splitting by year on cluster (this is most efficient) 
# and then distributes results back to nodes with suitable name change

# !!!Make sure only to merge listpoint in main home and not also sim listpoint else points are double!!!




wd="~/sim/ch_hres_3h_long"
simdir="~/sim/tscalOffline/"
dir.create(simdir)

cmd =paste("cp -r", paste0(wd,"/forcing"), simdir)
system(cmd)

cmd=paste0("find ",wd, " -maxdepth 3 -name listpoints.txt") #"> mylistpoints.txt")
filenames<-system(cmd, intern=T)



#filenames = list.files(path = wd, pattern="listpoints.txt", full.names = TRUE, recursive=T)


multMerge = function(filenames){
  datalist = lapply(filenames, 
                    function(x){read.csv(file = x,
                                         header = TRUE,
                                         stringsAsFactors = FALSE)})
  Reduce(function(x,y) {merge(x, y, all = TRUE)}, datalist)
}

megaListpoints = multMerge(filenames)
write.csv(megaListpoints, paste0(simdir,"listpoints.txt"))

# use something like this to limit serach depth system("find . -maxdepth 1 -type d -exec ls -ld "{}" \;")