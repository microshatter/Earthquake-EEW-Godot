extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var display_size = DisplayServer.screen_get_size()
	position = Vector2i(display_size.x / 2 - size.x / 2, display_size.y - size.y - 100)


func _on_hidetimer_timeout() -> void:
	hide()


func _on_visibility_changed() -> void:
	if visible:
		$eew.play()
		$hidetimer.start()


func _on_eew_popup_text_changed() -> void:
	if visible:
		$hidetimer.start()
