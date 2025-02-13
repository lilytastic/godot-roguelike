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

signal map_changed
signal entity_moved
signal actors_changed


func _ready() -> void:
	ECS.entity_added.connect(
		func(entity: Entity):
			if map and entity.location and entity.location.map == map:
				actors[entity.uuid] = entity
				actors_changed.emit()
	)
	entity_moved.connect(
		func(uuid: String):
			var entity = ECS.entity(uuid)
			if map and entity.location and entity.location.map == map:
				actors[uuid] = entity
				actors_changed.emit()
	)
	pass

func _process(delta) -> void:
	for actor in actors:
		if !ECS.entity(actor):
			actors.erase(actor)
	update_navigation()


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

func create_map(_map_name: String, data := {}):
	var prefab = data.get('prefab', 'test')

	if !prefab:
		print('no prefab found; not creating map')
		return null

	var _map = await Map.new(_map_name, {
		'prefab': prefab,
		'include_entities': true,
		'default_tile': 'soil'
	})

	return _map

var tile_data = {
	'void': {
		'atlas_coords': Vector2(0, 0)
	},
	'rough stone': {
		'atlas_coords': Vector2(2, 0),
		'color': Color('aaaaaa'),
		'is_solid': true
	},
	'rough stone floor': {
		'atlas_coords': Vector2(6, 13),
		'color': Color('444444'),
	},
	'stone floor': {
		'atlas_coords': Vector2(10, 17),
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

func get_tile_data(id: String):
	return tile_data[id]

func get_atlas_coords_for_id(id: String):
	return tile_data[id].get('atlas_coords', Vector2(0, 0))

func switch_map(_map: Map):
	is_switching = true
	add(_map)
	
	print('Switching to map: ', _map.name)
	await _map.init_prefab()
	print('Finished initiating prefab for map: ',  _map.name)

	map = _map.uuid
	if !current_map:
		return
	print('Switched to map: ', current_map.name, ' (', current_map.uuid, ')')
	print('size: ', current_map.size)
	map_changed.emit(map)

	init_actors()
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
	actors_changed.emit()


func update_navigation():
	if !navigation_map:
		return

	for point in navigation_map.get_point_ids():
		if navigation_map.has_point(point):
			navigation_map.set_point_disabled(
				point,
				!can_walk(navigation_map.get_point_position(point))
			)

	for actor in actors.values():
		if actor and actor.location and AIManager.blocks_entities(actor):
			var pos = get_astar_pos(actor.location.position.x, actor.location.position.y)
			if navigation_map.has_point(pos):
				navigation_map.set_point_disabled(
					pos,
					true
				)

func get_collisions(position: Vector2):
	return actors.values().filter(
		func(_entity):
			return AIManager.blocks_entities(_entity)
	).filter(
		func(_entity):
			return _entity.location.position.x == position.x and _entity.location.position.y == position.y
	)

func get_astar_pos(x, y) -> int:
	return current_map.get_astar_pos(x, y)

func can_walk(position: Vector2i):
	if current_map:
		return current_map.can_walk(position)
	return true
