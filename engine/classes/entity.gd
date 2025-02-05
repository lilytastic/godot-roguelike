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

var health: Meter = null

var energy := 0.00
var is_acting = false

var animation: AnimationSequence = null

var screen_position: Vector2:
	get:
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
	var new_id = ECS.add(self)
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


func can_see(pos: Vector2) -> bool:
	return true # Coords.get_range(pos, location.position) < 7

func can_act() -> bool:
	return blueprint.equipment != null

func blocks_entities() -> bool:
	return is_instance_valid(blueprint.equipment)

func is_hostile(other: Entity) -> bool:
	if other.uuid == uuid:
		return false
	return blueprint.equipment != null


func trigger_action(target: Entity):
	var act_range = 0
	if target and target.blocks_entities():
		act_range = 1
	if targeting.current_path.size() and targeting.current_path[0] == location.position:
		targeting.current_path = targeting.current_path.slice(1)

	# TODO: Check actual distance in case the path is wrong
	var distance = targeting.current_path.size()
	if distance > act_range:
		var result = await perform_action(
			MovementAction.new(
				targeting.current_path[0] - location.position
			),
			false
		)
		if result.success:
			targeting.current_path = targeting.current_path.slice(1)
		else:
			targeting.clear_path()
			targeting.clear_targeting()

		return result
	else:
		if target:
			var default_action = get_default_action(target)
			if !default_action:
				default_action = MovementAction.new(
					PlayerInput._input_to_direction(
						InputTag.MOVE_ACTIONS.pick_random()
					)
				)
			var result = null
			if default_action:
				result = await perform_action(default_action)
			targeting.clear_path()
			targeting.clear_targeting()
			if result:
				return result

	return null

func get_default_action(target: Entity) -> Action:
	# TODO: If it's hostile, use this entity's first weaponskill on it.
	if target.blueprint.equipment:
		if equipment:
			for uuid in equipment.slots.values():
				var worn_item = ECS.entity(uuid)
				if worn_item.blueprint.weapon:
					var ability = worn_item.blueprint.weapon.weaponskills[0]
					return UseAbilityAction.new(
						target,
						ability,
						{ 'conduit': worn_item } if worn_item else {}
					)
		return UseAbilityAction.new(
			target,
			'slash'
		)
	# TODO: Otherwise, if it's usable, use it!
	if target.blueprint.item:
		return UseAction.new(target)
		
	return null

func perform_action(action: Action, allow_recursion := true):
	is_acting = true
	var result = await action.perform(self)
	energy -= result.cost_energy
	if !result.success and result.alternate:
		if allow_recursion:
			return await perform_action(result.alternate)
	is_acting = false
	action_performed.emit(action, result)
	return result
