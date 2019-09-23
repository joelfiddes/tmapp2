import subprocess

def main(gridpath,mode,targV,beg,end):
	cmd = ["Rscript",  "./rsrc/tmapp_stats.R", gridpath,mode,targV,beg,end]
	subprocess.check_output(cmd)

#===============================================================================
#	Calling Main
#===============================================================================
if __name__ == '__main__':

	gridpath = sys.argv[1]
	mode = sys.argv[2]
	targV = sys.argv[3]
	beg = sys.argv[4]
	end = sys.argv[5]
	main(	gridpath,mode,targV,beg,end)
