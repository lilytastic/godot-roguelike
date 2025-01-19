extends Node

const PC_TAG = 'PC'
var player: Entity:
	get: return Global.player
var cameraSpeed := 6


func _ready() -> void:
	if !Global.player:
		Global.new_game()
	$TileMapLayer.map = player.map
	

func _process(delta: float) -> void:
	if player and player.position != null:
		$Camera2D.position = lerp($Camera2D.position, Coords.get_position(player.position), delta * cameraSpeed)
	$Camera2D.offset = Vector2i(8 + 16 * 0, 8)
	

func _unhandled_input(event: InputEvent) -> void:
	for i: StringName in InputTag.MOVE_ACTIONS:
		if event.is_action_pressed(i):
			Global.move_pc(i)
			return
	
	if event.is_action_pressed('quicksave'):
		Global.save()
		return
