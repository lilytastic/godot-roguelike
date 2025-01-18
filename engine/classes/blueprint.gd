class_name Blueprint

var id: String
var name: String
var parent: String
var glyph: Glyph

func _init(props: Dictionary):
	id = props.get("id")
	name = props.get("name", id)
	parent = props.get("parent", "")
	glyph = Glyph.new(props.get("glyph", {}))
	return
