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

var tile_data = {
	'void': {
		'atlas_coords': Vector2(0, 0)
	},
	'rough stone': {
		'atlas_coords': Vector2(2, 0),
		'color': Color('aaaaaa'),
		'bg': Color('888888'),
		'is_solid': true
	},
	'rough stone floor': {
		'atlas_coords': Vector2(6, 13),
		'bg': Color('333333'),
		'color': Color('444444'),
	},
	'stone floor': {
		'atlas_coords': Vector2(10, 17),
		'bg': Color('333333'),
		'color': Color('444444'),
	},
	'tree': {
		'atlas_coords': Vector2(4, 2),
		'color': Color('387a17'),
		'is_solid': true
	},
	'soil': {
		'atlas_coords': Vector2(5, 0),
		'color': Color('2c5b14')
	},
	'wildgrass': {
		'atlas_coords': Vector2(0, 2),
		'color': Color('387a17')
	}
}

signal map_changed
signal entity_moved
signal actors_changed


func _ready() -> void:
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

	if !prefab:
		print('no prefab found; not creating map')
		return null

	var _map = await Map.new({
		'prefab': prefab,
		'include_entities': true,
		'default_tile': 'soil'
	})
	maps[_map.uuid] = _map
	await _map.init_prefab()

	return _map


func get_tile_data(id: String):
	return tile_data[id]

func get_atlas_coords_for_id(id: String):
	return tile_data[id].get('atlas_coords', Vector2(0, 0))

func switch_map(_map: Map, entity: Entity):
	is_switching = true
	add(_map)
	
	print('Switching to map: ', _map.name)
	PlayerInput.overlay_opacity = 3.0
	print('Finished initiating prefab for map: ',  _map.name)

	map = _map.uuid
	if !current_map:
		return
	print('Switched to map: ', current_map.name, ' (', current_map.uuid, ')')
	print('size: ', current_map.size)

	init_actors()
	
	if !entity.location or entity.location.map != _map.uuid:
		var starting_location = Vector2i(-1, -1)
		for actor in actors.values():
			if actor.destination:
				starting_location = Vector2i(actor.location.position)
		entity.location = Location.new(_map.uuid, starting_location if starting_location != Vector2i(-1, -1) else _map.walkable_tiles.pick_random())
		var camera = get_viewport().get_camera_2d()
		if camera:
			camera.position = entity.location.position * 16

	if !actors.has(entity.uuid):
		actors[entity.uuid] = entity
		entity.update_fov()

	map_changed.emit(map)
	is_switching = false


func get_tiles():
	var arr := []
	
	if !current_map:
		return arr
	
	return current_map.tiles

func init_actors():
	actors = {}
	# print('[ecs] entities: ', ECS.entities.keys())
	
	var entities = ECS.entities.values().filter(
		func(entity):
			if !entity.location: return false
			return is_current_map(entity.location.map)
	)
	
	for entity in entities:
		actors[entity.uuid] = entity
		entity.update_fov()
	print('[MapManager] actors: ', actors.keys().size())
	actors_changed.emit()


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
		if actor and actor.location and AIManager.blocks_entities(actor):
			var pos = get_astar_pos(actor.location.position.x, actor.location.position.y)
			if _navigation_map.has_point(pos):
				_navigation_map.set_point_disabled(
					pos,
					true
				)

func get_collisions(position: Vector2i):
	return actors.values().filter(
		func(_entity):
			return AIManager.blocks_entities(_entity)
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
