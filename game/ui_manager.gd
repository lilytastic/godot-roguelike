extends Control

@export var pause_screen: Control
@export var character_screen: Control
@export var dialogue_screen: Control
@export var gameplay_screen: Control

var current_screen: Control = null

var screens: Array[Control]:
	get:
		return [pause_screen, character_screen, dialogue_screen, gameplay_screen]

var is_menu_open:
	get:
		return screens.filter(
			func(screen):
				return screen.visible && screen != gameplay_screen
		).size() > 0


func _ready():
	switch_screen(gameplay_screen)
		
	pause_screen.resume_pressed.connect(
		func(): switch_screen(null)
	)
	
	"""
	InkManager.script_started.connect(
		func():
			switch_screen(dialogue_screen)
	)
	InkManager.script_ended.connect(
		func():
			switch_screen(null)
	)
	"""


func switch_screen(screen: Control):
	if current_screen == null:
		pass # Global.take_screenshot()
	if !screen:
		screen = gameplay_screen
	"""
	if !screen:
		if InkManager.isPlaying:
			screen = dialogue_screen
		else:
			screen = gameplay_screen
	"""
	print('switch to: ', screen.name if screen else 'null')
	for _screen in screens:
		_screen.visible = false
	current_screen = screen
	if screen:
		screen.visible = true


func _input(event: InputEvent):
	if event.is_action_pressed('pause'):
		switch_screen(pause_screen if current_screen != pause_screen else null)
		get_viewport().set_input_as_handled()

	if event.is_action_pressed('open_character_menu') and current_screen != pause_screen:
		switch_screen(character_screen if current_screen != character_screen else null)
		get_viewport().set_input_as_handled()
	
	if !is_menu_open:
		Engine.time_scale = 1
	else:
		Engine.time_scale = 0


var was_menu_open = false
func _process(delta):
	if is_menu_open != was_menu_open:
		was_menu_open = is_menu_open
		PlayerInput.item_hovered.emit(null)

	if !is_menu_open:
		Engine.time_scale = 1
	else:
		Engine.time_scale = 0

func _unhandled_input(event: InputEvent):
	if !is_menu_open:
		return

	# When UI is open, consume all inputs
	get_viewport().set_input_as_handled()
