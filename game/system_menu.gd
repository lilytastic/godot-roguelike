extends Control

var isMenuOpen:
	get: return %AsideMenu.visible or %CharacterMenu.visible


func _ready():
	%AsideMenu.visible = false
	%CharacterMenu.visible = false

	if %AsideMenu:
		%AsideMenu.resume_pressed.connect(
			func(): %AsideMenu.visible = false
		)


func _input(event: InputEvent):
	if !%CharacterMenu.visible and event.is_action_pressed('open_system_menu'):
		%AsideMenu.visible = !%AsideMenu.visible
		get_viewport().set_input_as_handled()

	if !%AsideMenu.visible and event.is_action_pressed('open_character_menu'):
		%CharacterMenu.visible = !%CharacterMenu.visible
		get_viewport().set_input_as_handled()
	
	if !isMenuOpen:
		Engine.time_scale = 1
	else:
		Engine.time_scale = 0


func _unhandled_input(event: InputEvent):
	if !isMenuOpen:
		return

	# When UI is open, consume all inputs
	get_viewport().set_input_as_handled()
