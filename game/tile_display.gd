extends Node2D

static var fast_noise_lite = FastNoiseLite.new();

var _fov_map := {}
var last_position: Vector2

var tiles := {}


func _ready() -> void:
	get_viewport().connect("size_changed", render)
	_create_tiles()
	render()
	
	MapManager.map_changed.connect(
		func(map):
			print('map changed!')
			await Global.sleep(1)
			_create_tiles()
			render()
	)


func _process(delta):
	if Global.player and Global.player.location.position != last_position:
		last_position = Global.player.location.position
	render(delta)


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


func render(delta: float = 0) -> void:
	if !MapManager.current_map:
		return

	Global.player.update_fov()
	var player_location = Global.player.location.position
	var current_map = MapManager.current_map
	var walls_seen = {}
	var collision_dict = {}

	for x in range(current_map.size.x):
		for y in range(current_map.size.y):
			var position = Vector2i(x, y)
			if tiles.has(position):
				tiles[position].visible = true
				var is_known = current_map.tiles_known.get(position, false)
				var _color = tiles[position].modulate
				var _opacity = 1
				if Global.player.visible_tiles.has(position): # _visible.get(position, false) # AIManager.can_see(Global.player, position) and 
					# tiles[position].visible = true
					_opacity = 1
					# tiles[position].modulate = Color(tiles[position].modulate, 1)
				else:
					if is_known:
						# tiles[position].visible = true
						_opacity = 0.15
						# tiles[position].modulate = Color(tiles[position].modulate, 0.15)
					else:
						_opacity = 0.0
						# tiles[position].visible = false
				tiles[position].modulate = tiles[position].modulate.lerp(Color(_color, _opacity), delta * 12.0)


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
