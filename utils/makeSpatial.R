# set parameters directli script the call as:
# Rscript makeSpatial.R

wd = "/home/caduff/sim/paiku/"
Ngrids = 25
Nclust = 100
script ="now" # "mean"
targV = "snow_water_equivalent.mm." #"X100.0000.txt"
# set these if script = "now"
date = "'31/05/2014 00:00'"
# set these if script = "mean"
beg =  "'31/09/2009 00:00'"
end = "'31/09/2014 00:00'"

for (i in 1:Ngrids){
print (i)
	if (script=="now"){
	home=paste0(wd,"sim/g",i)
	system( paste("Rscript","./rsrc/toposubSpatialNow.R", home, Nclust, targV, date ))
	}

	if (script=="mean"){
	gridpath=paste0(wd,"sim/g",i)
	system( paste("Rscript","./rsrc/toposub_spatial_mean.R", gridpath, Nclust, targV, beg, end ))
	}
}

