extends Node

# Switch to C# lolllllll

@export var story: InkStory = preload('res://assets/ink/crossroads_godot.ink')

var is_playing = false
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

func _ready() -> void:
	story.BindExternalFunction(
		"addVectors",
		func(v1, v2):
			print(v1, v2)
			return ""
	)
	story.BindExternalFunction(
		"getPosition",
		func(_entity):
			print(_entity)
			return ""
	)
	story.Continue()
	print("binding shit")

func execute(path: String, _entity: Entity = null) -> void:
	if !story.HasFunction(path):
		print("NO FUNCTION AAAAA")
		return
	if _entity:
		story.StoreVariable("entity", _entity.uuid)
	print(story.FetchVariable("entity"))
	print("path: ", path)
	story.ChoosePathString(path)
	var i = 0
	if story.GetCanContinue(): # should be while, but GodotInk is fightin me when it errors
		i += 1
		print(story.Continue())
		if i > 9:
			pass # break

func perform(entity: Entity, path: String, target: Entity = null) -> ActionResult:
	story.ChoosePathString(path)
	print('perform(', path, ')')
	script_started.emit()
	is_playing = true
	await next(true)
	is_playing = false
	script_ended.emit()
	print('finished performing: ', path)
	return ActionResult.new(true, { 'cost_energy': 0 })

func proceed() -> bool:
	_step.emit(true)
	return true

func process(line: String, wait := false) -> bool:
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

func next(async := false) -> bool:
	var line = ''
	
	line = story.Continue()
	line_registered.emit(line)

	if story.GetCurrentChoices().size() > 0:
		current_choices = story.GetCurrentChoices()
		choices_changed.emit(current_choices)

	if line:
		print('next: ', line)
		await process(line, async)

	print(story.GetCanContinue())
	if story.GetCanContinue():
		return await next()
	return true
