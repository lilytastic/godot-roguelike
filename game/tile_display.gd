extends Node2D

static var fast_noise_lite = FastNoiseLite.new();

var _fov_map := {}
var last_position: Vector2

var tiles := {}
var tile_render := {}


func _ready() -> void:
	get_viewport().connect("size_changed", render)
	_create_tiles()
	update_tiles()
	
	Global.player.action_performed.connect(
		func(action, result):
			await Global.sleep(100)
			update_tiles()
	)
	
	MapManager.map_changed.connect(
		func(map):
			await Global.sleep(1)
			_create_tiles()
			update_tiles()
	)


func _process(delta):
	if Global.player and Global.player.location and Global.player.location.position != last_position:
		last_position = Global.player.location.position
		await Global.sleep(100)
		update_tiles()
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
	if !MapManager.current_map.tiles.has(position):
		return
	for _id in MapManager.current_map.tiles[position]:
		var tile = generate_tile(_id, position)
		if tile:
			add_child(tile)


func render(delta: float = 0) -> void:
	var current_map = MapManager.current_map
	var _center := get_viewport().get_camera_2d().get_screen_center_position()
	var _rect := get_viewport().get_camera_2d().get_viewport_rect()
	_rect.position = _center - _rect.size / 2
	_rect.position -= Vector2.ONE * 16
	_rect.size += Vector2.ONE * 32
	
	"""
	var _target_position = Vector2i(-1, -1)# (PlayerInput.mouse_position_in_world / 16)
	if PlayerInput.targeting.has_target():
		_target_position = Vector2i(PlayerInput.targeting.target_position())
	if Global.player.targeting.has_target():
		_target_position = Vector2i(Global.player.targeting.target_position())

	var path_to_cursor = Coords.get_point_line(
		Global.player.location.position,
		_target_position
	) if _target_position != Vector2i(-1, -1) else []
	"""

	for position in tiles.keys():
		if !is_instance_valid(tiles[position]):
			continue
		var _is_visible = _rect.has_point(position * 16)
		tiles[position].visible = _is_visible

		if !_is_visible or !tile_render.has(position):
			pass # return

		var _render_data = tile_render[position]
		var is_known = current_map.tiles_known.get(position, false)
		var _color = tile_render[position].tile_data.get('color', Color.WHITE) # tiles[position].modulate
		var _bg_color = tile_render[position].tile_data.get('bg', Color.WHITE) # tiles[position].modulate

		"""
		if path_to_cursor.find(Vector2(position)) != -1:
			_color = Color.RED # _color * 2
		"""
		var _opacity = 0.5
		if Global.player.visible_tiles.has(position): # _visible.get(position, false) # AgentManager.can_see(Global.player, position) and 
			_opacity = 1
		else:
			if is_known:
				_opacity = 0.15
			else:
				_opacity = 0.0
		# tiles[position].modulate = Color(_color, _opacity)
	
		var _noise = fast_noise_lite.get_noise_2d(position.x * 20, position.y * 20)
		var col = Color(_noise, _noise, _noise) / 8
		
		tile_render[position].color = _color + col
		tile_render[position].bg = _bg_color + col
		tile_render[position].opacity = _opacity
		
		_render_data = tile_render[position]
		# var _render_color = Color(_render_data.color, _render_data.opacity)
		tiles[position].modulate = tiles[position].modulate.lerp(
			Color(Color.WHITE, _render_data.opacity),
			delta * 8.0
		)
		var children = tiles[position].get_children()
		var spr = children[0]
		spr.modulate = spr.modulate.lerp(_render_data.color, delta * 8.0)
		if children.size() > 1:
			var bg = children[1]
			bg.modulate = bg.modulate.lerp(_render_data.bg, delta * 8.0)


func update_tiles() -> void:
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
			if !tiles.has(position):
				_create_tile_for_position(position)
			if tiles.has(position) and is_instance_valid(tiles[position]):
				var _tile_data = MapManager.get_tile_data(MapManager.current_map.tiles_at(position)[0])
				if !tile_render.has(position):
					tile_render[position] = {}
				tile_render[position].tile_data = _tile_data
				

func generate_tile(id: String, position: Vector2i) -> Node2D:
	var tile_node = Node2D.new()
	var spr = Sprite2D.new()
	tile_node.add_child(spr)
	tile_node.position = Coords.get_position(position) + Vector2(8, 8)
	var atlas = AtlasTexture.new()
	atlas.set_atlas(Glyph.tileset)
	var data = MapManager.get_tile_data(id)
	var coords = MapManager.get_atlas_coords_for_id(id)
	if coords == Vector2.ZERO:
		return null
	atlas.set_region(Rect2(coords.x * 16, coords.y * 16, 16, 16))
	spr.texture = atlas
	tile_node.z_index = -1
	# tile_node.modulate = Color(col, 0)
	
	if data.has('bg'):
		var _bg_color = data.get('bg', Color.WHITE)
		var _bg = Sprite2D.new()
		var _atlas = AtlasTexture.new()
		_atlas.set_atlas(Glyph.tileset)
		_atlas.set_region(Rect2(8 * 16, 5 * 16, 16, 16))
		_bg.texture = _atlas
		_bg.z_index = -1
		_bg.modulate = _bg_color
		tile_node.add_child(_bg)
	
	spr.modulate = data.get('color', Color.WHITE)

	tiles[position] = tile_node
	return tile_node
