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

var map_view: MapView = null
var navigation_map = AStar2D.new()

signal map_changed


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
	var _maps := []
	for _map in maps.values():
		_maps.append({
			'uuid': _map.uuid,
			'name': _map.name
		})
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

func switch_map(_map: Map, switch_to := true):
	add(_map)

	map = _map.uuid
	if !current_map:
		return

	print('Switched to map: ', current_map.name, ' (', current_map.uuid, ')')
	map_changed.emit(map)

	actors = {}
	# print('[ecs] entities: ', ECS.entities.keys())
	
	var entities = ECS.entities.values().filter(
		func(entity):
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
