extends Control


@onready var http_request = $HTTPRequest

func load_settings():
	var options = Utils.load_json_file(Utils.config_path)
	if options == null:
		$"../../Websockets".add_notification("JSON load failed or file not found(first time run). Using default value.")
		options = {}
	
	$VBoxContainer/TabContainer/General/GeoLocation/LatitudeSpinBox.value = options.get("latitude", 0.0)
	$VBoxContainer/TabContainer/General/GeoLocation/LongitudeSpinBox.value = options.get("longitude", 0.0)
	$VBoxContainer/TabContainer/General/MagnitudeIntensity/MagSpinBox.value = options.get("minmagnitude", 0)
	$VBoxContainer/TabContainer/General/MagnitudeIntensity/IntenSpinBox.value = options.get("minintensity", 5)
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
		"whewsapi": $"VBoxContainer/TabContainer/API Keys/WHEWSApi/LineEdit".text,
		"whewsceaid": $"VBoxContainer/TabContainer/API Keys/WHEWSCEAID/LineEdit".text,
		"whewsceasecret": $"VBoxContainer/TabContainer/API Keys/WHEWSCEASecret/LineEdit".text
	}
	Utils.save_json_file(Utils.config_path, options, 4)
	print("Config saved")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/TabContainer/General/GeoLocation/LatitudeSpinBox.step = 0.000001
	$VBoxContainer/TabContainer/General/GeoLocation/LongitudeSpinBox.step = 0.000001
	load_settings()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_save_only_button_pressed() -> void:
	save_settings()


func _on_locate_button_pressed() -> void:
	var request_api = API_URLs.utilUrls.geoIp
	http_request.request_completed.connect(_locate_complete)
	http_request.request(request_api)

func _locate_complete(_result, _response_code, _headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	print(response)
	$VBoxContainer/TabContainer/General/GeoLocation/LatitudeSpinBox.value = response.latitude
	$VBoxContainer/TabContainer/General/GeoLocation/LongitudeSpinBox.value = response.longitude


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
