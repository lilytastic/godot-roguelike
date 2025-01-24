class_name Blueprint

var id: String
var name: String
var description: String
var parent: String
var type: String
var glyph: Glyph
var item: ItemProps
var equipment: EquipmentProps
var speed := 0


func _init(props: Dictionary):
	id = props.get('id')
	name = props.get('name', id)
	parent = props.get('parent', '')
	description = props.get('description', '')
	type = props.get('type', 'unknown')
	speed = props.get('speed', 0)
	if props.has('glyph'):
		glyph = Glyph.new(props.glyph)
	if props.has('wearable') or props.has('storage'):
		item = ItemProps.new(props)
	if props.has('slots'):
		equipment = EquipmentProps.new(props)
	return


func concat(parent: Blueprint):
	type = type if type != 'unknown' else parent.type
	description = description if description != '' else parent.description
	glyph = glyph if glyph else parent.glyph
	item = item if item else parent.item
	equipment = equipment if equipment else parent.equipment
	speed = speed if speed != 0 else parent.speed
	
	return
