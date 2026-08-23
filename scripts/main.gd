extends Node


@export var indicator_id = -1
var indicator_menu: PopupMenu
@export var indicator_supported: bool
@onready var display_size = DisplayServer.screen_get_size()
@onready var main_window = get_window()



func initialize_window():
	$"EEW-Popup-Window".move_to_center()
	$"Flipping-Text-Window".visible = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#DisplayServer.tts_speak("Welcome to early warning app, using Godot 4.7!", DisplayServer.tts_get_voices()[0].id)
	indicator_supported = DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR)
	if not indicator_supported:
		print("It seems your OS/Desktop Environment doesn't support indicator yet...")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	$Options.visible = not $Options.visible
	$Options.move_to_center()


func _on_options_visibility_changed() -> void:
	$Options.move_to_center()


func _on_popup_menu_id_pressed(id: int) -> void:
	match id:
		0:
			for i in $"Flipping-Text-Window/VBoxContainer".get_children():
				$"Flipping-Text-Window/VBoxContainer".remove_child(i)
		1:
			$Options.visible = not $Options.visible
		2:
			get_tree().quit()
