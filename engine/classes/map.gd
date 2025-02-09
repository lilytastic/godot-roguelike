class_name Map

const uuid_util = preload('res://addons/uuid/uuid.gd')

var uuid := ''
var name := ''
var tiles := {}
var seed = 0
var prefab = ''
var size := Vector2(0,0)
var neighbours := [] # TODO: Neighbouring cells, particularly for exteriors.
var default_tile = 'void'

var navigation_map = AStar2D.new()


func _init(_map_name: String, data := {}) -> void:
	uuid = data.get('uuid',  uuid_util.v4())
	name = _map_name
	prefab = data.get('prefab', 'test')
	default_tile = data.get('default_tile', 'void')
	
	_init_prefab(prefab, data.get('include_entities', false))

	seed = data.get('seed', randi())

	print('tiles: ', tiles)
	print('size: ', size)
	# TODO: Set default tile to the most frequent tile in the array


func _init_prefab(prefab: String, include_entities = false):
	var cell = load('res://cells/' + prefab + '.tscn')
	var packed_scene = cell.instantiate()
	var tile_pattern = null
	var actors := []
	
	if packed_scene is MapPrefab:
		default_tile = packed_scene.default_tile
	
	for child in packed_scene.get_children():
		if child is TileMapLayer:
			tile_pattern = child.get_pattern(child.get_used_cells())
		for _child in child.get_children():
			if _child is Actor:
				actors.append(_child)

	if include_entities:
		var entities := []
		for actor in actors:
			var entity = Entity.init_from_node(actor)
			if entity:
				ECS.add(entity)
				entities.append(entity)
		for entity in entities:
			entity.location.map = uuid

	packed_scene.queue_free()
	
	size = tile_pattern.get_size()
	
	for tile in tile_pattern.get_used_cells():
		var atlas_coords = tile_pattern.get_cell_atlas_coords(tile)
		var _id = get_tile_id_from_atlas_coords(atlas_coords)
		if _id != default_tile:
			if !tiles.has(_id):
				tiles[tile] = []
			tiles[tile].append(_id)
	
	print(tiles)
	_init_navigation_map()

func get_tile_id_from_atlas_coords(coords: Vector2):
	var valid = MapManager.tile_data.keys().filter(
		func(id):
			return MapManager.tile_data[id].get('atlas_coords', Vector2(0,0)) == coords
	)
	if valid.size() > 0:
		return valid[0]
	return default_tile
	
func get_astar_pos(x, y) -> int:
	var width = size.x
	return x + width * y
	
func tiles_at(position: Vector2i):
	return tiles.get(position, [])

func can_walk(position: Vector2i):
	if position.x < 0 or position.x >= size.x or position.y < 0 or position.y >= size.y:
		return false
	
	return !tiles_at(position).any(
		func(id):
			return MapManager.tile_data[id].get('is_solid', false)
	)

func _init_navigation_map():
	navigation_map.clear()
	var width = size.x
	var height = size.y
	for x in range(width):
		for y in range(height):
			var pos = get_astar_pos(x, y)
			var vec = Vector2(x, y)

			if can_walk(vec):
				navigation_map.add_point(pos, vec)
				for i: StringName in InputTag.MOVE_ACTIONS:
					var offset = Vector2i(x, y) + PlayerInput._input_to_direction(i)
					var point = get_astar_pos(offset.x, offset.y)
					if offset.x < 0 or offset.x > width - 1:
						continue
					if offset.y < 0 or offset.y > height - 1:
						continue
					if navigation_map.has_point(point):
						navigation_map.connect_points(
							pos,
							point
						)
						

func get_save_data():
	return {
		'uuid': uuid,
		'name': name,
		'prefab': prefab,
		'seed': seed,
		'default_tile': default_tile,
		'size': size
	}

static func load_from_data(data: Dictionary) -> Map:
	print('load map from data: ', data)
	return Map.new(data.name, data)
