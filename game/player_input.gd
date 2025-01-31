extends Node

var dragging := {}
var entity_dragging: Entity:
	get:
		if PlayerInput.dragging.has('entity') and Global.ecs.entities.has(PlayerInput.dragging.entity):
			return Global.ecs.entity(PlayerInput.dragging.entity)
		return null

var cursor: Sprite2D = null

signal action_triggered
signal ui_action_triggered
signal double_click


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if cursor:
			cursor.position = Coords.get_coord(get_viewport().get_camera_2d().get_global_mouse_position()) * Vector2i(16, 16) + Vector2i(8, 8)
		return
	
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
