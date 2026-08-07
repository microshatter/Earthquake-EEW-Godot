extends Node

# -- folders -- 
var config_path = "user://config.json"
#--------------

@export var indicator_id = -1
var indicator_menu: PopupMenu
@export var indicator_supported: bool
@onready var display_size = DisplayServer.screen_get_size()
@onready var main_window = get_window()


func load_option():
	if FileAccess.file_exists(config_path):
		var f = FileAccess.open(config_path, FileAccess.READ)
		var options = f.get_var()
		return options

func initialize_window():
	$"EEW-Popup-Window".move_to_center()
	$"Flipping-Text-Window".visible = false

func create_indicator():
	var icon_texture = preload("res://icon.svg")
	indicator_id = DisplayServer.create_status_indicator(
		icon_texture, 
		"Earthquake and EEW Warning",
		self._on_indicator_clicked
	)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#DisplayServer.tts_speak("Welcome to early warning app, using Godot 4.7!", DisplayServer.tts_get_voices()[0].id)
	indicator_supported = DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR)
	if indicator_supported:
		create_indicator()
		print("Indicator create successfully!")
	else:
		print("It seems your OS/Desktop Environment doesn't support indicator yet...")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $"Websockets/Wolfx-Ping".time_left > 0:
		$"StatContainer/wolfx-timer".show()
	else:
		$"StatContainer/wolfx-timer".hide()
		
	if $"Websockets/FanStudio-Ping".time_left > 0:
		$"StatContainer/fanstudio-timer".show()
	else:
		$"StatContainer/fanstudio-timer".hide()

func _on_indicator_clicked(mouse_button: int, _mouse_position: Vector2i):
	if mouse_button == MOUSE_BUTTON_RIGHT:
		for i in $"Flipping-Text-Window/VBoxContainer".get_children():
			$"Flipping-Text-Window/VBoxContainer".remove_child(i)
	else:
		$Options.visible = not $Options.visible
		$Options.move_to_center()

func _exit_tree() -> void:
	if indicator_id != -1:
		DisplayServer.delete_status_indicator(indicator_id)


func _on_button_pressed() -> void:
	$Options.visible = not $Options.visible
	$Options.move_to_center()
