extends Node2D

func _draw() -> void:
	var root_size = $"..".size
	draw_line(Vector2(0, root_size.y), Vector2(root_size.x, root_size.y), Color("292929"))
