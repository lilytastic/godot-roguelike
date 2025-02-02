extends Control

@export var text_prefab = preload('res://game/text_prefab.tscn')

# Handle floating damage numbers, tooltips, etc.

func add_text(text: String, position: Vector2):
	var prefab = text_prefab.instantiate()
	add_child(prefab)
	var pos = position + -prefab.size / 2 + Vector2(0, -60)
	prefab.position = pos
	prefab.text = '[center]' + text + '[/center]'
	await Global.sleep(1000)
	prefab.queue_free()
