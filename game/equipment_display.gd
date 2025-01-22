extends HBoxContainer

var _entity: Entity
var entity: Entity:
	get: return _entity
	set(value):
		_entity = value
		_initialize_slots()

func _ready():
	_initialize_slots()
	
func _initialize_slots():
	if entity:
		print('initialized equipment display with ', entity.uuid)
