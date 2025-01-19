extends Node2D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_released():
		get_tree().change_scene_to_file('res://game/game.tscn')
		return
