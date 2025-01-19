extends Node

const PC_TAG = 'PC'
var player: Entity:
	get: return Global.player
var cameraSpeed := 6

signal action_triggered


func _ready() -> void:
	if !Global.player:
		Global.new_game()
	

func _process(delta: float) -> void:
	if player and player.position != null:
		$Camera2D.position = lerp($Camera2D.position, Coords.get_position(player.position), delta * cameraSpeed)
	$Camera2D.offset = Vector2i(8 + 16 * 0, 8)
	

func _unhandled_input(event: InputEvent) -> void:
	var action: Action
	for i: StringName in InputTag.MOVE_ACTIONS:
		if event.is_action_pressed(i):
			action = _move_pc(i)
			break
	
	if event.is_action_pressed('quicksave'):
		Global.save()
		return
		
	if action:
		action.perform(player)
		action_triggered.emit(action)


func _move_pc(direction: StringName) -> Action:
	if !player:
		return
	
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

	return MovementAction.new(coord)
