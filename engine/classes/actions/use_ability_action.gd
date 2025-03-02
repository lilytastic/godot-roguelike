class_name UseAbilityAction
extends Action

var target: Entity
var ability: Ability
var conduit: Entity


func _init(_target: Entity, abilityId: String, opts := {}):
	target = _target
	ability = ECS.abilities[abilityId]
	conduit = opts.get('conduit', null)
	

func perform(entity: Entity) -> ActionResult:
	if !target:
		print('no target')
		return ActionResult.new(false)
		
	# TODO: Make this totally different.
	# Iterate through a sequencer which specifies steps where you:
	# 1) Move the entity around.
	# 2) Apply the effect to select tiles.
	# Takes a direction.
	# Should be portable, so you can call it from the UI to show all affected tiles.

	var weapon_props = conduit.blueprint.weapon if (conduit and conduit.blueprint.weapon) else null
	var distance = entity.location.position.distance_to(target.location.position) if (entity.location and target.location) else -1
	if weapon_props and distance > weapon_props.range:
		# Too far!
		return ActionResult.new(false)
		
	var vec = entity.location.position.direction_to(target.location.position)
	
	entity.animation = AnimationSequence.new(
		[
			{ 'position': Vector2.ZERO * 0.0 },
			{ 'position': vec * 6.0 },
			{ 'position': vec * 7.0 },
			{ 'position': vec * 6.0 },
			{ 'position': Vector2.ZERO * 0.0 },
			{ 'position': -vec * 2.0 },
			{ 'position': Vector2.ZERO * 0.0 },
		],
		Global.STEP_LENGTH * 1.5
	)

	await Global.sleep(20)
	
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
			{ 'position': vec * 6.0, 'color': Color.CRIMSON },
			{ 'position': vec * 6.0, 'color': Color.CRIMSON },
			{ 'position': vec * 0.0, 'color': Color.CRIMSON },
			{ 'position': Vector2.ZERO * 0.0, 'color': Color.CRIMSON },
		],
		Global.STEP_LENGTH * 1.5
	)

	await Global.sleep(150)

	return ActionResult.new(true, { 'cost_energy': 100 })
