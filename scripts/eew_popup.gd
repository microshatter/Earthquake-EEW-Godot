extends PanelContainer

signal text_changed()

func set_header(text):
	$VBoxContainer/Title/Label.text = text
	text_changed.emit()

func set_text(text):
	$VBoxContainer/BodyContent/VBoxContainer/Label.text = text
	text_changed.emit()
	
func set_affected_cities(text):
	$VBoxContainer/BodyContent/VBoxContainer/RichTextLabel.text = text
	text_changed.emit()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
