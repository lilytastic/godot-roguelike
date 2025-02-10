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
