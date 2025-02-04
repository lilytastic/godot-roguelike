extends Node

var maps_loaded: Dictionary = {}

var maps := {}
var map := -1
var current_map: Map:
	get:
		return maps[map] if maps.has(map) else null
	set(value):
		map = value.id
		
var actors := {}

var map_view: MapView = null

var navigation_map = AStar2D.new()


func _ready() -> void:
	ECS.entity_added.connect(
		func(entity: Entity):
			if map and entity.location and entity.location.map == map:
				actors[entity.uuid] = entity
	)
	pass

func _process(delta) -> void:
	PlayerInput.update_cursor(actors)
	
	for actor in actors:
		if !ECS.entity(actor):
			actors.erase(actor)

func get_save_data() -> Dictionary:
	var _maps := {}
	for map in maps.values():
		_maps[map.id] = {
			'id': map.id,
			'name': map.name
		}
	return {
		'maps_loaded': maps_loaded,
		'maps': _maps
	}

func is_current_map(_id: int) -> bool:
	return map != -1 and _id == map
	
func add(_map: Map) -> Map:
	if !maps.has(_map.id):
		print('adding map: ', _map.name, ' (', _map.id, ')')
		maps[_map.id] = _map
	return _map

func switch_map(_map: Map, switch_to := true):
	add(_map)

	map = _map.id
	if !current_map:
		return

	print('Switched to map: ', current_map.name, ' (', current_map.id, ')')

	actors = {}
	# print('[ecs] entities: ', ECS.entities.keys())
	
	var entities = ECS.entities.values().filter(
		func(entity):
			# print(entity.blueprint.name, ': ', entity.location.map if entity.location else '')
			if !entity.location: return false
			return is_current_map(entity.location.map)
	)
	
	for entity in entities:
		actors[entity.uuid] = entity

func update_tiles():
	for tile in navigation_map.get_point_ids():
		if navigation_map.has_point(tile):
			navigation_map.set_point_disabled(
				tile,
				false
			)
	
	for actor in actors.values():
		if actor and actor.location and actor.blueprint.equipment:
			var pos = actor.location.position
			navigation_map.set_point_disabled(
				MapManager.map_view.get_astar_pos(pos.x, pos.y),
				true
			)
