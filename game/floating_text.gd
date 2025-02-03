extends Control

@export var text_prefab = preload('res://game/text_prefab.tscn')


func _ready() -> void:
	Global.floating_text_added.connect(add_text)

# Handle floating damage numbers, tooltips, etc.

func add_text(text: String, position: Vector2, opts := {}):
	var prefab = opts.get('prefab', text_prefab).instantiate()
	add_child(prefab)
	var pos = position + -prefab.size / 2
	prefab.position = pos
	prefab.text = '[center]' + text + '[/center]'
	prefab.modulate = opts.get('color', Color.WHITE)
	prefab._ready()
	return prefab
	
