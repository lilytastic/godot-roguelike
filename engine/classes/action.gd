class_name Action

func preview(entity: Entity):
	# TODO: Return list of tiles illustrating what this action will do.
	pass

func perform(entity: Entity) -> ActionResult:
	return ActionResult.new(false)
