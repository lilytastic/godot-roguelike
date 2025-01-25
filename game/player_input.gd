extends Node

signal action_triggered

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('quicksave'):
		Global.quicksave()
		return
		
	var action := _check_for_action(event)
	if action:
		action_triggered.emit(action)


func _check_for_action(event: InputEvent) -> Action:
	for i: StringName in InputTag.MOVE_ACTIONS:
		if event.is_action_pressed(i):
			return MovementAction.new(_input_to_direction(i))

	if event.is_action_pressed('use'):
		var entities = Global.ecs.find_by_location(Global.player.location).filter(
			func(entity): return entity.uuid != Global.player.uuid
		)
		if entities.size() > 0:
			print(entities[0].uuid)
			return UseAction.new(entities[0])

	return null


func _input_to_direction(direction: StringName):
	var coord: Vector2i = Vector2i.ZERO
	
	match direction:
		InputTag.MOVE_LEFT:
			coord += Vector2i.LEFT
		InputTag.MOVE_RIGHT:
			coord += Vector2i.RIGHT
		InputTag.MOVE_UP:
			coord += Vector2i.UP
		InputTag.MOVE_DOWN:
			coord += Vector2i.DOWN

	return coord
