class_name MapGen

static func accrete(room: Room, new_room: Room, used_cells: Array, bounds: Rect2i, padding := 1):
	var valid_positions = {}
	var directions = new_room.exits.keys()
	directions.shuffle()
	for face_direction in directions:
		# For each exit in that direction...
		for exit in new_room.exits[face_direction]:
			var faces = room.faces[-face_direction]
			faces.shuffle()
			for face_cell in faces:
				# Exit would be something like (3, -1) or (4, 3) for a 3x3 room -- it's relative to 0,0
				# Get all cells for our workspace, where the chosen exit is relative to the current face cell
				var relative_cells = new_room.cells.map(
					func(_cell):
						return _cell - exit + face_cell
				)
				
				if relative_cells.any(
					func(_cell):
						return _cell.x < padding or _cell.x > bounds.end.x - padding * 2 or _cell.y < padding or _cell.y > bounds.end.y - padding * 2
				):
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

				# TODO: Add padding, or walls around rooms, so they don't wind up side-by-side
				if !overlapped:
					await Global.sleep(30)
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


static func check_overlap_rect(arr1: Array, rect: Rect2):
	for item1 in arr1:
		if rect.has_point(item1):
			return true
	return false
