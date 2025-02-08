extends Node2D

static var fast_noise_lite = FastNoiseLite.new();

var _fov_map := {}
var last_position: Vector2


func _ready() -> void:
	get_viewport().connect("size_changed", render)
	render()
	
func _process(delta):
	if last_position != Global.player.location.position:
		last_position = Global.player.location.position
		render()


func render() -> void:
	for child in get_children():
		child.free()
		
	if !MapManager.current_map:
		return

	for position in MapManager.current_map.tiles.keys():
		for _id in MapManager.current_map.tiles[position]:
			add_child(generate_tile(_id, Global.string_to_vector(position)))


func generate_tile(id: String, position: Vector2) -> Sprite2D:
	var spr = Sprite2D.new()
	spr.position = Coords.get_position(position) + Vector2(8, 8)
	var atlas = AtlasTexture.new()
	atlas.set_atlas(Glyph.tileset)
	var data = MapManager.get_tile_data(id)
	var coords = MapManager.get_atlas_coords_for_id(id)
	atlas.set_region(Rect2(coords.x * 16, coords.y * 16, 16, 16))
	spr.texture = atlas
	spr.z_index = -1
	var _noise = fast_noise_lite.get_noise_2d(position.x * 20, position.y * 20)
	var col = Color(_noise, _noise, _noise) / 8
	spr.modulate = data.get('color', Color.WHITE) + col
	return spr
