class_name EQ_TOGGLES
extends RefCounted

# API Enabled
static var api_enabled = {
	"wolfx": true,
	"fssn": true,
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
	"early_est": false,
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
	"funvisis": false,
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

static func load_provider():
	var object = Utils.load_json_file(Utils.provider_path)
	if object == null or typeof(object) != TYPE_DICTIONARY:
		object = {}
	
	# validation
	var validated := {}
	for key in object:
		var value = object[key]
		if typeof(value) == TYPE_BOOL:
			validated[key] = value
		else:
			push_warning("load_provider: dropping non-bool entry '%s' (%s)" % [key, typeof(value)])
	api_enabled.merge(validated, true)

static func save_provider():
	Utils.save_json_file(Utils.provider_path, api_enabled)

static func load_source():
	var object = Utils.load_json_file(Utils.source_path)
	if object == null or typeof(object) != TYPE_DICTIONARY:
		object = {}
		
	# validation
	var validated := {}
	for key in object:
		var value = object[key]
		if typeof(value) == TYPE_BOOL:
			validated[key] = value
		else:
			push_warning("load_source: dropping non-bool entry '%s' (%s)" % [key, typeof(value)])
	sources_enabled.merge(validated, true)

static func save_source():
	Utils.save_json_file(Utils.source_path, sources_enabled)
