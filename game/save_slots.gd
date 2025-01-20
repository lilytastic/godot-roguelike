extends VBoxContainer

const slot_scene = preload('res://game/save_slot.tscn')
var mode := 'load'

func _init() -> void:
	var quicksave = _create_slot('quicksave', 'Quicksave')
	var autosave = _create_slot('autosave', 'Autosave')
	for n in 3:
		var num = str(n+1)
		var slot = _create_slot('save' + num, 'Save ' + num)


func _create_slot(path: String, type: String):
	var slot = slot_scene.instantiate()
	slot.text = type
	slot.path = 'user://%s.save' % path
	slot.slot_clicked.connect(func(path: String): _select(path))
	add_child(slot)
	return slot


func _select(path: String):
	match mode:
		'load':
			Global.load_game(path)
		'save':
			Global.save_game(path)
