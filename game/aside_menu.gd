extends Control

func _ready() -> void:
	%'NewGame'.pressed.connect(
		func():
			_start_game()
	)


func _start_game():
	Global.new_game()
	get_tree().change_scene_to_file('res://game/game.tscn')
