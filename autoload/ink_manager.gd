extends Node

@export var story: InkStory = preload('res://assets/ink/crossroads_godot.ink')

func execute(path: String) -> void:
	story.ChoosePathString(path)
	print('ChoosePathString(', path, ')')
	await next()

func next() -> bool:
	if story.GetCanContinue():
		var result = story.Continue()
		print('Continue(): ', result)
		await Global.sleep(1000)
	if story.GetCurrentChoices().size() > 0:
		return false
	if story.GetCanContinue():
		return await next()
	return true

func perform(path: String) -> ActionResult:
	await execute(path)
	return ActionResult.new(true, { 'cost_energy': 0 })
