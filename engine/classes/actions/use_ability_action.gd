class_name UseAbilityAction
extends Action

var target: Entity
var direction := Vector2.ZERO
var ability: Ability
var conduit: Entity


func _init(abilityId: String, opts := {}):
	ability = ECS.abilities[abilityId]
	target = opts.get("target", null)
	direction = opts.get("direction", Vector2.ZERO)
	conduit = opts.get('conduit', null)


func run_script(entity: Entity, handler: Callable) -> void:
	var weapon_props = conduit.blueprint.weapon if (conduit and conduit.blueprint.weapon) else null
	var damageRange = weapon_props.damage if weapon_props else [5, 5]
	var potency = round(randf_range(damageRange[0], damageRange[1]))
	InkManager.CommandTriggered.connect(handler)
	var dir = direction
	dir.x = round(dir.x)
	dir.y = round(dir.y)
	await InkManager.Execute(ability.id, [ entity.uuid, str(dir), potency ])
	InkManager.CommandTriggered.disconnect(handler)


func perform(entity: Entity) -> ActionResult:
	if entity.uuid == Global.player.uuid:
		if !target and !direction:
			PlayerInput.preview_action = self
			PlayerInput.direction_pressed.emit(Global.player.location.facing)
			var result = await PlayerInput.on_target_selected
			PlayerInput.preview_action = null
			if result:
				target = result.get("target", target)
				direction = result.get("direction", direction)

	if direction == Vector2.ZERO and target:
		direction = entity.location.position.direction_to(target.location.position)

	if !target and direction == Vector2.ZERO:
		print('no target')
		return ActionResult.new(false)
		
	entity.location.facing = direction
	
	entity.animation = AnimationSequence.new(
		[
			{ 'position': Vector2.ZERO * 0.0 },
			{ 'position': direction * 6.0 },
			{ 'position': direction * 7.0 },
			{ 'position': direction * 6.0 },
			{ 'position': Vector2.ZERO * 0.0 },
			{ 'position': -direction * 2.0 },
			{ 'position': Vector2.ZERO * 0.0 },
		],
		Global.STEP_LENGTH * 1.5
	)

	await Global.sleep(20)
	
	run_script(entity, func(command_result): return handle_command(command_result, entity))

	await Global.sleep(150)
	
	return ActionResult.new(true, { 'cost_energy': 100 })
	

	var weapon_props = conduit.blueprint.weapon if (conduit and conduit.blueprint.weapon) else null
	var distance = entity.location.position.distance_to(target.location.position) if (entity.location and target.location) else -1
	if weapon_props and distance > weapon_props.range:
		# Too far!
		return ActionResult.new(false)
		
	
	if is_instance_valid(target.actor):
		target.actor.modulate = Color.CRIMSON

	for effect in ability.effects:
		match effect.type:
			'damage':
				var damageRange = weapon_props.damage if weapon_props else [5, 5]
				var damage = round(randf_range(damageRange[0], damageRange[1]) * effect.potency)
				target.damage({ 'damage': damage, 'source': entity })
				pass
	
	target.animation = AnimationSequence.new(
		[
			{ 'position': direction * 6.0, 'color': Color.CRIMSON },
			{ 'position': direction * 6.0, 'color': Color.CRIMSON },
			{ 'position': direction * 0.0, 'color': Color.CRIMSON },
			{ 'position': Vector2.ZERO * 0.0, 'color': Color.CRIMSON },
		],
		Global.STEP_LENGTH * 1.5
	)

	await Global.sleep(150)

	return ActionResult.new(true, { 'cost_energy': 100 })


func handle_command(command_result, entity):
	var tagDictionary = command_result.get('tagDictionary', {})
	var tokens = command_result.get('tokens', [])

	var pos: Vector2 = Vector2.ZERO
	var direction: Vector2 = Vector2.ZERO
	if tagDictionary.has("position"):
		pos = Global.string_to_vector(tagDictionary["position"])
	if tagDictionary.has("direction"):
		direction = Global.string_to_vector(tagDictionary["direction"])
		if pos == Vector2.ZERO:
			pos = entity.location.position + direction
	else:
		direction = entity.location.position.direction_to(pos)

	var at_position = MapManager.get_collisions(pos)
	match tokens[0]:
		"move":
			if at_position.size() == 0:
				MovementAction.new(direction, false).perform(entity)
		"damage":
			for other in at_position:
				other.damage({
					"damage": float(tagDictionary["potency"])
				})
				# ((RefCounted)otherEntity.Get("actor")).Set("modulate", new Color(0.8f, 0, 0));
