# ==================================================================== SETUP
# ==================================================================== INFO
# extract timeseries of fSCA at coarse grid level
# update Nov 2019 to handle no crop of scene


# assumes MOD and MYD in separate directories (separate download jobs)
# can be multiple subdirs
# use _SNOW_COVER product (ndsi 0-100)
# no cloud filter


# WORKFLOW:

# 1. Download MODIS data from:
# https://search.earthdata.nasa.gov/projects?projectId=6513180453
# (options: geotiff/ lonlat / NDSI_SNOW_COVER)

# 2. Preprocess all data (FUN1):
# - select scene in melt season
# - convert to ndsi

# 3. Inline (FUN2):
# - subset  year
# - subset landform
# - write fsca_stack.tif
# - write fsca_dates.tif

# DEPENDENCY
require(raster)
# require(MODIStsp)

# SOURCE

# ====================================================================
# PARAMETERS/ARGS
# ====================================================================
args = commandArgs(trailingOnly = TRUE)
sca_wd="/home/joel/sim/paiku/modis"
#sink(paste0(simdir, "/modisprocess.log"), append = TRUE)

#cloudThreshold <- 100  # max cloud % to be considered 'cloudfree'

# rm modis if it exists to avoid duplicates
system (paste0('rm -r ' ,sca_wd, "/modis"))

dir.create(paste0(sca_wd,"/modis"))
setwd(sca_wd)
mypattern="Snow_Cover"

threshold=0.9
doystart=0
doyend =367

modfiles= list.files(pattern = mypattern, recursive=T)

mydatevec=c()

    for (modfile in modfiles) {

        filename= unlist(strsplit(modfile,'/'))[length(unlist(strsplit(modfile,'/')))]
        print(filename)

        # parse date
        date=substr(unlist(strsplit(filename,'_'))[2],2,8)
        year=substr(date,1,4)    
        doy=as.numeric(substr(date,5,7) )

        if (doy > doystart & doy <doyend){

            modRst=raster(modfile)

            # mask all non-snow pixels as NA
            modRst[modRst > 100] <- NA

            # count Non-snow pixels
            MOD.na <- length(which(is.na(values(modRst ))))
            
            percNa = MOD.na/ncell(modRst)
            print(percNa)
            # compute fsca
            fsca = (-0.01 + (1.45 * modRst))  # https://modis-snow-ice.gsfc.nasa.gov/uploads/C6_MODIS_Snow_User_Guide.pdf
            fsca[fsca > 100] <- 100
            fsca[fsca < 0] <- 0

            # add to index

            # write file
            writeRaster(fsca, paste0(sca_wd,"/modis/", filename  ,"_fsca.tif") ,overwrite=T)
            dd = strptime(paste(year, doy), format = "%Y %j")
            mydate = c(date, as.character(dd))
            mydatevec=c(mydatevec,mydate)
        }else{print('Scene outside of meltseason')}
    

print(paste(which(modfiles==modfile), "/", length(modfiles),"complete!"))

}

# run this inline with main code
# 
# startY= "2013" #start of snowmelt season dd-mm
# endY = "2014"   #end snowmelt season dd-mm
# modisRepo = "/home/joel/data/modis/barandun_paper/modis"
# modisRepo="/home/joel/Downloads/5000000430207/modis"
# out_wd='/home/joel/sim/barandunPaper/amu_basin/sim/g2/'
# landform=raster(paste0(out_wd, "/landform.tif"))
# setwd(modisRepo)
# mypattern="Snow_Cover"
# modfiles= list.files(pattern = mypattern, recursive=T)
# mydate = c()
# rast.list <- list()
# i=1
#     for (modfile in modfiles) {  
#         filename= unlist(strsplit(modfile,'/'))[length(unlist(strsplit(modfile,'/')))]


#         # parse date
#         date=substr(unlist(strsplit(filename,'_'))[2],2,8)
#         year=substr(date,1,4)    
#         doy=as.numeric(substr(date,5,7) )
#             dd = strptime(paste(year, doy), format = "%Y %j")


#         if (year >= startY & year <=endY){
# print(filename)
#     mydate = c(mydate, as.character(dd))
#             rast.list[i] <- crop(raster(modfiles[i]),landform) 
#             i=i+1
#         }
#     }

# write.csv(mydate, paste0(out_wd, "/fsca_dates.csv"), row.names = FALSE)
# rstack=stack(rast.list)  
# writeRaster(rstack , paste0(out_wd, "/fsca_stack.tif"), overwrite=TRUE)

















