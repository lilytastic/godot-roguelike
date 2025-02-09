extends MapPrefab

const DIGGER_COORDS := Vector2i(13, 4)
const ROOM_COORDS := Vector2i(13, 3)
const EXIT_COORDS := Vector2i(13, 2)

var exits := []
var rooms := []

var default_ground = MapManager.tile_data['soil'].atlas_coords
var default_wall = null

@export var template: TileMapLayer
@export var workspace: TileMapLayer
@export var target_layer: TileMapLayer

func _ready():
	default_wall = MapManager.tile_data[default_tile].atlas_coords
	var rect = template.get_used_rect()
	
	# Clear the map with with the default tile
	print('==== Map generation started ====')
	print('clear with ', default_tile)
	for x in range(rect.end.x):
		for y in range(rect.end.y):
			target_layer.set_cell(
				Vector2i(x, y),
				0,
				MapManager.tile_data[default_tile].atlas_coords
			)

	var tiles_dug = 0
	for coord in template.get_used_cells():
		var atlas_coords = template.get_cell_atlas_coords(coord)
		var direction = _get_tile_direction(coord)
		var size = _get_area(coord)
		if atlas_coords == EXIT_COORDS:
			var _coord = coord + Vector2i(randi_range(0, size.x - 1), randi_range(0, size.x - 1))
			var new_room = _add_room(_coord, direction, Vector2i(3, 3))
			rooms.append(new_room)
			tiles_dug += new_room.cells.size()
			exits.append(coord)
			_clear(coord, size) # clear template for the area used
		if atlas_coords == DIGGER_COORDS:
			_add_digger(coord, direction, size)
	
	var total_cells = rect.end.x * rect.end.y * 1.0
	var dug_percentage = tiles_dug / total_cells * 100.0
	var iterations = 0
	while true:
		if iterations > 999:
			break
		iterations += 1
		total_cells = rect.end.x * rect.end.y * 1.0
		dug_percentage = tiles_dug / total_cells * 100.0
		if dug_percentage > 40:
			break
		
		var new_room = _place_room(_make_room())
		if new_room:
			tiles_dug += new_room.cells.size()
		else:
			tiles_dug += 10

		rooms.append(new_room)
	print(tiles_dug, '/', total_cells, ' tiles dug (', snapped(dug_percentage, 0.1), '%)')
	workspace.queue_free()
	template.queue_free()
	print('==== Map generation complete ====')


func _check_overlap(arr1: Array, arr2: Array):
	for item1 in arr1:
		for item2 in arr2:
			if item1 == item2:
				return true
	return false


func _place_room(room: Room, _accrete: Room = null) -> Room:
	var workspace_cells = workspace.get_used_cells()
	if rooms.size() == 0:
		return null
	var accrete = _accrete if _accrete != null else rooms.pick_random()
	var valid_positions := []
	if !accrete:
		return null
	# Find a valid place to put the room in our workspace
	print('attempt to connect ', room, ' to ', accrete)
	var used_cells = target_layer.get_used_cells().filter(func(cell): return target_layer.get_cell_atlas_coords(cell) != Vector2i(default_wall))
	for face in accrete.faces.keys():
		for cell in accrete.faces[face]:
			for exit in room.exits[-face]:
				var offset = (cell - exit + face)
				var relative_cells = workspace_cells.map(func(_cell): return _cell + offset)
				print('new room at: ', offset)
				var overlapped = _check_overlap(used_cells, relative_cells)
				if !overlapped:
					valid_positions.append(cell)
				pass
	print(valid_positions.size(), ' valid places to put it')
	if valid_positions.size() == 0:
		return null
	var position = valid_positions.pick_random()
	room.cells = room.cells.map(func(cell): return cell + position)
	print('digging a new room with ', workspace_cells.size(), ' cells')
	for cell in room.cells:
		target_layer.set_cell(cell, 0, default_ground)
	return room


func _make_room() -> Room:
	workspace.clear()
	var new_room = Room.new()
	
	var cells := []
	var size = Vector2i(5, 5)
	
	for x in range(size.x):
		for y in range(size.y):
			var coord = Vector2i(x, y)
			workspace.set_cell(coord, 0, default_ground)
			cells.append(coord)
	new_room.cells = cells

	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		new_room.update_faces()
		new_room.exits[direction] = [ new_room.faces[direction].pick_random() ]
		pass
	
	# print('made a new room with ', new_room.exits.values().size(), ' exits')
	return new_room


func _clear(_coord: Vector2i, _size: Vector2i):
	for x in range(_size.x):
		for y in range(_size.y):
			template.set_cell(_coord + Vector2i(x, y), -1)


func _add_room(_coord: Vector2i, direction: Vector2i, size: Vector2i) -> Room:
	print('room at ', _coord)
	
	var dug := []
	
	for x in range(size.x):
		for y in range(size.y):
			var coord = _coord + Vector2i(x, y)
			dug.append(coord)
			_dig(target_layer, coord)
	
	var new_room = Room.new()
	new_room.cells = dug
	new_room.update_faces()
	return new_room

func _dig(layer: TileMapLayer, coord: Vector2i):
	layer.set_cell(coord, 0, default_ground)

func _add_digger(coord: Vector2i, direction: Vector2i, size: int):
	var digger_coord = coord
	
	_dig(target_layer, coord)
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
