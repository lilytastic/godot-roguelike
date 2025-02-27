extends Node

@export var story: InkStory = preload('res://assets/ink/crossroads_godot.ink')

var is_playing = true

signal line_registered
signal line_processed
signal command_executed
signal script_started
signal script_ended

signal _step

func _process(delta: float) -> void:
	pass
	# _step.emit()


func execute(path: String) -> void:
	story.ChoosePathString(path)
	print('ChoosePathString(', path, ')')
	script_started.emit()
	is_playing = true
	await next()
	is_playing = false
	script_ended.emit()

func perform(entity: Entity, path: String, target: Entity = null) -> ActionResult:
	story.ChoosePathString(path)
	print('perform(', path, ')')
	script_started.emit()
	is_playing = true
	await next()
	is_playing = false
	script_ended.emit()
	print('finished performing: ', path)
	return ActionResult.new(true, { 'cost_energy': 0 })

func proceed() -> bool:
	_step.emit(true)
	return true

func process(line: String) -> bool:
	print('process(): ', line)
	
	if line.begins_with('>>>'):
		var tokens = line.substr(3).split(' ')
		print('command: ', tokens)
		command_executed.emit(tokens)
		return true
		
	line_processed.emit(line)
	
	await _step
	return true

func next() -> bool:
	if story.GetCanContinue():
		var line = story.Continue()
		line_registered.emit(line)
		var result = await process(line)
	if story.GetCurrentChoices().size() > 0:
		return false
	if story.GetCanContinue():
		return await next()
	return true
