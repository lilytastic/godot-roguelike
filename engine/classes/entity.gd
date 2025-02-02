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
var health: Meter = null
var energy := 0.00

var current_path := []
var current_target: int = -1 # uuid
var animation: AnimationSequence = null

signal map_changed
signal health_changed
signal on_death
signal action_performed

func _init(opts: Dictionary):
	_blueprint = opts.blueprint
	uuid = opts.uuid if opts.has('uuid') else ResourceUID.create_id()

	if blueprint.baseHP:
		health = Meter.new(20)
		health_changed.connect(
			func(amount):
				if !health or health.current <= 0:
					on_death.emit()
					Global.ecs.remove(uuid)
		)

	on_death.connect(
		func():
			# Drop a corpse, drop gear, trigger an event, etc.
			pass
	)
	return
	
func damage(opts: Dictionary):
	var damage = opts.get('damage', 1)
	if health:
		health.deduct(damage)
		health_changed.emit(-damage)

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
	if health: dict.health = health.current

	return dict

func load_from_save(data: Dictionary) -> void:
	var new_id = Global.ecs.add(self)
	var json = JSON.new()
	
	if data.has('position'):
		var _pos = str(data.position).trim_prefix('(').trim_suffix(')').split(', ')
		location = Location.new(
			data.map,
			Vector2(int(_pos[0]), int(_pos[1]))
		)
		map_changed.emit(location.map)

	energy = data.energy if data.has('energy') else 0
	
	if data.has('inventory'): inventory = InventoryProps.new(data.inventory)
	if data.has('equipment'): equipment = EquipmentProps.new(data.equipment)
	if data.has('health'): health.current = data.get('health', 1)

func can_see(pos: Vector2) -> bool:
	return true # Coords.get_range(pos, location.position) < 7

func can_act() -> bool:
	return blueprint.equipment != null
