extends Node

var maps_loaded: Dictionary = {}

var maps := {}
var map := ''
var current_map: Map:
	get:
		return maps[map] if maps.has(map) else null
	set(value):
		map = value.id
		
var actors := {}

var navigation_map:
	get: return current_map.navigation_map if current_map else null

var is_switching = false

var map_definitions = {
	'wilderness': {
		'name': "Wilderness",
		'is_interior': false,
		'prefabs': [ 'test' ]
	},
	'dungeon': {
		'name': "Dungeon",
		'is_interior': true
	},
	'cave': {
		'parent': 'dungeon'
	},
	'mine': {
		'parent': 'dungeon'
	},
	'fort': {
		'parent': 'dungeon'
	},
	'ruin': {
		'parent': 'dungeon'
	},
	'tomb': {
		'parent': 'dungeon',
		'encounters': [ 'ghoul' ],
		'prefabs': [ 'fort1' ]
	},
	'privateers_hideout': {
		'name': "Thief's Hideout",
		'parent': 'tomb',
		'max_depth': 3,
	}
}

var tile_data = {
	'void': {
		'atlas_coords': Vector2(0, 0)
	},
	'rough stone': {
		'atlas_coords': Vector2(2, 0),
		'color': Color('aaaaaa'),
		'bg': Color('666666'),
		'is_solid': true
	},
	'rough stone floor': {
		'atlas_coords': Vector2(6, 13),
		'bg': Color('111111'),
		'color': Color('444444'),
	},
	'stone floor': {
		'atlas_coords': Vector2(10, 17),
		'bg': Color('171717'),
		'color': Color('444444'),
	},
	'tree': {
		'atlas_coords': Vector2(4, 2),
		'color': Color('387a17'),
		'is_solid': true
	},
	'soil': {
		'atlas_coords': Vector2(5, 0),
		'color': Color('2c5b14'),
		'scattering': 30
	},
	'wildgrass': {
		'atlas_coords': Vector2(0, 2),
		'color': Color('387a17')
	},
	'scrub': {
		'atlas_coords': Vector2(1, 2),
		'color': Color('387a17')
	}
}

signal map_changed
signal entity_moved
signal actors_changed


func _ready() -> void:
	for key in map_definitions:
		var def = map_definitions.get(key, {});
		if def.has('parent'):
			map_definitions[key].merge(map_definitions.get(def.parent, {}), true)

	update_navigation()
	ECS.entity_added.connect(
		func(entity: Entity):
			if map and entity.location and entity.location.map == map:
				actors[entity.uuid] = entity
				update_navigation()
				actors_changed.emit()
	)
	entity_moved.connect(
		func(uuid: String):
			var entity = ECS.entity(uuid)
			if map and entity.location and entity.location.map == map:
				actors[uuid] = entity
				update_navigation()
				actors_changed.emit()
	)
	pass

func _process(delta) -> void:
	for actor in actors:
		if !ECS.entity(actor):
			actors.erase(actor)


func get_save_data() -> Dictionary:
	var _maps := []
	for _map in maps.values():
		_maps.append(_map.get_save_data())
	return {
		'maps_loaded': maps_loaded.keys(),
		'maps': _maps
	}

func is_current_map(_id: String) -> bool:
	return map != '' and _id == map
	
func add(_map: Map) -> Map:
	if !maps.has(_map.uuid):
		print('adding map: ', _map.name, ' (', _map.uuid, ')')
		maps[_map.uuid] = _map
	return _map


func create_map(data := {}) -> Map:
	var prefab = data.get('prefab', 'test')
	
	var _map_definition = map_definitions.get(data.get('branch', ''), null)
	print(_map_definition)
	if _map_definition:
		prefab = _map_definition.prefabs.pick_random()
		print('set prefab to ', prefab)

	if !prefab:
		print('no prefab found; not creating map')
		return null

	data['include_entities'] = true
	print('Creating map with data: ', data)
	var _map = await Map.new(data)
	maps[_map.uuid] = _map
	_map.prefab = prefab
	_map.name = data.get('name', _map.name)
	_map.connections = data.get('connections', [])
	_map.branch = data.get('branch', '')
	_map.depth = data.get('depth', 0)
	
	await _map.init_prefab()

	return _map


func get_tile_data(id: String):
	return tile_data[id]

func get_atlas_coords_for_id(id: String):
	return tile_data[id].get('atlas_coords', Vector2(0, 0))

