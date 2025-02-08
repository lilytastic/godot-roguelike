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

	for tile in MapManager.get_tiles():
		pass # add_child(generate_tile(tile))


func generate_tile(tile: Dictionary) -> Sprite2D:
	var spr = Sprite2D.new()
	var position = tile.get('position', Vector2(0,0))
	spr.position = Coords.get_position(position) + Vector2(8, 8)
	var atlas = AtlasTexture.new()
	atlas.set_atlas(Glyph.tileset)
	var coords = tile.get('atlas_coords', Vector2(0, 0))
	atlas.set_region(Rect2(coords.x * 16, coords.y * 16, 16, 16))
	spr.texture = atlas
	spr.z_index = -1
	var _noise = fast_noise_lite.get_noise_2d(position.x * 20, position.y * 20)
	var col = Color(_noise, _noise, _noise) / 8
	spr.modulate = tile.get('color', Color.WHITE) + col
	spr.name = str(tile)
	return spr
