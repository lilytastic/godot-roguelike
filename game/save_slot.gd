class_name SaveSlot
extends Button

signal slot_clicked

var slot_type := 'Manual Save':
	set(value):
		slot_type = value

var _path = ''
var path: String:
	get: return _path
	set(value):
		_path = value
		_load()

func _ready():
	Global.game_saved.connect(func(): _load())
	self.connect('pressed', func(): _click())
	
func _click():
	slot_clicked.emit(path)
	# Global.save(path)

func _load():
	%TopLeft.text = ''
	%TopRight.text = ''
	%BottomLeft.text = ''
	%BottomRight.text = ''
	%Center.text = ''
	var data = Global.load_from_save(path)
	if data:
		var player_entity = data.entities.filter(
			func(entity):
				return entity['uuid'] == data.player
		)[0]
		var current_map = data.maps.maps[data.maps.maps.find(func(x): x.uuid == player_entity.map)]
		%TopLeft.text = ('%s - ' % current_map.name if current_map else '<Unknown Map>') + slot_type
		if data.has('date_modified'):
			var dict = Time.get_datetime_dict_from_datetime_string(data.date_modified, false)
			var minute = str(dict.minute) if dict.minute >= 10 else ('0'+str(dict.minute))
			var day = str(dict.day) if dict.day >= 10 else ('0'+str(dict.day))
			var date = str(dict.month) + '/' + day + '/' + str(dict.year) + ' ' + str(dict.hour) + ':' + minute
			%BottomRight.text = '[right]%s[/right]' % date
	else:
		%Center.text = '[center]No data[/center]'

func round_place(num,places):
	return (round(num*pow(10,places))/pow(10,places))
