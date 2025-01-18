class_name Blueprint

var id: String
var name: String
var parent: String
var type: String
var glyph: Glyph
var storage: StorageProps

func _init(props: Dictionary):
	id = props.get('id')
	name = props.get('name', id)
	parent = props.get('parent', '')
	type = props.get('type', '') if props.has('type') else 'unknown'
	glyph = Glyph.new(props.get('glyph', null)) if props.has('glyph') else null
	storage = StorageProps.new(props.get('storage')) if props.has('storage') else null
	return

func concat(parent: Blueprint):
	glyph = glyph if glyph else parent.glyph
	type = type if type != 'unknown' else parent.type
	storage = storage if storage else parent.storage
	return
