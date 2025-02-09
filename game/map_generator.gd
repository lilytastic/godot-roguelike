extends MapPrefab

const DIGGER_COORDS := Vector2i(13, 4)
const ROOM_COORDS := Vector2i(13, 3)
const EXIT_COORDS := Vector2i(13, 2)

var exits := []
var rooms := []

@export var template: TileMapLayer
@export var workspace: TileMapLayer
@export var target_layer: TileMapLayer

func _ready():
	var rect = template.get_used_rect()
	
	for x in range(rect.end.x):
		for y in range(rect.end.y):
			target_layer.set_cell(Vector2i(x, y), 0, MapManager.tile_data['rough stone'].atlas_coords)

	for coord in template.get_used_cells():
		var atlas_coords = template.get_cell_atlas_coords(coord)
		var direction = _get_tile_direction(coord)
		var size = _get_area(coord)
		if atlas_coords == EXIT_COORDS:
			var _coord = coord + Vector2i(randi_range(0, size.x - 1), randi_range(0, size.x - 1))
			var new_room = _add_room(_coord, direction, Vector2i(3, 3))
			rooms.append(new_room)
			exits.append(coord)
			_clear(coord, size) # clear template for the area used
		if atlas_coords == DIGGER_COORDS:
			_add_digger(coord, direction, size)
			
	workspace.queue_free()
	template.queue_free()


func _clear(_coord: Vector2i, _size: Vector2i):
	for x in range(_size.x):
		for y in range(_size.y):
			template.set_cell(_coord + Vector2i(x, y), -1)


func _add_room(_coord: Vector2i, direction: Vector2i, size: Vector2i):
	print('room at ', _coord)
	
	var dug := []
	
	for x in range(size.x):
		for y in range(size.y):
			var coord = _coord + Vector2i(x, y)
			dug.append(coord)
			_dig(coord)
			
	return {
		'cells': dug,
		'size': size
	}

func _dig(coord: Vector2i):
	target_layer.set_cell(coord, 0, MapManager.tile_data['soil'].atlas_coords)

func _add_digger(coord: Vector2i, direction: Vector2i, size: int):
	var digger_coord = coord
	
	_dig(coord)
	"""
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

	var time_since_direction_change = 0
	var time_since_size_change = 0

	for i in range(12):
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
	"""

func _get_area(coord: Vector2i) -> Vector2i:
	var size = Vector2i(1, 1)
	
	if !template.get_used_cells().any(func(cell): return coord == cell):
		return size

	var _check_for_atlas = template.get_cell_atlas_coords(coord)
	
	if _check_for_atlas == Vector2i(0,0):
		return size

	var _check_coord = coord
	while template.get_cell_atlas_coords(_check_coord + Vector2i(1, 0)) == _check_for_atlas:
		size.x += 1
		_check_coord += Vector2i(1, 0)
	
	_check_coord = coord
	while template.get_cell_atlas_coords(_check_coord + Vector2i(0, 1)) == _check_for_atlas:
		size.y += 1
		_check_coord += Vector2i(0, 1)
	
	return size


func _get_tile_direction(coord: Vector2i):
	var vec = Vector2i.RIGHT
	var alt = template.get_cell_alternative_tile(coord)
	if alt & TileSetAtlasSource.TRANSFORM_TRANSPOSE:
		vec = Vector2i(vec.y, vec.x)
	if alt & TileSetAtlasSource.TRANSFORM_FLIP_H:
		vec.x *= -1
	if alt & TileSetAtlasSource.TRANSFORM_FLIP_V:
		vec.y *= -1
	vec = Vector2i(-vec.y, vec.x)
	return vec
