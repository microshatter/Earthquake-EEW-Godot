class_name EQ_TOGGLES
extends RefCounted

# API Enabled
static var api_enabled = {
	"wolfx": true,
	"fan": true, # Full name: FAN Studio | FSSN is only recieved unless I apply for app id request
	"whews": false, # disabled unless authorized
	"p2p": true, # Full name: P2PQuake
}

# default value
static var sources_enabled = {
	# EEW
	"jma_eew": true,
	"cwa_eew": true,
	"sa_eew": false,
	"kma_eew": true,
	"cea": true,
	"cea_pr": true,
	# Information
	"jma": true,
	"cwa": true,
	"cenc": true,
	"kma": true,
	"bmkg": false,
	"geonet": false,
	"tmd": false,
	"usp": false,
	"gfz": false,
	"ingv": false,
	"usgs": true,
	"emsc": false,
	"hko": false,
	"bcsf": false,
	"nrcan": false,
	"mmd": false,
	"phivolcs": false,
	"sgc": false,
	"ga": false,
	"cenais": false,
	"gsras": false,
	"bgs": false,
	"ipma": false,
	"ssn": false,
	"afad": false,
	"sed": false,
	"noa": false,
	"scsn": false,
	"ssw": false,
	"iag": false,
	"igp": false,
	"nepal": false,
	"beijing": false,
	"yunnan": false,
	"ningxia": false,
	"fssn": true,
	# Tsunami and Other alerts
	"tsunami": true,
	"ntwc": true,
	"ptwc": true,
	"incois": true,
	"cat_tsunami": true,
	"weatheralarm": false,
	"va": false,
	"jma_tsunami": true,
}
