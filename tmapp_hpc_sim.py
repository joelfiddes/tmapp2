
import sys
wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 


from configobj import ConfigObj
config = ConfigObj(wd + "/config.ini")
tscale_root = config['main']['tscale_root']  # path to tscaleV2 directory
sys.path.insert(1, tscale_root)
import tscale_lib as tlib








# outputFormat='FSM'
lp = pd.read_csv(wd+"/listpoints.txt")

	ids=range(len(lp.id))
	for i,task in enumerate(ids):

		print("concat "+ str(ids[i]) )
		tlib.concat_results(wd,str(ids[i]+1), outputFormat)


# convert to FSM format
logging.info("Running FSM")




	meteofiles = sorted(glob.glob(wd+"/out/tscale*.csv"))
	for i,task in enumerate(meteofiles):

		print("Running FSM "+ meteofiles[i])
		tlib.fsm_sim(meteofiles[i],namelist,fsmexepath)