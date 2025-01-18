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

static func to_atlas_texture() -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.set_atlas(preload('res://monochrome-transparent_packed.png'))
	atlas.region = Rect2(432, 0, 16, 16)
	return atlas
