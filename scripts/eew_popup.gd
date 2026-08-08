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
	$VBoxContainer/BodyContent/VBoxContainer/Local.text = "震源からの距離: %.2f km | 推定現地震度: %.1f" % [distance, local_intensity]
	if local_intensity >= 1:
		shakealert.emit()
	text_changed.emit()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
