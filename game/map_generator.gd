extends MapPrefab

const DIGGER_COORDS := Vector2i(13, 4)
const ROOM_COORDS := Vector2i(13, 3)
const EXIT_COORDS := Vector2i(13, 2)

var exits := []
var features := []

var default_ground = MapManager.tile_data['soil'].atlas_coords
var default_wall = null
var cursor_prefab = preload('res://game/cursor.tscn')
var cursor = null

var diggers: Array[Digger] = []

@export var template: TileMapLayer
@export var workspace: TileMapLayer
@export var target_layer: TileMapLayer

var directions = [Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT]

var tiles_dug = 0

func _ready():
	tiles_dug = 0
	features.clear()
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

	for coord in template.get_used_cells():
		var atlas_coords = template.get_cell_atlas_coords(coord)
		var direction = MapGen.get_tile_direction(template, coord)
		var size = _get_area(coord)

		if atlas_coords == EXIT_COORDS:
			var _coord = coord + Vector2i(randi_range(0, size.x - 1), randi_range(0, size.x - 1))
			var new_room = _make_room(Vector2i(rect.end.x - _coord.x - 1, rect.end.y - _coord.y - 1))
			new_room.reposition(_coord)
			if rect.encloses(new_room.rect):
				for _cell in new_room.cells:
					_dig(target_layer, _cell)
				tiles_dug += new_room.cells.size()
				features.append(new_room)
				diggers.append(
					_make_digger(
						new_room.get_random_face(direction),
						direction,
						randi_range(10, 23)
					)
				)
			_clear(coord, size) # clear template for the area used
	
	print(tiles_dug, ' tiles dug for initial features')
	
	var total_cells = rect.end.x * rect.end.y * 1.0
	var dug_percentage = tiles_dug / total_cells * 100.0
	var iterations = 0
	while true:
		if iterations > 1999:
			break

		iterations += 1
		
		if diggers.size() > 0:
			if diggers[0].life > 0:
				tiles_dug += diggers[0].step()
				if diggers[0].life <= 0:
					_digger_finished(diggers.pop_front())

			await Global.sleep(50)
			continue

		total_cells = rect.end.x * rect.end.y * 1.0
		dug_percentage = tiles_dug / total_cells * 100.0
		if dug_percentage > 40:
			break
		
		var new_feature = await _make_room()
		
		if randi_range(0, 100) < 50:
			pass
		
		new_feature = await _place_feature(new_feature)
		if new_feature:
			tiles_dug += new_feature.cells.size()
			features.append(new_feature)
			await Global.sleep(150)

	print(tiles_dug, '/', total_cells, ' tiles dug (', snapped(dug_percentage, 0.1), '%)')
	
	var wall_atlas_coords = Vector2i(MapManager.tile_data[default_tile].atlas_coords)
	
	var astar = _get_navigation_map(func(cell): return target_layer.get_cell_atlas_coords(cell) == wall_atlas_coords)

	MapGen.connect_features(target_layer, astar, _is_solid, func(cell): _open_exit(cell))
	
	workspace.queue_free()
	template.queue_free()
	print('==== Map generation complete ====')

func _make_digger(coord: Vector2i, direction: Vector2i, life: int) -> Digger:
	return Digger.new(
		coord,
		direction,
		1,
		life,
		_can_dig,
		func(__cell): _dig(target_layer, __cell)
	)

func _digger_finished(digger: Digger):
	var new_corridor = Feature.new()
	new_corridor.set_cells(digger.cells)
	_dig_feature(new_corridor)
	if features.size() < 10:
		for i in range(randi_range(0, 2)):
			var random_face = new_corridor.get_random_face()
			var _direction = new_corridor.faces.keys().filter(func(dir): return new_corridor.faces[dir].find(random_face) != -1).front()
			if random_face and _direction:
				diggers.append(
					_make_digger(
						random_face,
						_direction,
						randi_range(6, 12)
					)
				)
	features.append(new_corridor)

func _can_dig(cell: Vector2i):
	return _is_solid(cell) and target_layer.get_used_rect().has_point(cell)

func _get_feature_at(cell: Vector2i):
	var filtered = features.filter(
		func(feature: Feature):
			return feature.cells.find(cell) != -1
	)
	if filtered.size() == 0:
		return null
	return filtered.front()

func _get_navigation_map(is_solid: Callable):
	var astar = AStar2D.new()
	var target_rect = target_layer.get_used_rect()
	for cell in target_layer.get_used_cells():
		if !is_solid.call(cell):
			astar.add_point(Coords.get_astar_pos(cell.x, cell.y, target_rect.end.x), cell)
			
	for cell in target_layer.get_used_cells():
		if !is_solid.call(cell):
			for dir in directions:
				var offset = cell + dir
				if !is_solid.call(offset):
					astar.connect_points(Coords.get_astar_pos(cell.x, cell.y, target_rect.end.x), Coords.get_astar_pos(offset.x, offset.y, target_rect.end.x))
				pass
	return astar


func _open_exit(cell: Vector2i):
	var arr = []
	arr.append(_get_feature_at(cell + Vector2i.UP))
	arr.append(_get_feature_at(cell + Vector2i.LEFT))
	arr.append(_get_feature_at(cell + Vector2i.RIGHT))
	arr.append(_get_feature_at(cell + Vector2i.DOWN))
	arr = arr.filter(func(x): return x != null)
	for feature in arr:
		feature.exits.append(cell)

	_dig(target_layer, cell)

func _is_solid(cell: Vector2i):
	var wall_atlas_coords = Vector2i(MapManager.tile_data[default_tile].atlas_coords)
	return target_layer.get_cell_atlas_coords(cell) == wall_atlas_coords


func _place_feature(room: Feature, _accrete: Feature = null) -> Feature:
	var workspace_cells = workspace.get_used_cells()
	if features.size() == 0:
		return null

	var accrete = _accrete if _accrete != null else features.pick_random()
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
		_dig_feature(room)

		return room
	return null

func _dig_feature(feature: Feature):
	var workspace_cells = workspace.get_used_cells()
	print('digging a new room with ', workspace_cells.size(), ' cells')
	for cell in feature.cells:
		_dig(target_layer, cell)

func _make_room(bounds := Vector2i(10, 10)) -> Feature:
	workspace.clear()
	var new_room = Feature.new()
	
	var _cells := []
	var size = Vector2i(
		randi_range(2, min(8, bounds.x)),
		randi_range(2, max(8, bounds.y))
	)
	
	for x in range(size.x):
		for y in range(size.y):
			var coord = Vector2i(x, y)
			workspace.set_cell(coord, 0, default_ground)
			_cells.append(coord)
	new_room.set_cells(_cells)

	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		new_room.exits.append(new_room.faces[direction].pick_random())
		pass
	
	# print('made a new room with ', new_room.exits.size(), ' exits')
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
