class_name UseAbilityAction
extends Action

var target: Entity
var ability: Ability
var conduit: Entity

func _init(_target: Entity, abilityId: String, opts := {}):
	target = _target
	ability = Global.ecs.abilities[abilityId]
	conduit = opts.get('conduit', null)
	

func perform(entity: Entity) -> ActionResult:
	if !target:
		return ActionResult.new(false)
		
	print('Doing ability ', ability.name, ' (', ability.effects[0], ')')
	for effect in ability.effects:
		match effect.type:
			'damage':
				var weapon_props = conduit.blueprint.weapon if conduit.blueprint.weapon else null
				var damageRange = weapon_props.damage if weapon_props else [5, 5]
				var damage = round(randf_range(damageRange[0], damageRange[1]) * effect.potency)
				target.damage({ 'damage': damage, 'source': entity })
				pass

	return ActionResult.new(false)
