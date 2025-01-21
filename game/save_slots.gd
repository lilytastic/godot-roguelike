extends VBoxContainer

const slot_scene = preload('res://game/save_slot.tscn')
var mode := 'load'

func _init() -> void:
	for dict in Global.get_save_slots():
		_create_slot(dict.path, dict.type)


func _create_slot(path: String, type: String):
	var slot = slot_scene.instantiate()
	slot.slot_type = type
	slot.path = path
	slot.slot_clicked.connect(func(path: String): _select(path))
	add_child(slot)
	return slot


func _select(path: String):
	match mode:
		'load':
			Global.load_game(path)
		'save':
			Global.save_game(path)
