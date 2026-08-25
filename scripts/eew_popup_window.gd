extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var display_size = DisplayServer.screen_get_size()
	position = Vector2i(display_size.x / 2 - size.x / 2, display_size.y - size.y - 100)

func send_eew(
	header: String, 
	brief: String, 
	desc: String, 
	distance: float = 0, 
	intensity: float = 0, 
	report: int = 0, 
	is_final: bool = false
):
	var reportstr = PackedStringArray()
	if report > 0:
		reportstr.append("#%s" % report)
	if is_final:
		reportstr.append("FINAL")
	var r = ''
	if len(reportstr) > 0:
		r = "(%s)" % ", ".join(reportstr)
	$"EEW-Popup".set_header(header + r)
	$"EEW-Popup".set_text(brief)
	$"EEW-Popup".set_affected_cities(desc)
	$"EEW-Popup".set_local_eq_info(distance, intensity)
	show()
	if is_final:
		$final.play()

func _on_hidetimer_timeout() -> void:
	hide()


func _on_visibility_changed() -> void:
	if visible:
		$eew.play()
		$hidetimer.start()


func _on_eew_popup_text_changed() -> void:
	if visible:
		$hidetimer.start()
		$update.play()
