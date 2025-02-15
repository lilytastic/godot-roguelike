class_name Coords

const START_X: int = 0
const START_Y: int = 0

const STEP_X: int = 16
const STEP_Y: int = 16

static func get_position(coord: Vector2, offset: Vector2 = Vector2i(0, 0)) -> Vector2:
	var new_x: int = START_X + STEP_X * coord.x + offset.x
	var new_y: int = START_Y + STEP_Y * coord.y + offset.y
	
	return Vector2i(new_x, new_y)


static func get_coord(in_world_position: Vector2) -> Vector2i: 
	var new_x: int = floor((in_world_position.x - START_X) / STEP_X)
	var new_y: int = floor((in_world_position.y - START_Y) / STEP_Y)
	
	return Vector2i(new_x, new_y)
	

static func get_range(this_coord: Vector2i, that_coord: Vector2i) -> int:
	return abs(this_coord.x - that_coord.x) + abs(this_coord.y - that_coord.y)


static func is_in_range(this_coord: Vector2i, that_coord: Vector2i,
		max_range: int) -> bool:
	return get_range(this_coord, that_coord) <= max_range

static func get_astar_pos(x, y, width) -> int:
	return x + width * y

static func get_point_line(position1: Vector2, position2: Vector2):
	# print(position1, ', ', position2)
	var arr = []
	var x0 = position1.x
	var y0 = position1.y
	var x1 = position2.x
	var y1 = position2.y
	
	var dx = abs(x1 - x0)
	var sx = 1 if (x0 < x1) else -1
	var dy = -abs(y1 - y0)
	var sy = 1 if (y0 < y1) else -1
	var error = dx + dy

	while true:
		arr.append(Vector2(x0, y0))
		var e2 = 2 * error
		if e2 >= dy:
			if x0 == x1:
				break
			error = error + dy
			x0 = x0 + sx
		if e2 <= dx:
			if y0 == y1:
				break
			error = error + dx
			y0 = y0 + sy

	return arr
