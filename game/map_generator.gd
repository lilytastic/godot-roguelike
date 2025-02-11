extends MapPrefab

const DIGGER_COORDS := Vector2i(13, 4)
const ROOM_COORDS := Vector2i(13, 3)
const EXIT_COORDS := Vector2i(13, 2)

var exits := []
var features := []

var default_ground = MapManager.tile_data['stone floor'].atlas_coords
var default_ground_corridor = MapManager.tile_data['rough stone floor'].atlas_coords
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
				_dig_feature(new_room)
				tiles_dug += new_room.cells.size()
				features.append(new_room)
				print('new exit at ', _coord, ' with ', new_room.cells.size(), ' cells')
				diggers.append(
					_make_digger(
						new_room.get_random_face(direction),
						direction,
						randi_range(10, 23)
					)
				)
			print('clearing template at ', coord, ' with size ', size)
			_clear(coord) # clear template for the area used
	
	print(tiles_dug, ' tiles dug for initial features')
	
	var total_cells = rect.end.x * rect.end.y * 1.0
	var dug_percentage = tiles_dug / total_cells * 100.0
	var iterations = 0
	while true:
		if iterations > 1999:
			break

		iterations += 1
		
		diggers = diggers.filter(func(digger): return digger.life > 0)
		if diggers.size() > 0:
			for digger in diggers:
				var _previous_direction = Vector2i(digger.direction)
				tiles_dug += digger.step()
				"""
				if digger.direction != _previous_direction and randi_range(0, 100) < 20:
					var _directions = Global.directions.filter(
						func(dir):
							return dir != digger.direction and _is_solid(digger.position + dir)
					)
					if _directions.size() > 0:
						var _direction = _directions.pick_random()
						diggers.append(_make_digger(digger.position + _direction, _direction, randi_range(6, 14)))
				"""
				if digger.life <= 0:
					_digger_finished(digger)
			await Global.sleep(10)
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
			await Global.sleep(30)

	print(tiles_dug, '/', total_cells, ' tiles dug (', snapped(dug_percentage, 0.1), '%)')
	
	var wall_atlas_coords = Vector2i(MapManager.tile_data[default_tile].atlas_coords)
	
	var astar = _get_navigation_map(func(cell): return target_layer.get_cell_atlas_coords(cell) == wall_atlas_coords)

	_connect_features(target_layer, astar, _is_solid, func(cell): _open_exit(cell))
	
	await _remove_dead_ends(target_layer)
	
	workspace.queue_free()
	template.queue_free()
	print('==== Map generation complete ====')


func _remove_dead_ends(layer: TileMapLayer):
	print('removing dead ends')
	var filled_cells = 0
	for cell in layer.get_used_cells():
		if !_is_solid(cell):
			var surrounding = layer.get_surrounding_cells(cell)
			var solid_neighbours = surrounding.filter(func(_cell): return _is_solid(_cell))
			if solid_neighbours.size() >= 3:
				print(solid_neighbours.size())
				layer.set_cell(cell, 0, default_wall)
				filled_cells += 1
	
	if filled_cells > 0:
		await Global.sleep(30)
		await _remove_dead_ends(layer)

func _connect_features(target_layer: TileMapLayer, astar: AStar2D, is_solid: Callable, dig: Callable):
	var target_rect = target_layer.get_used_rect()
	var connecting_walls = MapGen.get_connecting_walls(target_layer, is_solid)

	connecting_walls.shuffle()
	print(connecting_walls.size())

	for wall in connecting_walls:
		var position1 = Vector2i(wall.adjoining[0].x, wall.adjoining[0].y)
		var position2 = Vector2i(wall.adjoining[1].x, wall.adjoining[1].y)
		var point1 = Coords.get_astar_pos(position1.x, position1.y, target_rect.end.x)
		var point2 = Coords.get_astar_pos(position2.x, position2.y, target_rect.end.x)
		var feature1 = _get_feature_at(position1)
		var feature2 = _get_feature_at(position2)
		
		var will_break = false

		var path = astar.get_point_path(point1, point2)
		
		if feature1 is Corridor and feature2 is Corridor:
			# TODO: merge them into one corridor immediately
			if feature1 != feature2:
				feature1.cells += feature2.cells
				features = features.filter(func(feature): return feature != feature2)
				print('merge corridors')
			will_break = true

		if path.size() == 0 or path.size() > 20:
			will_break = true

		if will_break:
			var wall_point = Coords.get_astar_pos(wall.cell.x, wall.cell.y, target_rect.end.x)
			astar.add_point(wall_point, wall.cell)
			astar.connect_points(wall_point, point1)
			astar.connect_points(wall_point, point2)
			dig.call(wall.cell)

