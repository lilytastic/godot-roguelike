class_name Entity

var _uuid: int = 0
var uuid: int:
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
var location: Location
var inventory: InventoryProps
var equipment: EquipmentProps
var health: Meter = null
var energy := 0.00
var actor: Actor = null
var is_acting = false

var current_path := []
var current_target: int = -1 # uuid
var current_target_position: Vector2i = Vector2i(-1, -1)
var animation: AnimationSequence = null

var screen_position: Vector2:
	get:
		return actor.get_global_transform_with_canvas().origin

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
					# await Global.sleep(250)
					on_death.emit()
					ECS.remove(uuid)
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
		if damage > 0:
			Global.add_floating_text(
				str(damage),
				screen_position,
				{ 'color': Color.CRIMSON }
			)
		health_changed.emit(-damage)

func blocks_entities() -> bool:
	return is_instance_valid(blueprint.equipment)

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
	if data.has('health'): health.current = data.get('health', 1)

func can_see(pos: Vector2) -> bool:
	return true # Coords.get_range(pos, location.position) < 7

func can_act() -> bool:
	return blueprint.equipment != null

func is_hostile(other: Entity) -> bool:
	if other.uuid == uuid:
		return false
	return blueprint.equipment != null


func clear_path():
	current_path = []
	
func clear_targeting():
	current_target_position = Vector2i(-1, -1)
	current_target = -1

func set_target_position(pos: Vector2):
	current_target_position = pos
	current_target = -1

func has_target() -> bool:
	if current_target != -1:
		return true
		
	if current_target_position != Vector2i(-1, -1):
		return true

	return false

func target_position(include_cursor := true):
	var target = ECS.entity(current_target)
	if target and target.location:
		return target.location.position
		
	if current_target_position != Vector2i(-1, -1):
		return current_target_position

	if include_cursor and PlayerInput.entities_under_cursor.size() > 0 and PlayerInput.entities_under_cursor[0].location:
		return PlayerInput.entities_under_cursor[0].location.position

	return Vector2(-1, -1)

	
func perform_action(action: Action, allow_recursion := true):
	is_acting = true
	var result = await action.perform(self)
	if !result.success and result.alternate:
		if allow_recursion:
			return await perform_action(result.alternate)
	is_acting = false
	action_performed.emit(action, result)
	return result


func trigger_action(target: Entity):
	var act_range = 0
	if target and target.blocks_entities():
		act_range = 1
	if current_path.size() and current_path[0] == location.position:
		current_path = current_path.slice(1)

	# TODO: Check actual distance in case the path is wrong
	var distance = current_path.size()
	if distance > act_range:
		var result = await perform_action(
			MovementAction.new(
				current_path[0] - location.position
			),
			false
		)
		if result.success:
			current_path = current_path.slice(1)
		else:
			clear_path()
			clear_targeting()

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
			clear_path()
			clear_targeting()
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


func path_needs_updating() -> bool:
	var _reset_path = false
	if has_target():
		if current_path.size() == 0:
			_reset_path = true
		else:
			var _target_position = target_position(false)
			var _last_position = current_path[current_path.size() - 1]
			for coord in current_path.slice(1, -1):
				if Global.navigation_map.is_point_disabled(Global.map_view.get_astar_pos(coord.x, coord.y)):
					_reset_path = true
			if _target_position.x != _last_position.x or _target_position.y != _last_position.y:
				_reset_path = true
	return _reset_path
