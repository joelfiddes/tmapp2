#!/usr/bin/env python
import os
import subprocess
import pandas as pd
import sys
from configobj import ConfigObj
import glob
import numpy as np



# tmapp_darun
# approx 38 s for 100 samples and 32 model types (320 sims) for 1 sim year


def main(wd, ensembleN, daYear):
	daYear=int(daYear)

	config = ConfigObj(wd+"/config.ini")
	ensemb_root = wd+"/ensemble"

	# pad to 3 digits for sorting ease
	i=int(ensembleN)# this is 1-100

	ipad=	'%03d' % (i,)

	# make new dierectory if does not exist
	ensemb_dir = ensemb_root + "/ensemble" + str(ipad) + "/"
	if not os.path.isdir(ensemb_dir):
		cmd = "mkdir  %s"%(ensemb_dir)
		os.system(cmd)


	# read in csv as pd data
	df = pd.read_csv(ensemb_root+"/ensemble.csv")


	# python 0-99 index
	pbias = df['pbias'][i-1]
	tbias = df['tbias'][i-1]
	lwbias = df['lwbias'][i-1]
	swbias = df['swbias'][i-1]


	# config["main"]["wd"]  = ensemb_root + "/ensemble" + str(ipad) + "/"
	# config["da"]["pscale"] = pbias #factor to multiply precip by
	# config["da"]["tscale"] = tbias #factor to add to temp
	# config["da"]["swscale"] = swbias
	# config["da"]["lwscale"] = lwbias

	# config.write()

	# copy sim dirs only THIS doesnt scale as we 30GB data *100 workers! Do 1 by 1
	# src = wd+"/out/tscale*.csv"
	# ensemb_dir = config['main']['wd']
	# cmd = "cp -r  %s %s"%(src,ensemb_dir)
	# os.system(cmd)

	tsfiles = glob.glob(wd+"/out/tscale*.csv") # only looks for forcing files incase any outfiles there upon a restart (outfiles will crash tmapp due to index error in cols)
	
	df = pd.read_csv( tsfiles[0],sep='\t', header=None)
	stephr = df.iloc[1,3] -df.iloc[0,3] 
	tout=24/stephr
	
	# order of tsfiles does not matter here
	for myfile in tsfiles:
		myfilebase = os.path.basename(myfile)  # remove path
		# parse original meteo and purturb       
		
		df = pd.read_csv( myfile,sep='\t', header=None)
	

		# fixed columns table returned:
		#SW = col 5 (4)
		#LW = col 6 (5)
		#Sf = col 7 (6) 
		#Rf = col 8 (7)
		#TA = col 9 (6)
		# | Variable | Units  | Description       |
		# |----------|--------|-------------------|
		# | year     | years  | Year              |
		# | month    | months | Month of the year |
		# | day      | days   | Day of the month  |
		# | hour     | hours  | Hour of the day   |
		# | SW       | W m<sup>-2</sup> | Incoming shortwave radiation  |
		# | LW       | W m<sup>-2</sup> | Incoming longwave radiation   |
		# | Sf       | kg m<sup>-2</sup> s<sup>-1</sup> | Snowfall rate |
		# | Rf       | kg m<sup>-2</sup> s<sup>-1</sup> | Rainfall rate |
		# | Ta       | K      | Air temperature      |
		# | RH       | RH     | Relative humidity    |
		# | Ua       | m s<sup>-1</sup> | Wind speed |
		# | Ps       | Pa     | Surface air pressure |




		if config["da"]["PPARS"] == "P":
			df.iloc[:,6] = df.iloc[:,6] *pbias#multiplicative 
			df.iloc[:,7] = df.iloc[:,7] *pbias#multiplicative

		if config["da"]["PPARS"] == "PT":
			df.iloc[:,6] = df.iloc[:,6] *pbias#multiplicative
			df.iloc[:,7] = df.iloc[:,7] *pbias#multiplicative
			df.iloc[:,8] = df.iloc[:,8]*tbias


		if config["da"]["PPARS"] == "PTS":

			df.iloc[:,6] = df.iloc[:,6] *pbias#multiplicative
			df.iloc[:,7] = df.iloc[:,7] *pbias#multiplicative
			df.iloc[:,8] = df.iloc[:,8]*tbias
			df.iloc[:,4] = df.iloc[:,4] * swbias##multiplicative

		# suspicious of LW linked to TA so avoid this option
		if config["da"]["PPARS"] == "PTSL":
			df.iloc[:,6] = df.iloc[:,6] *pbias#multiplicative
			df.iloc[:,7] = df.iloc[:,7] *pbias#multiplicative
			df.iloc[:,8] = df.iloc[:,8]*tbias
			df.iloc[:,4] = df.iloc[:,4] * swbias##multiplicative
			df.iloc[:,5] = df.iloc[:,5] * lwbias##multiplicative



		# subset by hydro year + 3 year spinup
		# so if daYear =2019
		# simulation goes 2016-01-01 00:00 (first timestamp in 2016) to 2019-12-31 23:00 (last timestamp in 2019)
		startYear = daYear -3
		startDayIndex = np.array(np.where(df.iloc[:,0]==startYear)[0])[0]  
		endDayIndex = np.array(np.where(df.iloc[:,0]==daYear)[-1])[-1]  
		dfsub=df.loc[startDayIndex:endDayIndex,:]
		dfsub.to_csv( ensemb_dir+myfilebase,sep='\t', index = False, header=False)
		

		for n in range(31,32): # only do full physics setup31
			nconfig=str(n)
			nconfig2='%02d' % (n,)

			# get myfile id
			a  = myfilebase.split('.')[0]                                                                                                                
			fileID ='%03d' % (int(a.split('tscale_')[1]), )
			
			# write namelist
			nlst = open(ensemb_dir+"/nlst_tmapp.txt","w") 

			str1="! namelists for running FSM "
			str2="\n&config"
			str18="\n  nconfig="+nconfig
			str3="\n/"
			str4="\n&drive"
			str5="\n  met_file = './ensemble/ensemble"+str(ipad)+"/"+myfilebase+"'"
			str6="\n  zT = 1.5"
			str7="\n  zvar = .FALSE."
			str8="\n/"
			str9="\n&params"
			str10="\n/"
			str11="\n&initial"
			str12="\n  Tsoil = 282.98 284.17 284.70 284.70"
			str13="\n/"
			str14="\n&outputs"
			str15="\n  out_file = './ensemble/ensemble"+str(ipad)+"/"+'out'+fileID+'_'+nconfig2+".txt'"
			str16="\n  Nave=" +str(tout)
			str17="\n/\n"

			L = [str1, str2, str18, str3, str4, str5, str6, str7, str8, str9, str10, str11,str12,str13,str14,str15,str16,str17] 
			nlst.writelines(L)
			nlst.close() 

			# run model
			os.chdir(wd)
			fsm="./FSM"
			cmd=fsm+ " < " +ensemb_dir+"/nlst_tmapp.txt"

			os.system(cmd)
			os.chdir(config['main']['srcdir'])

			# remove forcing files
			os.system("rm " + ensemb_dir+"/"+ myfilebase)

#====================================================================
#	Calling MAIN
#====================================================================
if __name__ == '__main__':
	import sys
	wd      = sys.argv[1]
	ensembleN =sys.argv[2]
	daYear =sys.argv[3]

	main(wd, ensembleN, daYear)
