class_name MapGenerator
extends MapPrefab

const DIGGER_COORDS := Vector2i(13, 4)
const ROOM_COORDS := Vector2i(13, 3)
const EXIT_COORDS := Vector2i(13, 2)
const WALL_COORDS := Vector2i(8, 5)
const CELLULAR_COORDS := Vector2i(1, 17)

var exits := []
var features := []
var entities := []

var default_ground = MapManager.tile_data['stone floor'].atlas_coords
var default_ground_corridor = MapManager.tile_data['rough stone floor'].atlas_coords
var default_ground_natural = MapManager.tile_data['soil'].atlas_coords
var default_wall = null

var astar: AStar2D = AStar2D.new()

var diggers: Array[Digger] = []

@export var _generation_speed = 0

@export var template: TileMapLayer
@export var workspace: TileMapLayer
@export var target_layer: TileMapLayer

var directions = [Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT]

var tiles_dug = 0
var is_generating = true

var used_cells := {}


func generate(seed: int, data := {}) -> Dictionary:
	is_generating = true
	tiles_dug = 0
	features.clear()
	default_wall = MapManager.tile_data[default_tile].atlas_coords
	var rect = template.get_used_rect()

	astar = AStar2D.new()
	
	var time_started = Time.get_ticks_msec()
	print('==== Map generation started ====')
	seed(seed)
	print('Seed: ', seed)

	# Clear the map with with the default tile
	_fill(rect, default_wall)

	_resolve_template()
	
	_dig_random_dungeon()
	
	_connect_features(target_layer, _is_solid, func(cell): _open_exit(cell))
	
	_remove_walls(target_layer)
	
	await _remove_dead_ends(target_layer, _generation_speed)
	
	_add_entities(data)
	
	workspace.free()
	template.free()
	var time_finished = Time.get_ticks_msec()
	print('==== Map generation complete ====')
	print('Time to generate: ', snapped((time_finished - time_started) / 1000.0, 0.01), 's')
	
	is_generating = false
	randomize() # Reset the seed to a random state
	return {
		'features': features,
		'exits': exits,
		'entities': entities
	}


func _add_entities(data := {}):
	var connections = data.get('connections', [])

	var _exits = exits
	_exits.shuffle()
	
	var i = 0
	for connection in connections:
		if _exits.size() <= i:
			break

		var _exit = _exits[i]
		var _depth = data.get('depth', 0)
		var _connected_depth = connection.get('depth', 0)
		var random_tile = _exit.cells.pick_random()
		var new_entity = Entity.new({ 'blueprint': 'stairs_down' if _depth < _connected_depth else 'stairs_up' })
		new_entity.location = Location.new('', random_tile)
		new_entity.equipment = EquipmentProps.new({})
		new_entity.destination = connection
		print("linked an exit to: ", connection)
		entities.append(new_entity)
		i += 1
	
	var map_definition = MapManager.map_definitions.get(data.get('branch', ''), null)
	if _exits.size() > i:
		# Utilize additional exits!
		var _exit = _exits[i]
		if map_definition and map_definition.max_depth > data.get('depth', 0):
			var random_tile = _exit.cells.pick_random()
			var new_entity = Entity.new({ 'blueprint': 'stairs_down' })
			new_entity.location = Location.new('', random_tile)
			new_entity.equipment = EquipmentProps.new({})
			new_entity.destination = { 'branch': data.get('branch', ''), 'depth': data.get('depth', 0) + 1 }
			print('(2) linked an exit to: ', new_entity.destination)
			entities.append(new_entity)
			i += 1
			pass

	# await _connect_isolated_rooms(target_layer)
	var _features = features
	_features.shuffle()
	for feature in _features.filter(func(f): return f is Room).slice(0, 20):
		var random_tile = feature.cells.pick_random()
		var new_entity = Entity.new({ 'blueprint': 'ghoul' })
		new_entity.location = Location.new('', random_tile)
		new_entity.equipment = EquipmentProps.new({})
		new_entity.energy = -100
		entities.append(new_entity)


