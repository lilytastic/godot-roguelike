extends Node2D

static var fast_noise_lite = FastNoiseLite.new();

var _fov_map := {}
var last_position: Vector2

var tiles := {}


func _ready() -> void:
	get_viewport().connect("size_changed", render)
	_create_tiles()
	
	MapManager.map_changed.connect(
		func(map):
			print('map changed!')
			await Global.sleep(1)
			_create_tiles()
	)
	
func _process(delta):
	render()

func _create_tiles() -> void:
	for child in get_children():
		child.free()
		
	if !MapManager.current_map:
		return

	var current_map = MapManager.current_map
	for x in range(current_map.size.x):
		for y in range(current_map.size.y):
			var position = Vector2i(x, y)
			# var position_str = str(position)
			if !current_map.tiles.has(position) or !current_map.tiles[position].size():
				var tile = generate_tile(current_map.default_tile, position)
				if tile:
					add_child(tile)
			else:
				for _id in MapManager.current_map.tiles[position]:
					var tile = generate_tile(_id, position)
					if tile:
						add_child(tile)


func render() -> void:
	if !MapManager.current_map:
		return

	var current_map = MapManager.current_map
	for x in range(current_map.size.x):
		for y in range(current_map.size.y):
			var position = Vector2i(x, y)
			if tiles.has(position):
				tiles[position].visible = AIManager.can_see(Global.player, position)


func generate_tile(id: String, position: Vector2i) -> Sprite2D:
	var spr = Sprite2D.new()
	spr.position = Coords.get_position(position) + Vector2(8, 8)
	var atlas = AtlasTexture.new()
	atlas.set_atlas(Glyph.tileset)
	var data = MapManager.get_tile_data(id)
	var coords = MapManager.get_atlas_coords_for_id(id)
	if coords == Vector2.ZERO:
		return null
	atlas.set_region(Rect2(coords.x * 16, coords.y * 16, 16, 16))
	spr.texture = atlas
	spr.z_index = -1
	var _noise = fast_noise_lite.get_noise_2d(position.x * 20, position.y * 20)
	var col = Color(_noise, _noise, _noise) / 8
	spr.modulate = data.get('color', Color.WHITE) + col
	tiles[position] = spr
	return spr
