extends Node2D

static var fast_noise_lite = FastNoiseLite.new();

var _fov_map := {}
var last_position: Vector2

var tiles := {}
var tile_render := {}

var is_dirty = false

var current_preview := {}

func _ready() -> void:
	get_viewport().connect("size_changed", render)
	_create_tiles()
	is_dirty = true
	
	PlayerInput.preview_updated.connect(
		func(preview):
			print("Preview updated: ", preview)
			current_preview = preview
			is_dirty = true
	)
	
	Global.player.action_performed.connect(
		func(action, result):
			current_preview.clear()
			await Global.sleep(100)
			is_dirty = true
	)
	
	MapManager.map_changed.connect(
		func(map):
			await Global.sleep(1)
			_create_tiles()
			is_dirty = true
	)


func _process(delta):
	if Global.player and Global.player.location and Global.player.location.position != last_position:
		last_position = Global.player.location.position
		# await Global.sleep(100)
		is_dirty = true
	if is_dirty:
		update_tiles()
		is_dirty = false
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

	for position in tiles.keys():
		if !is_instance_valid(tiles[position]):
			continue
		var _is_visible = _rect.has_point(position * 16)
		tiles[position].visible = _is_visible

		if !_is_visible or !tile_render.has(position):
			pass # return

		var _render_data = tile_render[position]
		# var _render_color = Color(_render_data.color, _render_data.opacity)
		tiles[position].modulate = tiles[position].modulate.lerp(
			Color(Color.WHITE, _render_data.opacity),
			delta * 8.0
		)
		var children = tiles[position].get_children()
		var fg = children[0]
		fg.modulate = fg.modulate.lerp(_render_data.color, delta * 8.0)
		var bg = null
		if children.size() > 1:
			bg = children[1]
			bg.modulate = bg.modulate.lerp(_render_data.bg, delta * 8.0)
		
		if current_preview.has(position):
			for effect in current_preview[position]:
				var actors_painted = 0
				for other in MapManager.get_collisions(position):
					if other.actor:
						actors_painted += 1
						other.actor.modulate = Color.BLACK
				fg.modulate = Color.BLACK
				if bg:
					bg.modulate = Color.RED
					


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
				
				var is_known = current_map.tiles_known.get(position, false)
				var _color = _tile_data.get('color', Color.WHITE) # tiles[position].modulate
				var _bg_color = _tile_data.get('bg', Color.WHITE) # tiles[position].modulate
				var _scattering = _tile_data.get('scattering', -1)
				var _opacity = 0.5
				if Global.player.visible_tiles.has(position): # _visible.get(position, false) # AgentManager.can_see(Global.player, position) and 
					_opacity = 1
				else:
					if is_known:
						_opacity = 0.15
					else:
						_opacity = 0.0

				var _noise = fast_noise_lite.get_noise_2d(position.x * 20, position.y * 20)
				var _noise2 = fast_noise_lite.get_noise_2d((position.x + 3000) * 50, (position.y + 3000) * 50)
				var col = Color(_noise, _noise, _noise) / 8
				var bg_col = Color(_noise, _noise, _noise) / 30
				
				if _scattering > 0 and _noise2 * 100 <= _scattering:
					_color = Color(0,0,0,0)
					tile_render[position].color = _color
				else:
					tile_render[position].color = _color + col
				tile_render[position].bg = _bg_color + bg_col
				tile_render[position].opacity = _opacity
				

				

func generate_tile(id: String, position: Vector2i) -> Node2D:
	var current_map = MapManager.current_map
	var tile_node = Node2D.new()
	var spr = Sprite2D.new()
	tile_node.add_child(spr)
	tile_node.position = Coords.get_position(position) + Vector2(8, 8)
	var atlas = AtlasTexture.new()
	atlas.set_atlas(Glyph.tileset)
	var data = MapManager.get_tile_data(id)
	var bg = Color(current_map.map_definition.get('default_color', 'FF0000')) if current_map.map_definition else Color('FF0000')
	data.bg = data.get('bg', bg)
	var coords = MapManager.get_atlas_coords_for_id(id)
	if coords == Vector2.ZERO:
		return null
	atlas.set_region(Rect2(coords.x * 16, coords.y * 16, 16, 16))
	spr.texture = atlas
	tile_node.z_index = -1
	tile_node.modulate = Color(Color.WHITE, 0)
	
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
