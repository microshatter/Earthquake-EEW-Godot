extends Control

@export var text_lines = [
	"Test News",
	"On 2026-07-27 11:45, \nearthquake occuried near Nanning",
	"Max Intensity: 5-\nMagminude: 5.0 | Depth: 10 km",
	"No Tsunami have been issued"
]
var current_line = 0

func set_text(text_line):
	pass
	
func add_text(text):
	text_lines.append(text)
	
func clear_text():
	text_lines.clear()
	
func start_different_hidden_timer(sec):
	$HiddenTimer.start(sec)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HiddenTimer.start()
	$CycleTimer.start()
	$AudioStreamPlayer.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Label.custom_minimum_size.x = size.x
	$Label.text = text_lines[current_line]
	$ColorRect.size = size


func _on_cycle_timer_timeout() -> void:
	current_line += 1
	if current_line >= len(text_lines):
		current_line = 0

func _on_hidden_timer_timeout() -> void:
	hide()
