class_name UseAction
extends Action

var target: Entity

func _init(_target: Entity):
	target = _target

func perform(entity: Entity) -> ActionResult:
	if !target:
		return ActionResult.new(false)
		
	entity.animation = AnimationSequence.new(
		[
			{ 'scale': Vector2(1, 1) },
			{ 'scale': Vector2(1.3, 0.7) },
			{ 'scale': Vector2(1.3, 0.7) },
		],
		Global.STEP_LENGTH * 0.5
	)

	if target.blueprint.use:
		match target.blueprint.use.type:
			'talk':
				if target.blueprint.use.knot:
					return await InkManager.Perform(entity, target.blueprint.use.knot)
					# return ActionResult.new(false)
					# return await InkManager.perform(entity, target.blueprint.use.knot, target)
			'teleport':
				if !target.destination:
					return ActionResult.new(false)
					
				entity.animation = null
				MapManager.is_switching = true
				await Global.sleep(500)

				target.destination = await MapManager.resolve_destination(target.destination, entity)
				MapManager.teleport(target.destination, entity)
				print('used staircase; change destination to: ', target.destination)
				if target.destination.has('map'):
					return ActionResult.new(true, { 'cost_energy': 100 })
		pass

	if target.location and target.blueprint.item:
		if InventoryManager.give(entity, target):
			return ActionResult.new(true, { 'cost_energy': 100 })

	if entity.equipment and entity.equipment.has(target.uuid):
		if InventoryManager.unequip(entity, target):
			return ActionResult.new(true)

	if entity.inventory and entity.inventory.has(target.uuid):
		if InventoryManager.equip(entity, target):
			return ActionResult.new(true)

	return ActionResult.new(false)
