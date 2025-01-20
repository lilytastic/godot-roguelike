extends Node2D

var showMenu = false

func _ready():
	_set_menu(false)
	%'New Game'.pressed.connect(
		func():
			_start_game()
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_released():
		# _start_game()
		_set_menu(true)

		return

	if !showMenu:
		return


func _start_game():
	Global.new_game()
	get_tree().change_scene_to_file('res://game/game.tscn')

func _set_menu(isOpen: bool) -> void:
	var splash = $'CanvasLayer/Panel/Splash Menu'
	var aside = $'CanvasLayer/Panel/Aside Menu'
	if isOpen:
		splash.visible = false
		aside.visible = true
	else: 
		splash.visible = true
		aside.visible = false
	showMenu = isOpen
