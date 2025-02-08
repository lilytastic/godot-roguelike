class_name Entity

var _uuid: String = ''
var uuid: String:
	get: return _uuid
	set(value):
		ECS.entities.erase(_uuid)
		_uuid = value

var _blueprint: String
var blueprint: Blueprint:
	get: return ECS.blueprints.get(_blueprint, null)
	set(value): _blueprint = value.id

var glyph: Glyph:
	get: return blueprint.glyph if blueprint else null

var location: Location = null
var inventory: InventoryProps = null
var equipment: EquipmentProps = null
var targeting: Targeting = null
var actor: Actor = null
var destination: Dictionary = {}

var health: Meter = null

var energy := 0.00
var is_acting = false

var animation: AnimationSequence = null

var screen_position: Vector2:
	get:
		if !actor:
			return Vector2(0,0)
		return actor.get_global_transform_with_canvas().origin

signal map_changed
signal health_changed
signal on_death
signal action_performed

const uuid_util = preload('res://addons/uuid/uuid.gd')


func _init(opts: Dictionary):
	_blueprint = opts.blueprint
	uuid = opts.uuid if opts.has('uuid') else uuid_util.v4()
	targeting = Targeting.new()

	if blueprint.baseHP:
		health = Meter.new(20)
		health_changed.connect(
			func(amount):
				if !health or health.current <= 0:
					# await Global.sleep(250)
					on_death.emit()
					ECS.remove(uuid)
		)

func change_location(_location: Location):
	location = _location
	map_changed.emit(location.map)
	MapManager.entity_moved.emit(uuid)

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
	if destination: dict.destination = destination
	if health: dict.health = health.current

	return dict

func load_from_save(data: Dictionary) -> void:
	var new_id = ECS.add(self)
	var json = JSON.new()
	
	if data.has('position'):
		var _pos = str(data.position).trim_prefix('(').trim_suffix(')').split(', ')
		change_location(Location.new(
			data.map,
			Vector2(int(_pos[0]), int(_pos[1]))
		))

	energy = data.energy if data.has('energy') else 0
	
	if data.has('inventory'): inventory = InventoryProps.new(data.inventory)
	if data.has('equipment'): equipment = EquipmentProps.new(data.equipment)
	if data.has('destination'): destination = data.get('destination', {})
	if data.has('health'): health.current = data.health


func damage(opts: Dictionary):
	var damage = opts.get('damage', 1)
	if health:
		health.deduct(damage)
		if damage > 0:
			Global.add_floating_text(
				str(damage),
				screen_position,
				{ 'color': Color.CRIMSON }
			)
		health_changed.emit(-damage)

static func init_from_node(node: Node2D):
	var opts = {
		'blueprint': node.get_meta('blueprint', 'quadropus')
	}
	var props = node.get_meta('props', {})

	var new_entity = Entity.new(opts)
	var coords = Coords.get_coord(node.position)
	if new_entity.location:
		new_entity.location.position = coords
	else: 
		new_entity.location = Location.new('', coords)
	for prop in props:
		new_entity[prop] = props[prop]

	return new_entity
