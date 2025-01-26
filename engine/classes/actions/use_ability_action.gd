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

	return ActionResult.new(false)
