extends VBoxContainer

@onready var eqcard = preload("res://scenes/eqcard.tscn")
var max_list = 50

func add_history(intensity, mode: int, location: String, datetime: String, magnitude: float, depth: float, source: String, offset: int = 0):
	var eqcard_inst = eqcard.instantiate()
	if mode == 0:
		eqcard_inst.set_Shindo(intensity)
	else:
		eqcard_inst.set_Intensity(intensity)
	eqcard_inst.location = location
	eqcard_inst.datetime = datetime
	eqcard_inst.magnitude = magnitude
	eqcard_inst.depth = depth
	eqcard_inst.source = source
	eqcard_inst.datetime_offset_hr = offset
	$ScrollContainer/eqlist.add_child(eqcard_inst)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func sort_children():
	var children = $ScrollContainer/eqlist.get_children()
	children.sort_custom(
		func(a, b): 
			var unix_a = Time.get_unix_time_from_datetime_string(a.datetime) - a.datetime_offset_hr * 60 * 60
			var unix_b = Time.get_unix_time_from_datetime_string(b.datetime) - b.datetime_offset_hr * 60 * 60
			return unix_a > unix_b
	)
	for i in range(children.size()):
		$ScrollContainer/eqlist.move_child(children[i], i)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$"../..".custom_maximum_size = get_window().size
	sort_children()
	var child_count = $ScrollContainer/eqlist.get_child_count()
	if child_count > max_list:
		for i in range(child_count - 1, max_list, -1):
			var child = $ScrollContainer/eqlist.get_child(i)
			child.queue_free()
	
# %07.3f
