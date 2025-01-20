extends Control

var isOpen:
	get: return visible


func _ready():
	visible = false

	if %AsideMenu:
		%AsideMenu.resume_pressed.connect(
			func(): visible = false
		)

func _input(event: InputEvent):
	if event.is_action_pressed('open_system_menu'):
		visible = !visible


func _unhandled_input(event: InputEvent):
	if !visible:
		return
	
	# When UI is open, consume all inputs
	get_viewport().set_input_as_handled()
