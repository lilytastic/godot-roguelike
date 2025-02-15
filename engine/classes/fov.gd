class_name FOV

static func compute_fov(origin, is_blocking: Callable, mark_visible: Callable):
	mark_visible.call(origin)

	for i in range(4):
		var quadrant = Quadrant.new(i, origin)
		var first_row = Row.new(1, -1.0, 1.0)
		scan(first_row, quadrant, is_blocking, mark_visible)

static func reveal(tile, quadrant, mark_visible: Callable):
	var pos = quadrant.transform(tile)
	mark_visible.call(pos.x, pos.y)

static func is_wall(tile, quadrant, is_blocking: Callable):
	if tile == null:
		return false
	var pos = quadrant.transform(tile)
	return is_blocking.call(pos.x, pos.y)

static func is_floor(tile, quadrant, is_blocking: Callable):
	if tile == null:
		return false
	var pos = quadrant.transform(tile)
	return !is_blocking.call(pos.x, pos.y)
	

static func scan(row, quadrant, is_blocking: Callable, mark_visible: Callable):
	var prev_tile = null
	for tile in row.tiles():
		if is_wall(tile, quadrant, is_blocking) or row.is_symmetric(row, tile):
			reveal(tile, quadrant, mark_visible)
		if is_wall(prev_tile, quadrant, is_blocking) and is_floor(tile, quadrant, is_blocking):
			row.start_slope = row.slope(tile)
		if is_floor(prev_tile, quadrant, is_blocking) and is_wall(tile, quadrant, is_blocking):
			var next_row = row.next()
			next_row.end_slope = row.slope(tile)
			scan(next_row, quadrant, is_blocking, mark_visible)
		prev_tile = tile
	if is_floor(prev_tile, quadrant, is_blocking):
		scan(row.next(), quadrant, is_blocking, mark_visible)
	return
