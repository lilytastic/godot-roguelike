extends ScrollContainer

@export var list: Container
const slot_scene = preload('res://game/save_slot.tscn')
var mode := 'load'

signal slot_pressed
signal slot_hovered

func _ready() -> void:
	update_slots()

func _init() -> void:
	update_slots()


func update_slots() -> Array:
	if !list:
		return []
		
	for child in list.get_children():
		child.queue_free()
	
	var arr := []
	for dict in Global.get_save_slots():
		arr.append(_create_slot(dict.path, dict.type))
	return arr


func _create_slot(path: String, type: String) -> SaveSlot:
	var slot: SaveSlot = slot_scene.instantiate()
	slot.slot_type = type
	slot.path = path
	slot.slot_clicked.connect(func(path: String): _select(path, type))
	slot.slot_hovered.connect(func(path: String): slot_hovered.emit(slot))
	list.add_child(slot)

	if type != 'manual':
		var separator = HSeparator.new()
		list.add_child(separator)
		separator.modulate = Color(1,1,1,0.5)
		if mode == 'save':
			slot.disabled = true
			slot.modulate = Color(slot.modulate, 0.5)

	return slot


func _select(path: String, type: String):
	match mode:
		'load':
			Global.load_game(path)
		'save':
			if type == 'manual':
				Global.save_game(path)
				
	slot_pressed.emit({'path': path, 'type': type})
