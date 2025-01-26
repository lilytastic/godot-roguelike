class_name Entity

var _uuid: int = 0
var uuid: int:
	get: return _uuid
	set(value):
		Global.ecs.entities.erase(_uuid)
		_uuid = value
var _blueprint: String
var blueprint: Blueprint:
	get: return Global.ecs.blueprints.get(_blueprint, null)
	set(value): _blueprint = value.id
var glyph: Glyph:
	get: return blueprint.glyph if blueprint else null
var location: Location
var inventory: InventoryProps
var equipment: EquipmentProps
var energy := 0

signal map_changed


func _init(opts: Dictionary):
	print('Initializing entity with template: ', opts.blueprint)
	_blueprint = opts.blueprint
	uuid = opts.uuid if opts.has('uuid') else ResourceUID.create_id()
	return
	
func damage(opts: Dictionary):
	if opts.has('damage'):
		print(opts.damage)

func save() -> Dictionary:
	var dict := {}
	
	dict.uuid = uuid
	dict.blueprint = _blueprint
	dict.energy = energy

	if location:
		dict.map = location.map
		dict.position = location.position
	if inventory: dict.inventory = inventory.save()
	if equipment: dict.equipment = equipment.save()

	print('saving ', dict)
	return dict

func load_from_save(data: Dictionary) -> void:
	print('data: ', data)

	var new_id = Global.ecs.add(self)
	var json = JSON.new()
	
	if data.has('position'):
		var _pos = str(data.position).trim_prefix('(').trim_suffix(')').split(', ')
		location = Location.new(
			data.map,
			Vector2(int(_pos[0]), int(_pos[1]))
		)
		print('location: ', location.position)
		map_changed.emit(location.map)

	energy = data.energy if data.has('energy') else 0
	
	if data.has('inventory'): inventory = InventoryProps.new(data.inventory)
	if data.has('equipment'): equipment = EquipmentProps.new(data.equipment)
	
