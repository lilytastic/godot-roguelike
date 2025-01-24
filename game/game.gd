extends Node

const PC_TAG = 'PC'
var player: Entity:
	get: return Global.player
var cameraSpeed := 6

func _ready() -> void:
	if !Global.player:
		Global.new_game()
		# Global.autosave()

	if !Global.player.location:
		$Camera2D.position = Coords.get_position(Global.player.location.position)
	

func _process(delta: float) -> void:
	if player and player.location != null:
		$Camera2D.position = lerp($Camera2D.position, Coords.get_position(player.location.position), delta * cameraSpeed)
	$Camera2D.offset = Vector2i(8 + 16 * 0, 8)
