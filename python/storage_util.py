#! /usr/bin/env python

import sys, storage, string, getopt

def usage():
	print ("Use this program to configure SAN storage for GEO RAC solutions \n\
		Arguments: \n\
			-h (--help): this screen \n\
			-d (--debug): debug flag; print verbose information \n\
			-f (--free):  print rename commands to rename all powerpath devices to a free pseudodevice \n\
			-r (--real): print rename commands to rename all powerpath devices to the correct pseudodevice \n\
			-s (--sleep): print sleep statements between commands to avoid a powerpath bug which casus a kernel crash \n\
			-m (--munin): print munin config statements for each device (needs updated munin plugin version) \n\
			-c (--csv): print comma separated list of luns and pseudo devices \n\
	")	
	
def main(argv):
	_debug = 0
	_free = 0
	_sleep = 0
	_real = 0
	_munin = 0
	_csv = 0
	try:
		opts, args = getopt.getopt(argv, "hfdsrmc", ["help", "free", "debug", "sleep", "real", "munin", "csv"])
	except getopt.GetoptError:
		usage()
		sys.exit(2)
	for opt, arg in opts:
		if opt in ("-h", "--help"):
			usage()
			sys.exit()
		elif opt == '-d':
			_debug = 1
		elif opt in ("-f", "--free"):
			_free=1
		elif opt in ("-r", "--real"):
			_real=1
		elif opt in ("-s", "--sleep"):
			_sleep=1
		elif opt in ("-m", "--munin"):
			_munin = 1
		elif opt in ("-c", "--csv"):
			_csv=1

# 
# Enter symmetrix devices here
#

	deviceEQ = ''
	deviceTC = ''
	storageInstance = storage.storage()
	pseudoLunDict, lunList, pseudoList = storageInstance.Luns()
	pseudoPossibilities = storageInstance.PseudoPossibilities()
	lunList=dict(zip(lunList, lunList)).keys()
	lunList.sort()
	pseudoFree = storageInstance.FreePseudo()

	if _free==1:
		print storageInstance.FreeLuns(lunList, pseudoLunDict, pseudoFree, deviceEQ, deviceTC, _sleep)
	if _real==1:
		print storageInstance.RealLuns(lunList, pseudoLunDict, pseudoPossibilities, deviceEQ, deviceTC, _sleep)
	if _munin==1:
		print storageInstance.Munin(lunList, pseudoLunDict, deviceEQ, deviceTC)
	if _csv==1:
		print storageInstance.Csv(lunList, pseudoLunDict, deviceEQ, deviceTC)

if __name__ == "__main__":
	main(sys.argv[1:])
