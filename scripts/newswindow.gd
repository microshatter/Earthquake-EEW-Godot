extends Control

@export var text_lines: Array[String] = [
	"Test News",
	"On 2026-07-27 11:45, \nearthquake occurred near Nanning",
	"Max Intensity: 5-\nMagnitude: 5.0 | Depth: 10 km",
	"No Tsunami warnings have been issued",
	"\nwith spaces\n ",
	"This\nMessage\nis\n6\nlines\nlong!!!",
	"ultra long text".repeat(100)
]
var current_line = 0
var max_char = INT64_MAX

func set_text(text_line: Array[String]):
	text_lines = text_line.duplicate()
	for i in range(len(text_lines)):
		text_lines[i].strip_edges()

func add_text(text: String):
	text_lines.append(text.strip_edges())

func clear_text():
	text_lines.clear()

func strip_message():
	for i in range(len(text_lines)):
		text_lines[i] = wrap_string(text_lines[i].strip_edges(), max_char)

func return_text_lines(line: int, reset: bool = true):
	if line < 0 or line >= len(text_lines):
		return 0
	$Label.text = text_lines[line]
	var lines = $Label.get_line_count()
	if reset:
		$Label.text = text_lines[current_line]
	return lines

func return_fixed_message_content():
	var fixed_texts: Array[String] = []
	for i in range(len(text_lines)):
		var text = text_lines[i]
		var lines = return_text_lines(i, false)
		var visible_lines = $Label.max_lines_visible
		if lines > visible_lines:
			var splitted_text = text.split("\n")
			var t = ""
			for j in range(len(splitted_text)):
				if j % visible_lines == 0 and j != 0:
					fixed_texts.append(t.strip_edges())
					t = splitted_text[j] + "\n"
				else:
					t += splitted_text[j] + "\n"
			if len(t):
				fixed_texts.append(t.strip_edges())
		else:
			fixed_texts.append(text)
		#print("Text %d: Lines = %d, Visible Lines = %d, Overload = %s" % [i + 1, lines, visible_lines, lines > visible_lines])
	$Label.text = text_lines[current_line]
	return fixed_texts

func start_different_hidden_timer(sec):
	$HiddenTimer.start(sec)

func test_simulated_eng_chars_in_line():
	# ENSURE AUTO WRAP IS ENABLED!!!!!!
	var t = ""
	var og_width = $Label.size.x
	$Label.size.x = DisplayServer.screen_get_size().x
	$Label.text = t
	while $Label.get_line_count() == 1:
		t += "a"
		$Label.text = t
	max_char = int((len(t) - 1) / 2)
	print("This monitor max chars is %d in a line! It may have chinese and japanese chars, so it will set to %d" % [len(t), max_char])
	$Label.text = ""
	$Label.size.x = og_width

func wrap_string(text: String, max_length: int):
	var a = text
	var final = ""
	while len(a) > 0:
		if len(a) <= max_length:
			final += a
			return final
		var s = a.left(max_length).strip_edges()
		var last_space = max(s.rfind(" "), s.rfind("\t"), s.rfind("\n"), s.rfind("\r"))
		if last_space > 0:
			final += a.left(last_space) + "\n"
			a = a.substr(last_space + 1)
		else:
			final += s + "\n"
			a = a.substr(max_length)

	return final

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label.custom_minimum_size.x = size.x
	$Label.text = text_lines[current_line]
	$ColorRect.size = size
	$HiddenTimer.start()
	$CycleTimer.start()
	$AudioStreamPlayer.play()
	test_simulated_eng_chars_in_line()
	strip_message()
	text_lines = return_fixed_message_content()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Label.custom_minimum_size.x = size.x
	$Label.text = text_lines[current_line]
	$Label.position = Vector2((size.x / 2) - ($Label.size.x / 2), (size.y / 2) - ($Label.size.y / 2))
	$ColorRect.size = size

func _on_cycle_timer_timeout() -> void:
	current_line += 1
	if current_line >= len(text_lines):
		current_line = 0

func _on_hidden_timer_timeout() -> void:
	hide()
