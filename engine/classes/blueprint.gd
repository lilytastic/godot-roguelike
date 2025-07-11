class_name Blueprint

var id: String
var name: String
var description: String
var parent: String
var type: String
var glyph: Glyph
var item: ItemProps
var equipment: EquipmentProps
var weapon: WeaponProps
var use: UseProps
var speed := 0.0
var baseHP: String


func _init(props: Dictionary):
	id = props.get('id')
	name = props.get('name', id)
	parent = props.get('parent', '')
	description = props.get('description', '')
	if props.has('use'):
		use = UseProps.new(props.get('use'))
	var _hp = props.get('baseHP', 0)
	baseHP = str(_hp) if !(_hp is String) else _hp
	type = props.get('type', 'unknown')
	speed = float(props.get('speed', 0.0))
	if props.has('glyph'):
		glyph = Glyph.new(props.glyph)
	if props.has('wearable') or props.has('storage'):
		item = ItemProps.new(props)
	if props.has('slots'):
		equipment = EquipmentProps.new(props)
	if props.has('weapon'):
		weapon = WeaponProps.new(props.weapon)
	return


func concat(parent: Blueprint):
	type = type if type != 'unknown' else parent.type
	description = description if description != '' else parent.description
	glyph = glyph if glyph else parent.glyph
	if item:
		if parent.item:
			item.slots = parent.item.slots if item.slots.size() == 0 else item.slots
			item.weight = parent.item.weight if item.weight == 0 else item.weight
			item.value = parent.item.value if item.value == 0 else item.value
	else:
		item = parent.item
	equipment = equipment if equipment else parent.equipment
	speed = speed if speed != 0.0 else float(parent.speed)
	weapon = weapon if weapon else parent.weapon
	use = use if use else parent.use
	
	return

static func load_from_files(resources: Array) -> Dictionary:
	var preprocess: Dictionary
	
	for resource in resources:
		var data = Files.get_dictionary(resource)
		if data.has('blueprints'):
			var _blueprints = data.blueprints
			for blueprint in _blueprints:
				if blueprint.has('id'):
					preprocess[blueprint.id] = Blueprint.new(blueprint)

	for blueprint in preprocess:
		var current = preprocess[blueprint]
		var curr = preprocess[blueprint]
		while curr.parent:
			if !preprocess.has(curr.parent):
				break
			curr = preprocess[curr.parent]
			current.concat(curr)
	
	return preprocess
