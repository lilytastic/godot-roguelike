class_name SaveSlot
extends Button

signal slot_clicked

var _path = ''
var path : String:
	get: return _path
	set(value):
		_path = value
		_load()

func _ready():
	Global.game_saved.connect(func(data, path): _load())
	self.connect('pressed', func(): _click())
	
func _click():
	slot_clicked.emit(path)
	# Global.save(path)

func _load():
	var data = Global.load_from_save(path)
	if data:
		var player_entity = data.entities.filter(
			func(entity):
				return str(entity['uuid']) == str(data.player)
		)[0]
		print('save slot: ' + str(player_entity))
