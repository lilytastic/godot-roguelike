class_name Blueprint

var id: String
var name: String
var description: String
var parent: String
var type: String
var glyph: Glyph
var storage: StorageProps
var slots := []


func _init(props: Dictionary):
	id = props.get('id')
	name = props.get('name', id)
	parent = props.get('parent', '')
	description = props.get('description', '') if props.has('description') else ''
	type = props.get('type', '') if props.has('type') else 'unknown'
	glyph = Glyph.new(props.get('glyph', null)) if props.has('glyph') else null
	storage = StorageProps.new(props.get('storage')) if props.has('storage') else null
	slots = props.get('slots', []).map(
		func(slot): 
			if slot is Dictionary and slot.has('id'):
				return slot.id 
			return slot
	)
	return


func concat(parent: Blueprint):
	type = type if type != 'unknown' else parent.type
	description = description if description != '' else parent.description
	glyph = glyph if glyph else parent.glyph
	storage = storage if storage else parent.storage
	
	slots = slots if slots.size() > 0 else parent.slots
	
	return
