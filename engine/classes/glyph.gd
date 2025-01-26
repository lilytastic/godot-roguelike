class_name Glyph

var ch: String
var fg: Color
var bg: Color

func _init(props: Dictionary) -> void:
	ch = props.get("ch", '')
	if props.has('fg'):
		fg = Color(
			props.fg[0] / 255,
			props.fg[1] / 255,
			props.fg[2] / 255
		)
	if props.has('bg'):
		bg = Color(
			props.bg[0] / 255,
			props.bg[1] / 255,
			props.bg[2] / 255
		)

func to_atlas_texture() -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.set_atlas(tileset)
	atlas.region = get_atlas_region(ch)
	return atlas

static var tileset = preload('res://assets/KenneyRoguelike/monochrome-transparent_packed.png')

static func get_atlas_region(_ch: String) -> Rect2:
	var rect := Rect2(0, 0, 16, 16)
	match _ch:
		'G_SWORD':
			rect = Rect2(32 * 16, 7 * 16, 16, 16)
		'G_DAGGER':
			rect = Rect2(32 * 16, 6 * 16, 16, 16)
		'G_GREATSWORD':
			rect = Rect2(32 * 16, 8 * 16, 16, 16)
		'G_AXE':
			rect = Rect2(41 * 16, 8 * 16, 16, 16)
		'G_HERO':
			rect = Rect2(27 * 16, 0 * 16, 16, 16)
		'G_HUMAN':
			rect = Rect2(25 * 16, 0 * 16, 16, 16)
		'G_GOBLIN':
			rect = Rect2(25 * 16, 1 * 16, 16, 16)
		'G_HELMET':
			rect = Rect2(33 * 16, 0 * 16, 16, 16)
		'G_ARMOR':
			rect = Rect2(34 * 16, 1 * 16, 16, 16)
		'G_CLOAK':
			rect = Rect2(38 * 16, 1 * 16, 16, 16)
		'G_GLOVES':
			rect = Rect2(41 * 16, 1 * 16, 16, 16)
		'G_BOOTS':
			rect = Rect2(39 * 16, 1 * 16, 16, 16)
		'G_AMULET':
			rect = Rect2(44 * 16, 7 * 16, 16, 16)
		'G_RING':
			rect = Rect2(45 * 16, 6 * 16, 16, 16)
		'G_RING_ALT':
			rect = Rect2(44 * 16, 6 * 16, 16, 16)
	return rect
