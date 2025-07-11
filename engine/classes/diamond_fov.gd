class_name DiamondFov

# from https://github.com/Bozar/godot-4-roguelike-tutorial/wiki/c05
func get_fov_map(source: Vector2i, sight_range: int,
		out_fov_map: Dictionary) -> void:
	var column: Array
	var coord: Vector2i = Vector2i(0, 0)

	for x: int in out_fov_map.keys():
		column = out_fov_map[x]
		for y: int in range(0, column.size()):
			coord.x = x
			coord.y = y
			column[y] = Coords.is_in_range(source, coord, sight_range)
			
