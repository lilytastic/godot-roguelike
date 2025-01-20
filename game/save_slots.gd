extends VBoxContainer

const slot_scene = preload('res://game/save_slot.tscn')

func _init() -> void:
	var quicksave = _create()
	quicksave.text = 'Quicksave'
	quicksave.path = 'user://%s.save' % 'quicksave'
	var autosave = _create()
	autosave.text = 'Autosave'
	autosave.path = 'user://%s.save' % 'autosave'
	for n in 3:
		var slot = _create()
		slot.text = 'Save ' + str(n + 1)
		slot.path = 'user://%s.save' % ('save' + str(n+1))

func _create(slot := slot_scene.instantiate()) -> SaveSlot:
	add_child(slot)
	return slot
