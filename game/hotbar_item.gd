extends Button

@export var label = '';
@export var hotkey = '';

func _process(delta):
	%Label.text = label
	%Hotkey.text = hotkey
