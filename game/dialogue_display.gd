extends VBoxContainer

var current_line = ''
var current_choices := []

var choice_button = preload('res://game/dialogue_choice_button.tscn')

func _ready():
	visible = false

	for child in %ChoiceList.get_children():
		child.queue_free()

	InkManager.script_started.connect(
		func():
			visible = true
	)
	InkManager.script_ended.connect(
		func():
			visible = false
	)
	InkManager.line_processed.connect(
		func(line):
			current_line = line
			%DialogueText.text = line
			print(line)
	)
	InkManager.choices_changed.connect(
		func(choices):
			current_choices = InkManager.story.GetCurrentChoices()
			print('choices changed: ', current_choices)
			for child in %ChoiceList.get_children():
				child.queue_free()
			for choice in current_choices:
				var button = choice_button.instantiate()
				button.text = choice.Text
				print(button.text)
				%ChoiceList.add_child(button)
				button.pressed.connect(
					func():
						for child in %ChoiceList.get_children():
							child.queue_free()
						InkManager.choose(choice)
				)
	)

func _input(event: InputEvent) -> void:
	if event.is_pressed() or event.is_action_pressed('dialogue_next'):
		InkManager.proceed()