func _resolve_template():
	var rect = template.get_used_rect()
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
				exits.append(new_room)
				# print('new exit at ', _coord, ' with ', new_room.cells.size(), ' cells')
				diggers.append(
					_make_digger(
						new_room.get_random_face(direction),
						direction,
						randi_range(10, 23)
					)
				)
			# print('clearing template at ', coord, ' with size ', size)
			_clear(coord) # clear template for the area used

		if atlas_coords == CELLULAR_COORDS:
			var cells = MapGen.flood_fill(template, coord)
			# print('cellular ', size, ' with ', cells.size(), ' cells')
			var new_cells := {}
			
			for cell in cells:
				new_cells[cell] = 0 if randi_range(0, 100) < 60 else 1
				
			for i in range(12):
				if _generation_speed > 0:
					await Global.sleep(150 / _generation_speed)
				for cell in cells:
					var neighbours = [
						cell + Vector2i.UP,
						cell + Vector2i.UP + Vector2i.LEFT,
						cell + Vector2i.LEFT,
						cell + Vector2i.UP + Vector2i.RIGHT,
						cell + Vector2i.RIGHT,
						cell + Vector2i.DOWN,
						cell + Vector2i.DOWN + Vector2i.LEFT,
						cell + Vector2i.DOWN + Vector2i.RIGHT,
					]
					var living_neighbours = neighbours.filter(func(n): return cells.find(n) != -1 and new_cells[n] == 1)
					var outside_edges = neighbours.filter(func(n): return cells.find(n) == -1)
					# var dead_neighbours = neighbours.filter(func(n): return cells.find(n) == -1 or new_cells[n] == 0)
					if new_cells[cell] == 1:
						if living_neighbours.size() < 2 or outside_edges.size() > 0:
							new_cells[cell] = 0
					else:
						if living_neighbours.size() >= 5:
							new_cells[cell] = 1

				if _generation_speed > 0:
					await Global.sleep(300 / _generation_speed)

				for cell in new_cells.keys():
					target_layer.set_cell(cell, 0, default_ground_natural if new_cells[cell] == 1 else default_wall)
				
			var feature = Cavern.new()
			feature.set_cells(cells.filter(func(cell): return new_cells[cell] == 1))
			_dig_feature(feature)

			_clear(coord)

		if atlas_coords == WALL_COORDS:
			used_cells[coord] = coord
			target_layer.set_cell(coord, 0, WALL_COORDS)

	print(tiles_dug, ' tiles dug for initial features, of which there are ', features.size())


func _fill(rect: Rect2, atlas_coords: Vector2i):
	for x in range(rect.end.x):
		for y in range(rect.end.y):
			target_layer.set_cell(Vector2i(x, y), 0, atlas_coords)


func _dig_random_dungeon():
	var rect = template.get_used_rect()
	var total_cells = rect.end.x * rect.end.y * 1.0
	var dug_percentage = tiles_dug / total_cells * 100.0
	var iterations = 0
	var previously_dug = tiles_dug
	while true:
		if iterations > 900:
			print('breaking loop; iterations > 900')
			break
		
		iterations += 1

		dug_percentage = tiles_dug / total_cells * 100.0
		var max_dug_percentage = 50

		previously_dug = tiles_dug

		total_cells = rect.end.x * rect.end.y * 1.0
		if dug_percentage > max_dug_percentage:
			print('breaking loop; dug_percentage > ', max_dug_percentage)
			break
		
		diggers = diggers.filter(func(digger): return digger.life > 0)
		if diggers.size() > 0:
			for digger in diggers:
				digger.step()
				if digger.life <= 0:
					var result = _digger_finished(digger)
			if _generation_speed > 0:
				await Global.sleep(30 / _generation_speed)
			continue
		
		var hallway_chance = 30
		if randi_range(0, 100) <= hallway_chance and features.size() > 0:
			var shuffled = features
			shuffled.shuffle()
			for item in shuffled:
				var result = _dig_off_of(features.pick_random())
				if result:
					break
			continue
			
		var new_feature = _make_room()
		new_feature = _place_feature(new_feature)
		if new_feature:
			# print('placed ', new_feature)
			_dig_feature(new_feature)
			if _generation_speed > 0:
				await Global.sleep(200 / _generation_speed)
	print(tiles_dug, '/', total_cells, ' tiles dug (', snapped(dug_percentage, 0.1), '%)')


func _connect_isolated_rooms(layer: TileMapLayer):
	var rooms = features.filter(func(feature): return feature is Room)
	rooms.shuffle()
	
	for room in rooms:
		await _augh(rooms, room)


func _augh(rooms: Array, room: Feature):
	var room_center = room.get_center()
	if _is_solid(room_center):
		return

	var closest_rooms = rooms.filter(func(r): return r != room)
	closest_rooms.shuffle()
	closest_rooms.sort_custom(
		func(a: Room, b: Room):
			if a.get_center().distance_to(room_center) < b.get_center().distance_to(room_center):
				return true
			return false
	)
	
	for other_room in closest_rooms:
		await _auugh(room, other_room)


