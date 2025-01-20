class_name SaveSlot
extends Button

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
	print(path)
	Global.save(path)

func _load():
	print('loading ', path)
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var text = file.get_line()
		file.close()
		var json = JSON.new()
		json.parse(text)
		var player_entity = json.data.entities.filter(
			func(entity): return str(entity['uuid']) == str(json.data.player)
		)[0]
		print('player: ' + str(player_entity))
