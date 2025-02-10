extends MapPrefab

const DIGGER_COORDS := Vector2i(13, 4)
const ROOM_COORDS := Vector2i(13, 3)
const EXIT_COORDS := Vector2i(13, 2)

var exits := []
var rooms := []

var default_ground = MapManager.tile_data['soil'].atlas_coords
var default_wall = null
var cursor_prefab = preload('res://game/cursor.tscn')
var cursor = null

@export var template: TileMapLayer
@export var workspace: TileMapLayer
@export var target_layer: TileMapLayer

func _ready():
	default_wall = MapManager.tile_data[default_tile].atlas_coords
	var rect = template.get_used_rect()
	cursor = cursor_prefab.instantiate()
	add_child(cursor)
	
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
			var new_room = _make_room() # _add_room(_coord, direction, Vector2i(3, 3))
			new_room.reposition(_coord)
			for _cell in new_room.cells:
				_dig(target_layer, _cell)
			rooms.append(new_room)
			_clear(coord, size) # clear template for the area used
	
	var total_cells = rect.end.x * rect.end.y * 1.0
	var dug_percentage = tiles_dug / total_cells * 100.0
	var iterations = 0
	while true:
		if iterations > 9999:
			break
		iterations += 1
		total_cells = rect.end.x * rect.end.y * 1.0
		dug_percentage = tiles_dug / total_cells * 100.0
		if dug_percentage > 50:
			break
		
		var new_room = await _place_room(_make_room())
		if new_room:
			tiles_dug += new_room.cells.size()
			rooms.append(new_room)
			await Global.sleep(500)
	print(tiles_dug, '/', total_cells, ' tiles dug (', snapped(dug_percentage, 0.1), '%)')
	
	var flood_filled = MapGen.flood_fill(target_layer, rooms[0].cells[0])
	for cell in flood_filled:
		target_layer.set_cell(cell, 0, Vector2i(1, 0))
	print(flood_filled)
	workspace.queue_free()
	template.queue_free()
	print('==== Map generation complete ====')


func _place_room(room: Room, _accrete: Room = null) -> Room:
	var workspace_cells = workspace.get_used_cells()
	if rooms.size() == 0:
		return null
	var accrete = _accrete if _accrete != null else rooms.pick_random()
	if !accrete:
		return null
		
	# Find a valid place to put the room in our workspace
	# All cells already defined on the target layer, for checking overlaps
	var used_cells = target_layer.get_used_cells().filter(
		func(cell): return target_layer.get_cell_atlas_coords(cell) != Vector2i(default_wall)
	)

	# For each direction this room has exits...
	var valid_location = await MapGen.accrete(accrete, room, used_cells, template.get_used_rect())
	if valid_location:
		_dig(target_layer, valid_location.exit)
		room.cells = room.cells.map(func(_cell): return _cell + valid_location.offset)
		room.update_faces()
		print('digging a new room with ', workspace_cells.size(), ' cells')
		for cell in room.cells:
			_dig(target_layer, cell)

		return room
	return null


func _make_room() -> Room:
	workspace.clear()
	var new_room = Room.new()
	
	var _cells := []
	var size = Vector2i(randi_range(2, 8), randi_range(2, 8))
	
	for x in range(size.x):
		for y in range(size.y):
			var coord = Vector2i(x, y)
			workspace.set_cell(coord, 0, default_ground)
			_cells.append(coord)
	new_room.set_cells(_cells)

	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		new_room.exits[direction] = [ new_room.faces[direction].pick_random() ]
		pass
	
	# print('made a new room with ', new_room.exits.values().size(), ' exits')
	return new_room


func _clear(_coord: Vector2i, _size: Vector2i):
	for x in range(_size.x):
		for y in range(_size.y):
			template.set_cell(_coord + Vector2i(x, y), -1)


func _dig(layer: TileMapLayer, coord: Vector2i):
	layer.set_cell(coord, 0, default_ground)

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
