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

var navigation_map = AStar2D.new()

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
		_maps.append({
			'uuid': _map.uuid,
			'name': _map.name,
			'tiles': _map.tiles,
			'size': _map.size
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

func create_map(_map_name: String, data := {}):
	var cell = load('res://cells/test.tscn')
	var packed_scene = cell.instantiate()
	var tile_pattern = null
	var actors := []
	for child in packed_scene.get_children():
		if child is TileMapLayer:
			tile_pattern = child.get_pattern(child.get_used_cells())
		for _child in child.get_children():
			if _child is Actor:
				actors.append(_child)

	var entities := []
	for actor in actors:
		var entity = Entity.init_from_node(actor)
		if entity:
			ECS.add(entity)
			entities.append(entity)

	packed_scene.queue_free()
	
	var tiles := {}
	
	for tile in tile_pattern.get_used_cells():
		var atlas_coords = tile_pattern.get_cell_atlas_coords(tile)
		var _id = get_tile_id_from_atlas_coords(atlas_coords)
		if !tiles.has(_id):
			tiles[_id] = []
		tiles[_id].append(tile)

	var _map = Map.new(_map_name, {
		'tiles': tiles,
		'size': tile_pattern.get_size(),
		'default_tile': 'soil'
	})
	
	tiles.erase('void')

	for entity in entities:
		entity.location.map = _map.uuid

	return _map

var tiles = {
	'void': {
		'atlas_coords': Vector2(0, 0)
	},
	'tree': {
		'atlas_coords': Vector2(4, 2),
		'color': Color('387a17')
	},
	'wildgrass': {
		'atlas_coords': Vector2(0, 2),
		'color': Color('697a17')
	}
}
func get_tile_id_from_atlas_coords(coords: Vector2):
	var valid = tiles.keys().filter(func(id): return tiles[id].get('atlas_coords', Vector2(0,0)) == coords)
	if valid.size() > 0:
		return valid[0]
	return 'void'

func get_tile_data(id: String):
	return tiles[id]

func get_atlas_coords_for_id(id: String):
	return tiles[id].get('atlas_coords', Vector2(0, 0))

func switch_map(_map: Map, switch_to := true):
	add(_map)

	map = _map.uuid
	if !current_map:
		return

	_init_navigation_map()
	print('Switched to map: ', current_map.name, ' (', current_map.uuid, ')')
	print('size: ', current_map.size)
	map_changed.emit(map)

	init_actors()
	
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
				get_astar_pos(pos.x, pos.y),
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
	var size = current_map.size
	var width = size.x
	return x + width * y

func can_walk(position: Vector2i):
	var size = current_map.size
	if position.x < 0 or position.x >= size.x or position.y < 0 or position.y >= size.y:
		return false

	var cell_data = current_map.tiles.keys().filter(
		func(key):
			return current_map.tiles[key].any(func(pos): return pos == position)
	)
	# TODO: Check if solid
	if cell_data.find('tree') != -1:
		return false

	return true


func _init_navigation_map():
	var width = current_map.size.x
	var height = current_map.size.y
	for x in range(width):
		for y in range(height):
			var pos = get_astar_pos(x, y)
			var vec = Vector2(x, y)
			
			if MapManager.can_walk(vec):
				MapManager.navigation_map.add_point(pos, vec)
			if MapManager.navigation_map.has_point(pos):
				for i: StringName in InputTag.MOVE_ACTIONS:
					var offset = Vector2i(x, y) + PlayerInput._input_to_direction(i)
					var point = get_astar_pos(offset.x, offset.y)
					if offset.x < 0 or offset.x > width - 1:
						continue
					if offset.y < 0 or offset.y > height - 1:
						continue
					if MapManager.navigation_map.has_point(point):
						MapManager.navigation_map.connect_points(
							pos,
							point
						)
						
