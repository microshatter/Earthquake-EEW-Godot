extends Window

@onready var init_display_size = DisplayServer.screen_get_size()
@onready var main_window = get_window()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	size = Vector2i(init_display_size.x, 100)
	position = Vector2i(0, 0)
	$VBoxContainer.size = size
	# debug
	#var new_debug = load("res://scenes/newswindow.tscn")
	#for i in range(0, 10):
		#var a = new_debug.instantiate()
		#$VBoxContainer.add_child(a)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var display_size = DisplayServer.screen_get_size()
	
	var news_count = $VBoxContainer.get_child_count()
	if news_count > 0:
		show()
		size = Vector2i(display_size.x, 150 * news_count)
		position = Vector2i(0, 0)
		$VBoxContainer.size = size
		for i in $VBoxContainer.get_children():
			if not i.visible:
				$VBoxContainer.remove_child(i)
	else:
		hide()


func _on_close_requested() -> void:
	for i in $VBoxContainer.get_children():
		$VBoxContainer.remove_child(i)
