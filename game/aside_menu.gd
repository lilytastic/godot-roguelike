extends Control

func _ready() -> void:
	%'NewGame'.pressed.connect(
		func(): _start_game()
	)
	Global.player_changed.connect(
		func(player): _initialize()
	)

func _enter_tree() -> void:
	_initialize()
	
func _initialize() -> void:
	print('initialize ', Global.is_game_started)
	
	if Global.is_game_started:
		%'Continue'.visible = false
		%'Resume'.visible = true
		%'NewGame'.visible = false
		%'SaveGame'.visible = true
		%'ExitToMainMenu'.visible = true
	else:
		%'Continue'.visible = true
		%'Resume'.visible = false
		%'NewGame'.visible = true
		%'SaveGame'.visible = false
		%'ExitToMainMenu'.visible = false
		

func _start_game():
	Global.new_game()
	get_tree().change_scene_to_file('res://game/game.tscn')
