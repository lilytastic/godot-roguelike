extends TileMapLayer

const DIGGER_COORDS := Vector2i(13, 4)
const ROOM_COORDS := Vector2i(13, 3)
const EXIT_COORDS := Vector2i(13, 2)

@export var workspace: TileMapLayer
@export var target_layer: TileMapLayer

func _ready():
	var rect = get_used_rect()
	
	for x in range(rect.end.x):
		for y in range(rect.end.y):
			target_layer.set_cell(Vector2i(x, y), 0, MapManager.tile_data['rough stone'].atlas_coords)

	for coord in get_used_cells():
		var atlas_coords = get_cell_atlas_coords(coord)
		if atlas_coords == EXIT_COORDS:
			var size = _get_area(coord)
			var direction = _get_tile_direction(coord)
			_add_room(coord)
			
			if direction == Vector2i.LEFT:
				_add_digger(
					Vector2i(coord.x - 1, coord.y + randi_range(0, 2)),
					direction,
					1
				)
			else:
				_add_digger(
					Vector2i(coord.x + 3, coord.y + randi_range(0, 2)),
					direction,
					1
				)
			_clear(coord, size)
		if atlas_coords == DIGGER_COORDS:
			var digger_direction = _get_tile_direction(coord)
			var digger_size = _get_area(coord)
			_add_digger(coord, digger_direction, digger_size)
			
	workspace.queue_free()
	queue_free()


func _clear(_coord: Vector2i, _size: Vector2i):
	for x in range(_size.x):
		for y in range(_size.y):
			set_cell(_coord + Vector2i(x, y), -1)


func _add_room(_coord: Vector2i):
	print('room at ', _coord)
	
	var coord = _coord
	var direction = _get_tile_direction(coord)
	var size = _get_area(coord)
	print(size)
	
	# _add_digger(Vector2i(_coord.x + size.x + 1, randi_range(0, size.y)))

	for x in range(size.x):
		for y in range(size.y):
			target_layer.set_cell(coord + Vector2i(x, y), 0, MapManager.tile_data['soil'].atlas_coords)


func _add_digger(coord: Vector2i, direction: Vector2i, size: int):
	var digger_coord = coord
	
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var time_since_direction_change = 0
	var time_since_size_change = 0

	for i in range(7):
		for x in range(size):
			for y in range(size):
				target_layer.set_cell(
					digger_coord + Vector2i(x, y),
					0,
					MapManager.tile_data['soil'].atlas_coords
				)
		digger_coord += direction
		
		if time_since_size_change > 4 and randi_range(0, 100) < 20:
			var mod = [-1, 1].pick_random()
			var new_size = max(1, size + mod)
			size = new_size
			
			time_since_size_change = 0
		else:
			time_since_size_change += 1
			
		if time_since_direction_change > (5 + size) and randi_range(0, 100) < 50:
			print('change direction')
			direction = directions.filter(
				func(vec):
					return vec != direction and vec != -direction
			).pick_random()
			time_since_direction_change = 0
		else:
			time_since_direction_change += 1


func _get_area(coord: Vector2i) -> Vector2i:
	var size = Vector2i(1, 1)
	
	if !get_used_cells().any(func(cell): return coord == cell):
		print('not used', coord, get_used_cells())
		return size

	var _check_for_atlas = get_cell_atlas_coords(coord)
	
	if _check_for_atlas == Vector2i(0,0):
		return size

	var _check_coord = coord
	while get_cell_atlas_coords(_check_coord + Vector2i(1, 0)) == _check_for_atlas:
		size.x += 1
		_check_coord += Vector2i(1, 0)
	
	_check_coord = coord
	while get_cell_atlas_coords(_check_coord + Vector2i(0, 1)) == _check_for_atlas:
		size.y += 1
		_check_coord += Vector2i(0, 1)
	
	return size


func _get_tile_direction(coord: Vector2i):
	var vec = Vector2i.RIGHT
	var alt = get_cell_alternative_tile(coord)
	if alt & TileSetAtlasSource.TRANSFORM_TRANSPOSE:
		vec = Vector2i(vec.y, vec.x)
	if alt & TileSetAtlasSource.TRANSFORM_FLIP_H:
		vec.x *= -1
	if alt & TileSetAtlasSource.TRANSFORM_FLIP_V:
		vec.y *= -1
	vec = Vector2i(-vec.y, vec.x)
	return vec
