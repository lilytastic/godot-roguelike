extends Control

@export var text_prefab = preload('res://game/text_prefab.tscn')

# Handle floating damage numbers, tooltips, etc.

func add_text(text: String, position: Vector2):
	var prefab = text_prefab.instantiate()
	add_child(prefab)
	var pos = position + -prefab.size / 2
	prefab.position = pos
	prefab.text = '[center]' + text + '[/center]'
	queue_for_deletion(prefab)
	return prefab
	
func queue_for_deletion(prefab):
	await Global.sleep(1000)
	prefab.queue_free()