func switch_map(_map: Map, entity: Entity):
	is_switching = true

	PlayerInput.overlay_opacity = 1.0
	await Global.sleep(1)
	add(_map)
	
	if !_map.is_loaded:
		await _map.init_prefab()
		print('Finished initiating prefab for map: ',  _map.name)

	print('Switching to map: ', _map.name)
	
	map = _map.uuid
	if !current_map:
		return
	print('Switched to map: ', current_map.name, ' (', current_map.uuid, ')')
	print('size: ', current_map.size)

	await init_actors()
	
	await Global.sleep(1)

	if !entity.location or entity.location.map != _map.uuid:
		var starting_location = _map.walkable_tiles.pick_random()
		print('looking for a starting location...')
		for actor in actors.values():
			if actor.blueprint.id == 'staircase' or actor.destination:
				print('staircase found: ', actor.location.position)
				starting_location = Vector2i(actor.location.position)
		entity.location = Location.new(_map.uuid, starting_location)

	if !actors.has(entity.uuid):
		actors[entity.uuid] = entity
		entity.update_fov()

	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.position = (entity.location.position + PlayerInput.camera_offset) * 16

	map_changed.emit(map)
	is_switching = false


func get_tiles():
	var arr := []
	
	if !current_map:
		return arr
	
	return current_map.tiles

func init_actors():
	actors = {}
	
	var entities = ECS.entities.values().filter(
		func(entity):
			if !entity.location: return false
			return is_current_map(entity.location.map)
	)
	
	for entity in entities:
		actors[entity.uuid] = entity
		entity.update_fov()
	print('[MapManager] init_actors, actors: ', actors.keys().size())
	actors_changed.emit()


func teleport(destination: Dictionary, entity: Entity):
	print('teleport to: ', destination)
	if destination.has('map'):
		var _map = maps[destination.map]
		switch_map(_map, entity)
		if destination.has('position'):
			var _position = Global.string_to_vector(destination.position)
			entity.location = Location.new(destination.map, _position)


func resolve_destination(destination: Dictionary, entity: Entity):
	var _destination = destination
	
	# If the destination goes to a set location, skip this.
	# Otherwise, we'll look for an existing map matching the destination's prefab (for procgen maps)
	if !_destination.has('map'):
		_destination = assign_destination(_destination)

	# None found for prefab -- so we'll have to generate the prefab.
	if !_destination.has('map'):
		_destination = await create_destination(_destination, entity)

	print('resolved destination: ', destination, ' as ', _destination)
	return _destination


func assign_destination(destination: Dictionary):
	var _destination = destination
	if _destination.has('prefab'):
		for _map in maps.values():
			if _map and _map.prefab == _destination['prefab']:
				_destination['map'] = _map.uuid
	if _destination.has('branch'):
		var _depth = _destination.get('depth', 1)
		for _map in maps.values():
			if _map and _map.branch == _destination['branch'] and (!_destination.has('depth') or _map.depth == _depth):
				_destination['map'] = _map.uuid
	return _destination
	

func create_destination(destination: Dictionary, entity: Entity = null) -> Dictionary:
	if !destination.has('connections'):
		destination['connections'] = [{ 'map': entity.location.map, 'position': entity.location.position }]
	var _map = await create_map(destination)
	var _entities = ECS.entities.values().filter(func(e): return e.location and e.location.map == _map.uuid)
	var _starting_position = Vector2i(-1, -1)
	for _entity in _entities:
		if _entity.destination or _entity.blueprint.id == 'staircase':
			_starting_position = _entity.location.position
			if entity and entity.location and !_entity.destination.has('position'):
				# Directly link this portal to wherever the teleported entity is
				_entity.destination.erase('prefab')
				_entity.destination['map'] = entity.location.map
				_entity.destination['position'] = entity.location.position
			break
	destination = {
		'map': _map.uuid,
		'position': _starting_position
	}
	return destination
	






func update_navigation():
	if !navigation_map:
		return
		
	var _navigation_map = navigation_map

	for point in _navigation_map.get_point_ids():
		if _navigation_map.has_point(point):
			_navigation_map.set_point_disabled(
				point,
				!can_walk(_navigation_map.get_point_position(point))
			)

	for actor in actors.values():
		if actor and actor.location and AgentManager.blocks_entities(actor):
			var pos = get_astar_pos(actor.location.position.x, actor.location.position.y)
			if _navigation_map.has_point(pos):
				_navigation_map.set_point_disabled(
					pos,
					true
				)

func get_collisions(position: Vector2i):
	return actors.values().filter(
		func(_entity):
			return AgentManager.blocks_entities(_entity)
	).filter(
		func(_entity):
			return _entity.location.position.x == position.x and _entity.location.position.y == position.y
	)
	
func get_collisions_line(position1: Vector2i, position2: Vector2i):
	var line = Coords.get_point_line(position1, position2)
	# print('line ', line)
	var collisions = []
	for position in line:
		var tiles = current_map.get_tiles_at(position)
		for id in tiles:
			var tile_data = MapManager.tile_data.get(id)
			# print(id, ' - ', tile_data)
			if tile_data and tile_data.get("is_solid", false):
				collisions.append(position)
	return collisions
	
func get_astar_pos(x, y) -> int:
	return current_map.get_astar_pos(x, y)

func can_walk(position: Vector2i):
	if current_map:
		return current_map.can_walk(position)
	return true
