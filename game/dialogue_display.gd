extends VBoxContainer

var current_line = ''

func _ready():
	visible = false
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

func _input(event: InputEvent) -> void:
	if event.is_pressed() or event.is_action_pressed('dialogue_next'):
		InkManager.proceed()
