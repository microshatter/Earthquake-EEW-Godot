extends Control


@onready var http_request = $HTTPRequest

func load_settings():
	if FileAccess.file_exists(Utils.config_path):
		var f = FileAccess.open(Utils.config_path, FileAccess.READ)
		var json = JSON.new()
		var err = json.parse(f.get_as_text())
		var options = {}
		if err == OK:
			options = json.data
		else:
			$"../../Websockets".add_notification("JSON load failed! Using default value. \nCheck config and reload again!")
			$"..".show()
			OS.shell_open(ProjectSettings.globalize_path(Utils.config_path))
		$VBoxContainer/TabContainer/General/GeoLocation/LatitudeSpinBox.value = options.get("latitude", 0.0)
		$VBoxContainer/TabContainer/General/GeoLocation/LongitudeSpinBox.value = options.get("longitude", 0.0)
		$VBoxContainer/TabContainer/General/MagnitudeIntensity/MagSpinBox.value = options.get("minmagnitude", 0)
		$VBoxContainer/TabContainer/General/MagnitudeIntensity/IntenSpinBox.value = options.get("minintensity", 5)
		$"VBoxContainer/TabContainer/API Keys/FanApi/LineEdit".text = options.get("fanapi", "")
		$"VBoxContainer/TabContainer/API Keys/WHEWSApi/LineEdit".text = options.get("whewsapi", "")
		$"VBoxContainer/TabContainer/API Keys/WHEWSCEAID/LineEdit".text = options.get("whewsceaid", "")
		$"VBoxContainer/TabContainer/API Keys/WHEWSCEASecret/LineEdit".text = options.get("whewsceasecret", "")
		print("Config loaded!")

func save_settings():
	var options = {
		"latitude": $VBoxContainer/TabContainer/General/GeoLocation/LatitudeSpinBox.value,
		"longitude": $VBoxContainer/TabContainer/General/GeoLocation/LongitudeSpinBox.value,
		"minmagnitude": $VBoxContainer/TabContainer/General/MagnitudeIntensity/MagSpinBox.value,
		"minintensity": $VBoxContainer/TabContainer/General/MagnitudeIntensity/IntenSpinBox.value,
		"fanapi": $"VBoxContainer/TabContainer/API Keys/FanApi/LineEdit".text,
		"whewsapi": $"VBoxContainer/TabContainer/API Keys/WHEWSApi/LineEdit".text,
		"whewsceaid": $"VBoxContainer/TabContainer/API Keys/WHEWSCEAID/LineEdit".text,
		"whewsceasecret": $"VBoxContainer/TabContainer/API Keys/WHEWSCEASecret/LineEdit".text
	}
	var f = FileAccess.open(Utils.config_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(options, "  "))
	f.close()
	print("Config saved")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/TabContainer/General/GeoLocation/LatitudeSpinBox.step = 0.000001
	$VBoxContainer/TabContainer/General/GeoLocation/LongitudeSpinBox.step = 0.000001
	load_settings()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_save_only_button_pressed() -> void:
	save_settings()


func _on_locate_button_pressed() -> void:
	var request_api = API_URLs.utilUrls.geoIp
	http_request.request_completed.connect(_locate_complete)
	http_request.request(request_api)

func _locate_complete(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	print(response)
	$VBoxContainer/Settings/GeoLocation/LatitudeSpinBox.value = response.latitude
	$VBoxContainer/Settings/GeoLocation/LongitudeSpinBox.value = response.longitude


func _on_options_close_requested() -> void:
	_on_discard_button_pressed()


func _on_save_button_pressed() -> void:
	save_settings()
	$"..".hide()


func _on_discard_button_pressed() -> void:
	$"..".hide()
	load_settings()


func _on_reload_button_pressed() -> void:
	load_settings()


func _on_fan_key_button_pressed() -> void:
	OS.shell_open("https://api.fanstudio.tech/dev-platform/")
