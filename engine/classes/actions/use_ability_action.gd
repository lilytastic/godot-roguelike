class_name UseAbilityAction
extends Action

var target: Entity
var direction: Vector2
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
	await InkManager.Execute(ability.id, [ entity.uuid, str(direction), potency ])
	InkManager.CommandTriggered.disconnect(handler)

func preview(entity: Entity):
	await run_script(entity, preview_command)

func perform(entity: Entity) -> ActionResult:
	if entity.uuid == Global.player.uuid:
		if !target and !direction:
			var result = await PlayerInput.prompt_for_target(self)
			target = result.get("target", target)
			direction = result.get("direction", direction)

	if !direction and target:
		direction = entity.location.position.direction_to(target.location.position)

	if !target and !direction:
		print('no target')
		# TODO: Tell the UI to let the player select a target and await.
		return ActionResult.new(false)
		
	# TODO: Make this totally different.
	# Iterate through a sequencer which specifies steps where you:
	# 1) Move the entity around.
	# 2) Apply the effect to select tiles.
	# Takes a direction.
	# Should be portable, so you can call it from the UI to show all affected tiles.
	
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
	
	run_script(entity, handle_command)

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



func handle_command(tokens):
	var tagDictionary := {}
	for tag in InkManager.story.GetCurrentTags():
		var t = tag.split("=")
		tagDictionary[t[0].strip_edges()] = t[1].strip_edges()

	match tokens[0]:
		"damage":
			var pos: Vector2 = Global.string_to_vector(tagDictionary["position"])
			var affected = MapManager.get_collisions(pos)
			for other in affected:
				other.damage({
					"damage": float(tagDictionary["potency"])
				})
				# ((RefCounted)otherEntity.Get("actor")).Set("modulate", new Color(0.8f, 0, 0));


func preview_command(tokens):
	var tagDictionary := {}
	for tag in InkManager.story.GetCurrentTags():
		var t = tag.split("=")
		tagDictionary[t[0].strip_edges()] = t[1].strip_edges()

	print("display: ", tokens[0], tagDictionary)
	match tokens[0]:
		"damage":
			var pos: Vector2 = Global.string_to_vector(tagDictionary["position"])
			var affected = MapManager.get_collisions(pos)
			pass
		