func _auugh(room: Room, other_room: Room):
	var target_rect = target_layer.get_used_rect()
	var room_center = room.get_center()
	var other_center = other_room.get_center()

	if _is_solid(other_center):
		return
	var point1 = Coords.get_astar_pos(room_center.x, room_center.y, target_rect.end.x)
	var point2 = Coords.get_astar_pos(other_center.x, other_center.y, target_rect.end.x)
	if !astar.are_points_connected(point1, point2):
		var new_path = await _connect(room, other_room)


func _connect(feature1: Feature, feature2: Feature):
	var path := []
	var target_rect = target_layer.get_used_rect()

	var position1 = feature1.get_center()
	var position2 = feature2.get_center()
	
	var point1 = Coords.get_astar_pos(position1.x, position1.y, target_rect.end.x)
	var point2 = Coords.get_astar_pos(position2.x, position2.y, target_rect.end.x)
	
	# print('connect ', point1, ' ', point2)
	
	var layer_width = target_rect.end.x

	var astar_empty = AStar2D.new()
	for cell in target_layer.get_used_cells():
		var p = Coords.get_astar_pos(cell.x, cell.y, layer_width)
		astar_empty.add_point(p, cell)
		for direction in Global.directions:
			var offset = cell + direction
			var p2 = Coords.get_astar_pos(offset.x, offset.y, layer_width)
			if astar_empty.has_point(p2):
				astar_empty.connect_points(p, p2)

	path = await astar_empty.get_point_path(point1, point2)

	var new_corridor = Corridor.new()
	new_corridor.set_cells(path)
	await _dig_feature(new_corridor)
	
	return path


func _remove_walls(layer: TileMapLayer):
	for cell in used_cells.keys():
		if layer.get_cell_atlas_coords(cell) == WALL_COORDS:
			_fill_in(layer, cell)


func _dig(cell: Vector2i, _tile: Vector2i):
	var layer_width = target_layer.get_used_rect().end.x
	used_cells[cell] = cell
	target_layer.set_cell(cell, 0, _tile)
	var point1 = Coords.get_astar_pos(cell.x, cell.y, layer_width)
	astar.add_point(point1, cell)
	for direction in Global.directions:
		var offset = cell + direction
		var point2 = Coords.get_astar_pos(offset.x, offset.y, layer_width)
		if astar.has_point(point2):
			astar.connect_points(point1, point2)


func _fill_in(layer: TileMapLayer, cell: Vector2i):
	used_cells.erase(cell)
	layer.set_cell(cell, 0, default_wall)
	var target_rect = layer.get_used_rect()
	var point1 = Coords.get_astar_pos(cell.x, cell.y, target_rect.end.x)
	if !astar.has_point(point1):
		return
	for dir in Global.directions:
		var offset = cell + dir
		var point2 = Coords.get_astar_pos(offset.x, offset.y, target_rect.end.x)
		if astar.has_point(point2):
			astar.disconnect_points(point1, point2)
	astar.remove_point(point1)


func _dig_feature(feature: Feature):
	tiles_dug += feature.cells.size()
	if feature.cells.size() == 0:
		return
	for cell in feature.cells:
		var _tile = default_ground
		if feature is Corridor:
			_tile = default_ground_corridor
		if feature is Cavern:
			_tile = default_ground_natural
		_dig(cell, _tile)

	features.append(feature)


func _remove_dead_ends(layer: TileMapLayer, __generation_speed := 0):
	var filled_cells = 0

	for cell in target_layer.get_used_cells():
		if !_is_wall(cell):
			var surrounding = layer.get_surrounding_cells(cell)
			var solid_neighbours = surrounding.filter(func(_cell): return _is_wall(_cell))
			if solid_neighbours.size() >= 3:
				_fill_in(layer, cell)
				filled_cells += 1
		else:
			var surrounding = layer.get_surrounding_cells(cell)
			var solid_neighbours = surrounding.filter(func(_cell): return _is_wall(_cell))
			if solid_neighbours.size() == 0:
				_dig(cell, default_ground_corridor)
				filled_cells += 1
	
	if filled_cells > 0:
		if __generation_speed > 0:
			await Global.sleep(30 / __generation_speed)
		await _remove_dead_ends(layer, __generation_speed)


func _connect_features(target_layer: TileMapLayer, is_solid: Callable, dig: Callable):
	var connecting_walls = MapGen.get_connecting_walls(target_layer, is_solid)

	connecting_walls.shuffle()
	
	for wall in connecting_walls:
		_check_wall(wall)


