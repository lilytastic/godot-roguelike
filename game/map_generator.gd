extends TileMapLayer

const DIGGER_COORDS := Vector2i(13, 4)
const ROOM_COORDS := Vector2i(13, 3)
const EXIT_COORDS := Vector2i(13, 2)

@export var target_layer: TileMapLayer

func _ready():
	var rect = get_used_rect()
	
	for x in range(rect.end.x):
		for y in range(rect.end.y):
			target_layer.set_cell(Vector2i(x, y), 0, MapManager.tile_data['rough stone'].atlas_coords)

	for coord in get_used_cells():
		var atlas_coords = get_cell_atlas_coords(coord)
		if atlas_coords == DIGGER_COORDS:
			_add_digger(coord)


func _add_digger(coord: Vector2i):
	print('digger at ', coord)
	
	var digger_coord = coord
	var digger_direction = _get_tile_direction(coord)
	var digger_size = _get_area(digger_coord)

	print(digger_size)

	set_cell(coord, -1)
	
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var time_since_direction_change = 0
	var time_since_size_change = 0
	var used_cells = get_used_cells()
	
	#while used_cells.find(digger_coord) == -1:
	for i in range(30):
		for x in range(digger_size.x):
			for y in range(digger_size.y):
				target_layer.set_cell(digger_coord + Vector2i(x, y), 0, MapManager.tile_data['soil'].atlas_coords)
		digger_coord += digger_direction
		
		if time_since_size_change > 4 and randi_range(0, 100) < 20:
			var mod = [-1, 1].pick_random()
			var new_size = max(1, digger_size.x + mod)
			digger_size.x = new_size
			digger_size.y = new_size
			
			time_since_size_change = 0
		else:
			time_since_size_change += 1
			
		if time_since_direction_change > 4 and randi_range(0, 100) < 50:
			digger_direction = directions.filter(
				func(vec): return vec != digger_direction and vec != -digger_direction
			).pick_random()
			time_since_direction_change = 0
		else:
			time_since_direction_change += 1


func _get_area(coord: Vector2i) -> Vector2i:
	var size = Vector2i(1, 1)
	
	var _check_for_atlas = get_cell_atlas_coords(coord)

	var _check_coord = coord
	while get_cell_atlas_coords(_check_coord + Vector2i(1, 0)) == _check_for_atlas:
		size.x += 1
		_check_coord += Vector2i(1, 0)
	
	_check_coord = coord
	while get_cell_atlas_coords(_check_coord + Vector2i(0, 1)) == _check_for_atlas:
		size.y += 1
		_check_coord += Vector2i(0, 1)
		
	for x in range(size.x):
		for y in range(size.y):
			set_cell(coord + Vector2i(x, y), -1)
	
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
