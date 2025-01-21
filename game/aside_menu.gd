extends Control

signal option_pressed
signal resume_pressed

func _input(ev: InputEvent) -> void:
	if ev.is_action_pressed('open_system_menu'):
		if %SaveSlotWrapper.visible:
			%SaveSlotWrapper.visible = false
			get_viewport().set_input_as_handled()
		

func _ready() -> void:
	_initialize()
	%SaveSlotWrapper.visible = false
	Global.game_saved.connect(
		func():
			%SaveSlotWrapper.visible = false
	)
	Global.game_loaded.connect(
		func():
			%SaveSlotWrapper.visible = false
			get_tree().change_scene_to_file('res://game/game.tscn')
	)
	%Continue.pressed.connect(
		func():
			option_pressed.emit('Continue')
			_continue()
	)
	%'Resume'.pressed.connect(
		func():
			option_pressed.emit('Resume')
			resume_pressed.emit()
	)
	%'NewGame'.pressed.connect(
		func():
			option_pressed.emit('NewGame')
			_start_game()
	)
	%'SaveGame'.pressed.connect(
		func():
			option_pressed.emit('SaveGame')
			%SaveSlots.mode = 'save'
			%SaveSlotsLabel.text = '[center]Save Game[/center]'
			%SaveSlotWrapper.visible = true
	)
	%'LoadGame'.pressed.connect(
		func():
			option_pressed.emit('LoadGame')
			%SaveSlots.mode = 'load'
			%SaveSlotsLabel.text = '[center]Load Game[/center]'
			%SaveSlotWrapper.visible = true
	)
	%'ExitToMainMenu'.pressed.connect(
		func():
			Global.clear_game()
			get_tree().change_scene_to_file('res://title/title.tscn')
	)
	%'Exit'.pressed.connect(
		func():
			get_tree().quit()
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
		var latestSave = _get_latest_save()
		if latestSave:
			%'Continue'.visible = true
		else:
			%'Continue'.visible = false
		%'Resume'.visible = false
		%'NewGame'.visible = true
		%'SaveGame'.visible = false
		%'ExitToMainMenu'.visible = false
		

func _start_game():
	Global.new_game()
	get_tree().change_scene_to_file('res://game/game.tscn')

func _get_latest_save():
	var latestSave: Dictionary
	var latestDate = 0
	for slot in Global.get_save_slots():
		var data = Global.load_from_save(slot.path)
		if data and data.has('date_modified'):
			var date = Time.get_unix_time_from_datetime_string(data.date_modified)
			if date > latestDate:
				latestDate = date
				latestSave = slot
	if latestSave:
		return latestSave
	return null

func _continue():
	var latestSave = _get_latest_save()
	if latestSave:
		Global.load_game(latestSave.path)
		# get_tree().change_scene_to_file('res://game/game.tscn')