func _make_digger(coord: Vector2i, direction: Vector2i, life: int) -> Digger:
	return Digger.new(
		coord,
		direction,
		1,
		life,
		_can_dig,
		func(__cell): target_layer.set_cell(__cell, 0, default_ground_corridor)
	)
	
func _dig_off_of(feature: Feature, _position := Vector2i(-1,-1)):
	var digger: Digger

	var random_face = feature.get_random_face()
	if _position == Vector2i(-1, -1) and random_face:
		_position = random_face

	var directions = feature.faces.keys().filter(func(dir): return feature.faces[dir].find(_position) != -1)
	var _direction = directions.front() if directions.size() > 0 else Vector2i.ZERO
	if _position and _direction != Vector2i.ZERO and _is_solid(_position + _direction * 2):
		digger = _make_digger(
			_position,
			_direction,
			randi_range(6, 25)
		)
		diggers.append(digger)
	return digger

func _digger_finished(digger: Digger):
	var new_corridor = Corridor.new()
	new_corridor.set_cells(digger.cells)
	_dig_feature(new_corridor)
	if randi_range(0, 100) < 20:
		for i in range(1):
			_dig_off_of(new_corridor)
	features.append(new_corridor)

func _can_dig(cell: Vector2i):
	return _is_solid(cell) and target_layer.get_used_rect().has_point(cell)

func _get_features_at(cell: Vector2i):
	return features.filter(
		func(feature: Feature):
			return feature.cells.find(cell) != -1 or feature.exits.find(cell) != -1
	)
	
func _get_feature_at(cell: Vector2i):
	var filtered = _get_features_at(cell)
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
	arr.append(_get_features_at(cell + Vector2i.UP))
	arr.append(_get_features_at(cell + Vector2i.LEFT))
	arr.append(_get_features_at(cell + Vector2i.RIGHT))
	arr.append(_get_features_at(cell + Vector2i.DOWN))

	arr = arr.filter(func(x): return x != null)

	var _is_exit = arr.find(func(x: Feature): return x.exits.any(func(exit): exit == cell)) != -1
	if _is_exit:
		return

	for feature in arr:
		if feature is Room:
			feature.exits.append(cell)
			target_layer.set_cell(cell, 0, default_ground_corridor)
		else:
			target_layer.set_cell(cell, 0, default_ground_corridor)

func _is_solid(cell: Vector2i):
	var wall_atlas_coords = Vector2i(MapManager.tile_data[default_tile].atlas_coords)
	return target_layer.get_cell_atlas_coords(cell) == wall_atlas_coords


func _place_feature(feature: Feature, _accrete: Feature = null) -> Feature:
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
	var valid_location = await MapGen.accrete(accrete, feature, used_cells, template.get_used_rect())
	if valid_location:
		feature.exits.append(valid_location.exit)
		target_layer.set_cell(valid_location.exit, 0, default_ground_corridor)
		feature.cells = feature.cells.map(func(_cell): return _cell + valid_location.offset)
		feature.update_faces()
		_dig_feature(feature)
		if randi_range(0, 100) < 66 and feature is Room:
			_dig_off_of(feature)

		return feature
		
	return null

func _dig_feature(feature: Feature):
	var workspace_cells = workspace.get_used_cells()
	print('digging a new room with ', workspace_cells.size(), ' cells')
	for cell in feature.cells:
		if feature is Room:
			target_layer.set_cell(cell, 0, default_ground)
		else:
			target_layer.set_cell(cell, 0, default_ground_corridor)

func _make_room(bounds := Vector2i(10, 10)) -> Feature:
	workspace.clear()
	var new_room = Room.new()
	
	var _cells := []
	var size = Vector2i(
		randi_range(3, min(8, bounds.x)),
		randi_range(3, min(8, bounds.y))
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


func _clear(_coord: Vector2i):
	var cells = MapGen.flood_fill(template, _coord)
	for cell in cells:
		template.set_cell(cell, -1)


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
