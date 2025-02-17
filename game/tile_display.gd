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
	if Global.player and Global.player.location and Global.player.location.position != last_position:
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
				_create_tile_for_position(position)


func _create_tile_for_position(position: Vector2i):
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
	
	var _center := get_viewport().get_camera_2d().get_screen_center_position()
	var _rect := get_viewport().get_camera_2d().get_viewport_rect()
	_rect.position = _center - _rect.size / 2
	_rect.position -= Vector2.ONE * 16
	_rect.size += Vector2.ONE * 32

	for x in range(current_map.size.x):
		for y in range(current_map.size.y):
			var position = Vector2i(x, y)
			if !tiles.has(position):
				_create_tile_for_position(position)
			if tiles.has(position) and is_instance_valid(tiles[position]):
				tiles[position].visible = _rect.has_point(position * 16)
				
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
	
	if data.has('bg'):
		var _bg_color = data.get('bg', Color.WHITE)
		var _bg = Sprite2D.new()
		var _atlas = AtlasTexture.new()
		_atlas.set_atlas(Glyph.tileset)
		_atlas.set_region(Rect2(8 * 16, 5 * 16, 16, 16))
		_bg.texture = _atlas
		_bg.z_index = -1
		_bg.modulate = _bg_color
		spr.add_child(_bg)
	
	var _noise = fast_noise_lite.get_noise_2d(position.x * 20, position.y * 20)
	var col = Color(_noise, _noise, _noise) / 8
	spr.modulate = Color(data.get('color', Color.WHITE) + col, 0)

	tiles[position] = spr
	return spr
