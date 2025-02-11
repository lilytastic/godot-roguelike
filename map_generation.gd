class_name MapGen

static func accrete(room: Feature, new_room: Feature, used_cells: Array, bounds: Rect2i, padding := 1):
	var valid_positions = {}
	var directions = new_room.faces.keys()
	directions.shuffle()
	for face_direction in directions:
		# For each exit in that direction...
		for exit in new_room.exits.filter(func(exit): return new_room.faces[face_direction].find(exit) != -1):
			var faces = room.faces[-face_direction]
			faces.shuffle()
			for face_cell in faces:
				# Exit would be something like (3, -1) or (4, 3) for a 3x3 room -- it's relative to 0,0
				# Get all cells for our workspace, where the chosen exit is relative to the current face cell
				var relative_cells = new_room.cells.map(
					func(_cell):
						return _cell - exit + face_cell
				)
				
				var padded_bounds = Rect2(padding, padding, max(0, bounds.size.x - padding * 2), max(0, bounds.size.y - padding * 2))
				
				if relative_cells.any(func(_cell): return !padded_bounds.has_point(_cell)):
					continue
				
				var min_x = relative_cells.map(func(c): return c.x).min()
				var max_x = relative_cells.map(func(c): return c.x).max()
				var min_y = relative_cells.map(func(c): return c.y).min()
				var max_y = relative_cells.map(func(c): return c.y).max()
				
				var new_bounds = Rect2(
					min_x - padding,
					min_y - padding,
					(max_x - min_x) + 1 + padding * 2,
					(max_y - min_y) + 1 + padding * 2
				)
				var overlapped = check_overlap_rect(used_cells, new_bounds) # _check_overlap(used_cells, relative_cells)

				# TODO: Add padding, or walls around features, so they don't wind up side-by-side
				if !overlapped:
					# await Global.sleep(30)
					if !valid_positions.has(face_direction):
						valid_positions[face_direction] = []
					valid_positions[face_direction].append({
						'exit': (-exit + face_cell) + exit,
						'offset': -exit + face_cell
					})
	
	if !valid_positions.keys().size():
		return null
	var chosen_direction = valid_positions.keys().pick_random()
	return valid_positions[chosen_direction].pick_random()

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
