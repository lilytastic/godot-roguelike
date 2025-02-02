extends Control

@export var text_prefab = preload('res://game/text_prefab.tscn')

# Handle floating damage numbers, tooltips, etc.

func add_text(text: String, position: Transform2D):
	var prefab = text_prefab.instantiate()
	add_child(prefab)
	var center = %Camera2D.get_screen_center_position()
	var scale = Vector2(get_tree().root.size / get_tree().root.content_scale_size)
	var pos = position.translated(-prefab.size / 2).translated(Vector2(0, -60))
	prefab.position = pos * scale
	prefab.text = '[center]' + text + '[/center]'
	await Global.sleep(1000)
	prefab.queue_free()
