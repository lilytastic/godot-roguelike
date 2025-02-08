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
		print(target.blueprint.use)
		match target.blueprint.use:
			'teleport':
				if !target.destination:
					return ActionResult.new(false)
				print(target.destination)
				var _map_name = target.destination.map
				print('teleported to: ', entity.location.map)
				var _map = MapManager.switch_map(MapManager.create_map(_map_name))
				if !_map:
					return ActionResult.new(false)
				entity.location.map = _map.uuid
				entity.location.position = target.destination.position
				MapManager.init_actors()
				return ActionResult.new(true, { 'cost_energy': 3 })
				
		pass

	if target.location and target.blueprint.item:
		if InventoryManager.give(entity, target):
			return ActionResult.new(true, { 'cost_energy': 3 })

	if entity.equipment and entity.equipment.has(target.uuid):
		if InventoryManager.unequip(entity, target):
			return ActionResult.new(true)

	if entity.inventory and entity.inventory.has(target.uuid):
		if InventoryManager.equip(entity, target):
			return ActionResult.new(true)

	return ActionResult.new(false)
