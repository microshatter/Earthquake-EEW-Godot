extends Control

@export var text_lines: Array[String] = [
	"Test News",
	"On 2026-07-27 11:45, \nearthquake occurred near Nanning",
	"Max Intensity: 5-\nMagnitude: 5.0 | Depth: 10 km",
	"No Tsunami warnings have been issued",
	"\nwith spaces\n ",
	"This\nMessage\nis\n6\nlines\nlong!!!",
	"ultralongtext".repeat(100)
]
var current_line = 0

func set_text(text_line: Array[String]):
	for i in range(len(text_line)):
		text_line[i].strip_edges()
	text_lines = text_line
	
func add_text(text: String):
	text_lines.append(text.strip_edges())
	
func clear_text():
	text_lines.clear()
	
func strip_message():
	for i in range(len(text_lines)):
		text_lines[i] = text_lines[i].strip_edges()
	
func return_text_lines(line: int, reset: bool = true):
	if line < 0 or line >= len(text_lines):
		return 0
	$Label.text = text_lines[line]
	var lines = $Label.get_line_count()
	if reset:
		$Label.text = text_lines[current_line]
	return lines
	
func retuen_fixed_message_content():
	var fixed_texts: Array[String] = []
	for i in range(len(text_lines)):
		var text = text_lines[i]
		var lines = return_text_lines(i, false)
		var visible_lines = $Label.max_lines_visible
		if lines > visible_lines:
			pass
		else:
			fixed_texts.append(text)
		print("Text %d: Lines = %d, Visible Lines = %d, Overload = %s" % [i + 1, lines, visible_lines, lines > visible_lines])
	$Label.text = text_lines[current_line]
	return fixed_texts
	
func start_different_hidden_timer(sec):
	$HiddenTimer.start(sec)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HiddenTimer.start()
	$CycleTimer.start()
	$AudioStreamPlayer.play()
	strip_message()
	retuen_fixed_message_content()

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
