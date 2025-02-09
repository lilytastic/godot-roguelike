extends TileMapLayer

var cells := []
const DIGGER_COORDS := Vector2i(13, 2)

func _ready():
	cells = get_used_cells()
	print(cells)
	for coord in cells:
		var atlas_coords = get_cell_atlas_coords(coord)
		if atlas_coords == DIGGER_COORDS:
			_add_digger(coord)


func _add_digger(coord: Vector2i):
	print('digger at ', coord)
	
	var digger_coord = coord
	var digger_direction = _get_tile_direction(coord)
	var digger_size = Vector2i(1, 1)
	var _check_coord = coord
	while get_cell_atlas_coords(_check_coord + Vector2i(1, 0)) == DIGGER_COORDS:
		digger_size.x += 1
		_check_coord += Vector2i(1, 0)
	
	_check_coord = coord
	while get_cell_atlas_coords(_check_coord + Vector2i(0, 1)) == DIGGER_COORDS:
		digger_size.y += 1
		_check_coord += Vector2i(0, 1)
		
	for x in range(digger_size.x):
		for y in range(digger_size.y):
			set_cell(coord + Vector2i(x, y), -1)
		
	print(digger_size)

	set_cell(coord, -1)
	
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var time_since_direction_change = 0
	for i in range(20):
		for x in range(digger_size.x):
			for y in range(digger_size.y):
				set_cell(digger_coord + Vector2i(x, y), 0, MapManager.tile_data['soil'].atlas_coords)
		digger_coord += digger_direction
		if time_since_direction_change > 4 and randi_range(0, 100) < 20:
			digger_direction = directions.filter(
				func(vec): return vec != digger_direction and vec != -digger_direction
			).pick_random()
		else:
			time_since_direction_change += 1


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
