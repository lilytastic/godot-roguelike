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
	atlas.set_atlas(preload('res://assets/KenneyRoguelike/monochrome-transparent_packed.png'))
	var rect = Rect2(0, 0, 16, 16)
	match ch:
		'G_SWORD':
			rect = Rect2(32 * 16, 7 * 16, 16, 16)
		'G_AXE':
			rect = Rect2(41 * 16, 8 * 16, 16, 16)
		'G_HERO':
			rect = Rect2(27 * 16, 0 * 16, 16, 16)
		'G_HUMAN':
			rect = Rect2(25 * 16, 0 * 16, 16, 16)
		'G_GOBLIN':
			rect = Rect2(25 * 16, 1 * 16, 16, 16)
	atlas.region = rect
	return atlas
