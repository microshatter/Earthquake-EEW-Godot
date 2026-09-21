extends PanelContainer

signal text_changed()
signal shakealert()

func set_header(text):
	$VBoxContainer/Title/Label.text = text
	text_changed.emit()

func set_text(text):
	$VBoxContainer/BodyContent/VBoxContainer/Label.text = text
	text_changed.emit()

func set_affected_cities(text):
	$VBoxContainer/BodyContent/VBoxContainer/RichTextLabel.text = text
	text_changed.emit()

func set_local_eq_info(distance: float, local_intensity: float):
	$VBoxContainer/BodyContent/VBoxContainer/Local.text = "%.2f km | Intensity %.1f" % [distance, local_intensity]
	if local_intensity >= Utils.load_option().get("minintensity", 0):
		shakealert.emit()
	text_changed.emit()

func set_max_prograss(pwave: float, swave: float):
	$VBoxContainer/BodyContent/VBoxContainer/HBoxContainer/PWave/Remain.max_value = pwave
	$VBoxContainer/BodyContent/VBoxContainer/HBoxContainer/SWave/Remain.max_value = swave

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not visible:
		$VBoxContainer/BodyContent/VBoxContainer/HBoxContainer/PWave/Timer.text = "---.--"
		$VBoxContainer/BodyContent/VBoxContainer/HBoxContainer/SWave/Timer.text = "---.--"
	# P-Wave
	var ptime = $"../../PWave".time_left
	$VBoxContainer/BodyContent/VBoxContainer/HBoxContainer/PWave/Timer.text = "%06.2f" % ptime
	if $VBoxContainer/BodyContent/VBoxContainer/HBoxContainer/PWave/Remain.max_value < ptime:
		$VBoxContainer/BodyContent/VBoxContainer/HBoxContainer/PWave/Remain.max_value = ptime
	$VBoxContainer/BodyContent/VBoxContainer/HBoxContainer/PWave/Remain.value = ptime
	
	# S-Wave
	var stime = $"../../SWave".time_left
	$VBoxContainer/BodyContent/VBoxContainer/HBoxContainer/SWave/Timer.text = "%06.2f" % stime
	if $VBoxContainer/BodyContent/VBoxContainer/HBoxContainer/SWave/Remain.max_value < stime:
		$VBoxContainer/BodyContent/VBoxContainer/HBoxContainer/SWave/Remain.max_value = stime
	$VBoxContainer/BodyContent/VBoxContainer/HBoxContainer/SWave/Remain.value = stime