func _check_wall(wall: Dictionary):
	var target_rect = target_layer.get_used_rect()
	var position1 = Vector2i(wall.adjoining[0].x, wall.adjoining[0].y)
	var position2 = Vector2i(wall.adjoining[1].x, wall.adjoining[1].y)
	var point1 = Coords.get_astar_pos(position1.x, position1.y, target_rect.end.x)
	var point2 = Coords.get_astar_pos(position2.x, position2.y, target_rect.end.x)
	var feature1 = _get_feature_at(position1)
	var feature2 = _get_feature_at(position2)
	
	var will_break = false
		
	if feature1 is Corridor and feature2 is Corridor:
		# TODO: merge them into one corridor immediately
		if feature1 != feature2:
			feature1.cells += feature2.cells
			features = features.filter(func(feature): return feature != feature2)
			# print('merge corridors')
		will_break = true
	
	if astar.has_point(point1) and astar.has_point(point2):
		var path = astar.get_point_path(point1, point2)

		if path.size() == 0 or path.size() > 20:
			will_break = true

	if will_break:
		_dig(wall.cell, default_ground_corridor)


func _make_digger(coord: Vector2i, direction: Vector2i, life: int) -> Digger:
	return Digger.new(
		coord,
		direction,
		1,
		life,
		_can_dig,
		func(__cell): _dig(__cell, default_ground_corridor)
	)


func _dig_off_of(_feature: Feature, _position := Vector2i(-1,-1)):
	var digger: Digger
	
	if !_position:
		return null

	for dir in _feature.faces.keys():
		var faces = _feature.faces[dir]
		faces.shuffle()
		for face in faces:
			if _lookahead(target_layer, face, dir, 4) > 4:
				_dig(face, default_ground_corridor)
				digger = _make_digger(
					face + dir,
					dir,
					randi_range(6, 16)
				)
				diggers.append(digger)
				return digger
		
	return null


func _lookahead(layer: TileMapLayer, position: Vector2i, direction: Vector2i, length: int):
	for i in length + 1:
		if _can_dig(position):
			for ii in range(3):
				var to_check = position + direction * i
				if ii == 0:
					to_check += Vector2i.UP if direction.x != 0 else Vector2i.LEFT
				if ii == 2:
					to_check += Vector2i.DOWN if direction.x != 0 else Vector2i.RIGHT
				if _can_dig(to_check) == false:
					return i
		else:
			return 0
	return length + 1
	
	
func _digger_finished(digger: Digger):
	var new_corridor = Corridor.new()
	new_corridor.set_cells(digger.cells)
	# print('digger finished corridor ', new_corridor)
	_dig_feature(new_corridor)
	if randi_range(0, 100) < 40:
		pass # _dig_off_of(new_corridor)
	return new_corridor
	

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
		_dig(cell, default_ground_corridor)


func _is_solid(cell: Vector2i):
	return !used_cells.has(cell)


func _is_wall(cell: Vector2i):
	return _is_solid(cell) or target_layer.get_cell_atlas_coords(cell) == WALL_COORDS
	


func _place_feature(_feature: Feature, _accrete: Feature = null) -> Feature:
	if features.size() == 0:
		return null

	if _accrete != null:
		if _find_valid_accretion(_feature, _accrete) != null:
			return _feature
		return null

	var allowed_accretion = features
	if randi_range(0, 100) < 50:
		# Restrict it to corridors only
		allowed_accretion = allowed_accretion.filter(
			func(f):
				return f is Corridor
		)

	var feature_queue := []
	feature_queue.append_array(allowed_accretion)
	feature_queue.shuffle()
	
	for item in feature_queue:
		var new_location = _find_valid_accretion(_feature, item)
		if new_location.keys().size() > 0:
			# print('success! checked ', places_checked)
			return _feature
	# print('failure. checked ', places_checked)
	return null


func _find_valid_accretion(_feature: Feature, _accrete: Feature) -> Dictionary:
	# Find a valid place to put the room in our workspace
	# All cells already defined on the target layer, for checking overlaps
	var valid_location = MapGen.accrete(_accrete, _feature, used_cells, target_layer.get_used_rect())
	if valid_location:
		# Adds a one-tile corridor between rooms
		_feature.exits.append(valid_location.exit)
		_dig(valid_location.exit, default_ground_corridor)
		# Sets the cells to the new offset
		_feature.set_cells(_feature.cells.map(func(_cell): return _cell + valid_location.offset))

	return valid_location


func _make_room(bounds := Vector2i(10, 10)) -> Feature:
	workspace.clear()
	var new_room = Room.new()
	
	var _cells := []
	var size = Vector2i(
		randi_range(2, min(8, bounds.x)),
		randi_range(2, min(8, bounds.y))
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
