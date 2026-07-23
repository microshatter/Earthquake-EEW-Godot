extends Control

var config_file = "user://config.json"
@onready var http_request = $HTTPRequest

func load_settings():
	if FileAccess.file_exists(config_file):
		var f = FileAccess.open(config_file, FileAccess.READ)
		var options = f.get_var()
		$VBoxContainer/Settings/GeoLocation/LatitudeSpinBox.value = options.latitude
		$VBoxContainer/Settings/GeoLocation/LongitudeSpinBox.value = options.longitude
		$VBoxContainer/Settings/MagnitudeIntensity/MagSpinBox.value = options.minmagnitude
		$VBoxContainer/Settings/MagnitudeIntensity/IntenSpinBox.value = options.minintensity
		$VBoxContainer/Settings/FanApi/LineEdit.text = options.fanapi
		print("Config loaded!")

func save_settings():
	var options = {
		"latitude": $VBoxContainer/Settings/GeoLocation/LatitudeSpinBox.value,
		"longitude": $VBoxContainer/Settings/GeoLocation/LongitudeSpinBox.value,
		"minmagnitude": $VBoxContainer/Settings/MagnitudeIntensity/MagSpinBox.value,
		"minintensity": $VBoxContainer/Settings/MagnitudeIntensity/IntenSpinBox.value,
		"fanapi": $VBoxContainer/Settings/FanApi/LineEdit.text
	}
	var f = FileAccess.open(config_file, FileAccess.WRITE)
	f.store_var(options)
	f.close()
	print("Config saved")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/Settings/GeoLocation/LatitudeSpinBox.step = 0.000001
	$VBoxContainer/Settings/GeoLocation/LongitudeSpinBox.step = 0.000001


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_save_only_button_pressed() -> void:
	save_settings()


func _on_locate_button_pressed() -> void:
	var request_api = $"../../API-sources".utilUrls.geoIp
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
	$"..".hide()


func _on_save_button_pressed() -> void:
	save_settings()
	$"..".hide()


func _on_discard_button_pressed() -> void:
	$"..".hide()
	load_settings()


func _on_reload_button_pressed() -> void:
	load_settings()
