class_name UseAbilityAction
extends Action

var target: Entity
var ability: Ability

func _init(_target: Entity, abilityId: String):
	target = _target
	ability = Global.ecs.abilities[abilityId]

func perform(entity: Entity) -> ActionResult:
	if !target:
		return ActionResult.new(false)
		
	print('Doing ability ', ability.name, ' (', ability.effects[0], ')')
	for effect in ability.effects:
		match effect.type:
			'damage':
				Global.ecs.remove(target.uuid)
				pass

	return ActionResult.new(false)
