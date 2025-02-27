extends Node

@export var story: InkStory = preload('res://assets/ink/crossroads_godot.ink')

var is_playing = true
var current_choices := []

signal line_registered
signal line_processed
signal command_executed
signal script_started
signal script_ended
signal choices_changed
signal choice_selected

signal _step
signal _choose

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
	if current_choices.size() > 0:
		await choice_selected
		print('choice selected')
		return true

	await _step
	print('stepped')
	return true

func choose(choice: InkChoice) -> void:
	print(choice.Index, " in ", current_choices.map(func(x): return x.Index))
	story.ChooseChoiceIndex(choice.Index)
	choice_selected.emit(choice)
	current_choices.clear()
	if story.GetCurrentChoices().size() > 0:
		current_choices = story.GetCurrentChoices()
	choices_changed.emit(current_choices)
	proceed()

func next() -> bool:
	var line = ''
	if story.GetCanContinue():
		line = story.Continue()
		line_registered.emit(line)
	print('next: ', story.GetCurrentChoices())
	if story.GetCurrentChoices().size() > 0:
		current_choices = story.GetCurrentChoices()
		choices_changed.emit(current_choices)
	if line:
		await process(line)
	if story.GetCanContinue():
		return await next()
	return true
