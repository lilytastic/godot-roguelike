class_name MapGen

static func accrete(attach_to: Feature, new_room: Feature, used_cells: Array, bounds: Rect2i, padding := 1):
	var valid_positions = {}
	var directions = new_room.faces.keys()
	directions.shuffle()
	# For each direction...
	for face_direction in directions:
		# For each of the new room's exits in that direction...
		for exit in new_room.exits.filter(func(exit): return new_room.faces[face_direction].find(exit) != -1):
			# Get faces for that direction, shuffle them
			var faces = attach_to.faces[-face_direction]
			faces.shuffle()
			for face_cell in faces:
				# TODO: Make a helper function out of this shit
				# Get all cells for our workspace, where the chosen exit is relative to the current face cell
				var relative_cells = move_relative(new_room.cells, -(exit - face_cell), bounds, padding)

				if relative_cells.size() == 0:
					continue
					
				var overlapped = check_cell_overlap(relative_cells, used_cells, padding)

				# TODO: Add padding, or walls around features, so they don't wind up side-by-side
				if !overlapped:
					# await Global.sleep(30)
					if !valid_positions.has(face_direction):
						valid_positions[face_direction] = []
					valid_positions[face_direction].append({
						'exit': (-exit + face_cell) + exit,
						'offset': -exit + face_cell
					})
	
	if valid_positions.keys().size() == 0:
		return {}
	var chosen_direction = valid_positions.keys().filter(func(key): return valid_positions[key].size() > 0).pick_random()
	return valid_positions[chosen_direction].pick_random()

static func move_relative(_cells: Array, offset: Vector2i, bounds: Rect2, padding := 1) -> Array:
	var relative_cells = _cells.map(
		func(_cell):
			return _cell + offset
	)
	var padded_bounds = Rect2(padding, padding, max(0, bounds.size.x - padding * 2), max(0, bounds.size.y - padding * 2))
	if relative_cells.any(func(_cell): return !padded_bounds.has_point(_cell)):
		return []
	return relative_cells

static func check_cell_overlap(cells: Array, used_cells: Array, padding := 1) -> bool:
	var min_x = cells.map(func(c): return c.x).min()
	var max_x = cells.map(func(c): return c.x).max()
	var min_y = cells.map(func(c): return c.y).min()
	var max_y = cells.map(func(c): return c.y).max()
	
	var new_bounds = Rect2(
		min_x - padding,
		min_y - padding,
		(max_x - min_x) + 1 + padding * 2,
		(max_y - min_y) + 1 + padding * 2
	)
	return check_overlap_rect(used_cells, new_bounds)


static func get_connecting_walls(target_layer: TileMapLayer, is_solid: Callable):
	var connecting_walls = []
	var walls = target_layer.get_used_cells().filter(func(cell): return is_solid.call(cell))
	for cell in walls:
		if target_layer.get_used_rect().has_point(cell + Vector2i.LEFT) and target_layer.get_used_rect().has_point(cell + Vector2i.RIGHT) and !is_solid.call(cell + Vector2i.LEFT) and !is_solid.call(cell + Vector2i.RIGHT):
			connecting_walls.append({'cell': cell, 'direction': 'HORIZONTAL', 'adjoining': [cell + Vector2i.LEFT, cell + Vector2i.RIGHT]})
		if target_layer.get_used_rect().has_point(cell + Vector2i.UP) and target_layer.get_used_rect().has_point(cell + Vector2i.DOWN) and !is_solid.call(cell + Vector2i.UP) and !is_solid.call(cell + Vector2i.DOWN):
			connecting_walls.append({'cell': cell, 'direction': 'VERTICAL', 'adjoining': [cell + Vector2i.UP, cell + Vector2i.DOWN]})
	return connecting_walls

static func check_overlap(arr1: Array, arr2: Array):
	for item1 in arr1:
		for item2 in arr2:
			if item1 == item2:
				return true
	return false

static func check_overlap_rect(arr1: Array, rect: Rect2):
	for item1 in arr1:
		if rect.has_point(item1):
			return true
	return false

static func flood_fill(tile_map_layer: TileMapLayer, coord: Vector2i) -> Array:
	var coords = []
	var queue = [ coord ]
	var rect = tile_map_layer.get_used_rect()
	var atlas_coords = tile_map_layer.get_cell_atlas_coords(coord)
	while queue.size() > 0:
		var next = queue.pop_front()
		var atlas_coords_here = tile_map_layer.get_cell_atlas_coords(next)
		if coords.find(next) == -1 and atlas_coords_here == atlas_coords and next.x >= 0 and next.y >= 0 and next.x <= rect.end.x and next.y <= rect.end.y:
			coords.append(next)
			queue.append(next + Vector2i.UP)
			queue.append(next + Vector2i.LEFT)
			queue.append(next + Vector2i.RIGHT)
			queue.append(next + Vector2i.DOWN)
	return coords

static func get_tile_direction(layer: TileMapLayer, coord: Vector2i):
	var vec = Vector2i.RIGHT
	var alt = layer.get_cell_alternative_tile(coord)
	if alt & TileSetAtlasSource.TRANSFORM_TRANSPOSE:
		vec = Vector2i(vec.y, vec.x)
	if alt & TileSetAtlasSource.TRANSFORM_FLIP_H:
		vec.x *= -1
	if alt & TileSetAtlasSource.TRANSFORM_FLIP_V:
		vec.y *= -1
	vec = Vector2i(-vec.y, vec.x)
	return vec
