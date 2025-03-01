class_name Map

const uuid_util = preload('res://addons/uuid/uuid.gd')

var uuid := ''
var name := ''
var tiles := {}
var seed = 0
var depth = 0
var branch = ''
var prefab = ''
var connections := []
var size := Vector2(0,0)
var neighbours := [] # TODO: Neighbouring cells, particularly for exteriors.
var default_tile = 'void'
var map_definition = null

var is_loaded = false

var tiles_known := {} # The tiles the player knows about

var navigation_map = AStar2D.new()

var include_entities = false

var walkable_tiles: Array:
	get:
		return tiles.keys().filter(func(pos): return can_walk(pos))

var data := {}

func _init(_data := {}) -> void:
	data = _data
	uuid = data.get('uuid', uuid_util.v4())
	prefab = data.get('prefab', 'test')
	connections = data.get('connections', [])
	branch = data.get('branch', '')
	depth = data.get('depth', 0)
	
	map_definition = MapManager.map_definitions.get(branch, null)

	name = data.get('map', map_definition.name if map_definition else '<unnamed map>')
	default_tile = data.get('default_tile', 'void')

	var _tiles_known = data.get('tiles_known', [])
	for tile in _tiles_known:
		tiles_known[Global.string_to_vector(tile)] = true

	include_entities = data.get('include_entities', false)
	seed = data.get('seed', randi())

	print('size: ', size)


func init_prefab() -> void:
	print('Initializing prefab: ', prefab)
	if is_loaded:
		print('Bailing because this map is loaded already')
		return

	is_loaded = true
	var cell = load('res://cells/' + prefab + '.tscn')
	var packed_scene = cell.instantiate()
	var tile_pattern = null
	var actors := []
	
	if packed_scene is MapPrefab:
		default_tile = packed_scene.default_tile
	
	if packed_scene is MapGenerator:
		print('Found generator')
		default_tile = packed_scene.default_tile
		var result = await packed_scene.generate(seed, data)
		var features = result.get('features', [])
		var entities = result.get('entities', [])
		print('Add entities? ', include_entities)
		
		if include_entities:
			for entity in entities:
				entity.location.map = uuid
				entity.energy -= 100.0
				ECS.add(entity)

	for child in packed_scene.get_children():
		if child is TileMapLayer:
			print('tile map found: ', child)
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
		if !tiles.has(_id):
			tiles[tile] = []
		tiles[tile].append(_id)
	
	print(tiles.size())
	_init_navigation_map()
	return

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
		
	var tiles = tiles_at(position)
	
	return !tiles.any(
		func(id):
			var tile_data = MapManager.tile_data[id]
			return tile_data.get('is_solid', false)
	)

func _init_navigation_map():
	print('_init_navigation_map')
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

func get_tiles_at(position: Vector2i):
	return tiles.get(position, [])

func get_save_data():
	return {
		'uuid': uuid,
		'name': name,
		'prefab': prefab,
		'branch': branch,
		'depth': depth,
		'seed': seed,
		'default_tile': default_tile,
		'tiles_known': tiles_known.keys(),
		'size': size
	}

static func load_from_data(data: Dictionary) -> Map:
	print('load map from data: ', data)
	return await Map.new(data)
