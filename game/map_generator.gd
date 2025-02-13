class_name MapGenerator
extends MapPrefab

const DIGGER_COORDS := Vector2i(13, 4)
const ROOM_COORDS := Vector2i(13, 3)
const EXIT_COORDS := Vector2i(13, 2)
const WALL_COORDS := Vector2i(8, 5)
const CELLULAR_COORDS := Vector2i(1, 17)

var exits := []
var features := []

var default_ground = MapManager.tile_data['stone floor'].atlas_coords
var default_ground_corridor = MapManager.tile_data['rough stone floor'].atlas_coords
var default_wall = null

var diggers: Array[Digger] = []

@export var _generation_speed = 0

@export var template: TileMapLayer
@export var workspace: TileMapLayer
@export var target_layer: TileMapLayer

var directions = [Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT]

var tiles_dug = 0
var is_generating = true

var used_cells := {}

func _ready():
	pass
	
func generate(seed: int, generation_speed := 0):
	seed(seed)
	is_generating = true
	tiles_dug = 0
	features.clear()
	default_wall = MapManager.tile_data[default_tile].atlas_coords
	var rect = template.get_used_rect()
	
	await Global.sleep(1)
	
	var time_started = Time.get_ticks_msec()
	print('==== Map generation started ====')

	# Clear the map with with the default tile
	for x in range(rect.end.x):
		for y in range(rect.end.y):
			target_layer.set_cell(
				Vector2i(x, y),
				0,
				default_wall
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
				if generation_speed > 0:
					await Global.sleep(150 / generation_speed)
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

				if generation_speed > 0:
					await Global.sleep(300 / generation_speed)

				for cell in new_cells.keys():
					target_layer.set_cell(cell, 0, default_ground if new_cells[cell] == 1 else default_wall)
				
			var feature = Room.new()
			feature.set_cells(cells.filter(func(cell): return new_cells[cell] == 1))
			_dig_feature(feature)

			_clear(coord)

		if atlas_coords == WALL_COORDS:
			used_cells[coord] = coord
			target_layer.set_cell(coord, 0, WALL_COORDS)

	
	print(tiles_dug, ' tiles dug for initial features, of which there are ', features.size())
	
	var total_cells = rect.end.x * rect.end.y * 1.0
	var dug_percentage = tiles_dug / total_cells * 100.0
	var iterations = 0
	var previously_dug = tiles_dug
	while true:
		if iterations > 900:
			print('breaking loop; iterations > 900')
			break
		
		iterations += 1

		if generation_speed <= 0:
			await Global.sleep(1)
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
			if generation_speed > 0:
				await Global.sleep(30 / generation_speed)
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
			if generation_speed > 0:
				await Global.sleep(200 / generation_speed)

	print(tiles_dug, '/', total_cells, ' tiles dug (', snapped(dug_percentage, 0.1), '%)')
	
	var astar = _get_navigation_map(func(cell): return target_layer.get_cell_atlas_coords(cell) == Vector2i(default_wall))

	_connect_features(target_layer, astar, _is_solid, func(cell): _open_exit(cell))
	
	_remove_walls(target_layer)
	
	await _remove_dead_ends(target_layer, generation_speed)
	
	# await _connect_isolated_rooms(target_layer)
	
	workspace.free()
	template.free()
	var time_finished = Time.get_ticks_msec()
	print('==== Map generation complete ====')
	print('Time to generate: ', (time_finished - time_started) / 1000, 's')
	
	is_generating = false
	randomize()


func _connect_isolated_rooms(layer: TileMapLayer):
	var target_rect = layer.get_used_rect()
	var rooms = features.filter(func(feature): return feature is Room)
	rooms.shuffle()

	var astar = _get_navigation_map(
		func(cell):
			return false
	)
	
	for room in rooms:
		var room_center = room.get_center()
		if _is_solid(room_center):
			continue

		var closest_rooms = rooms.filter(func(r): return r != room)
		closest_rooms.shuffle()
		closest_rooms.sort_custom(
			func(a: Room, b: Room):
				if a.get_center().distance_to(room_center) < b.get_center().distance_to(room_center):
					return true
				return false
		)
		
		for other_room in closest_rooms:
			var other_center = other_room.get_center()
			if _is_solid(other_center):
				continue
			var point1 = Coords.get_astar_pos(room_center.x, room_center.y, target_rect.end.x)
			var point2 = Coords.get_astar_pos(other_center.x, other_center.y, target_rect.end.x)
			for p in astar.get_point_ids():
				astar.set_point_disabled(p, _is_solid(astar.get_point_position(p)))
			if astar.are_points_connected(point1, point2):
				continue
			var new_path = await _connect(room, other_room, astar)
			astar = _connect_adjacent_tiles(astar, new_path, _is_solid)
			


func _connect(feature1: Feature, feature2: Feature, astar: AStar2D):
	var path := []
	var target_rect = target_layer.get_used_rect()

	var position1 = feature1.get_center()
	var position2 = feature2.get_center()
	
	var point1 = Coords.get_astar_pos(position1.x, position1.y, target_rect.end.x)
	var point2 = Coords.get_astar_pos(position2.x, position2.y, target_rect.end.x)

	for p in astar.get_point_ids():
		astar.set_point_disabled(p, false)

	path = await astar.get_point_path(point1, point2)

	if path.size() <= 1:
		return path

	var new_corridor = Corridor.new()
	new_corridor.set_cells(path)
	_dig_feature(new_corridor)
	
	return path


func _remove_walls(layer: TileMapLayer):
	for cell in used_cells.keys():
		if layer.get_cell_atlas_coords(cell) == WALL_COORDS:
			_fill_in(layer, cell)

func _fill_in(layer: TileMapLayer, cell: Vector2i):
	used_cells.erase(cell)
	layer.set_cell(cell, 0, default_wall)

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
				_dig(cell, true)
				filled_cells += 1
	
	if filled_cells > 0:
		if __generation_speed > 0:
			await Global.sleep(30 / __generation_speed)
		await _remove_dead_ends(layer, __generation_speed)


func _connect_features(target_layer: TileMapLayer, astar: AStar2D, is_solid: Callable, dig: Callable):
	var target_rect = target_layer.get_used_rect()
	var connecting_walls = MapGen.get_connecting_walls(target_layer, is_solid)

	connecting_walls.shuffle()
	
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
				# print('merge corridors')
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
		func(__cell): _dig(__cell, true)
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
				_dig(face, true)
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


func _get_navigation_map(is_solid: Callable):
	var astar = AStar2D.new()
	var target_rect = target_layer.get_used_rect()
	var _cells = target_layer.get_used_cells()
	astar = _connect_adjacent_tiles(astar, _cells, is_solid)
	return astar


func _connect_adjacent_tiles(astar: AStar2D, cells: Array, is_solid: Callable):
	var target_rect = target_layer.get_used_rect()
	for cell in cells:
		var _cell = Vector2i(cell)
		if !is_solid.call(_cell):
			var point = Coords.get_astar_pos(cell.x, cell.y, target_rect.end.x)
			if !astar.has_point(point):
				astar.add_point(point, cell)
			for dir in directions:
				var offset = _cell + dir
				var point2 = Coords.get_astar_pos(offset.x, offset.y, target_rect.end.x)
				if point2 < 0 or cells.find(offset) == -1:
					continue
				if !is_solid.call(offset):
					if !astar.has_point(point2):
						astar.add_point(point2, offset)
					astar.connect_points(
						point,
						point2,
						true
					)
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
		_dig(cell, true)


func _is_solid(cell: Vector2i):
	return !used_cells.has(cell)
	# var wall_atlas_coords = Vector2i(MapManager.tile_data[default_tile].atlas_coords)
	# return target_layer.get_cell_atlas_coords(cell) == wall_atlas_coords


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
		_dig(valid_location.exit)
		# Sets the cells to the new offset
		_feature.set_cells(_feature.cells.map(func(_cell): return _cell + valid_location.offset))

	return valid_location

func _dig(cell: Vector2i, is_corridor := false):
	used_cells[cell] = cell
	target_layer.set_cell(cell, 0, default_ground_corridor if is_corridor else default_ground)

func _dig_feature(feature: Feature):
	tiles_dug += feature.cells.size()
	if feature.cells.size() == 0:
		return
	if feature is Room:
		# print('digging a new room with ', feature.cells.size(), ' cells')
		pass
	if feature is Corridor:
		# print('digging a new hallway with ', feature.cells.size(), ' cells')
		pass
	for cell in feature.cells:
		_dig(cell, feature is Corridor)

	features.append(feature)


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
