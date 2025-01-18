class_name Glyph

var ch: String
var fg: Array
var bg: Array

func _init(props: Dictionary):
	ch = props.get("ch", '')
	fg = props.get("fg", [])
	bg = props.get("bg", [])
