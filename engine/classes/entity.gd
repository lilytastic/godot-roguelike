class_name Entity

var _uuid: int = 0
var uuid: int:
	get: return _uuid
	set(value):
		Global.ecs.entities.erase(_uuid)
		_uuid = value
var _blueprint: String
var location := Location.new()

signal map_changed

var map: String:
		get: return location.map
		set(value):
			location.map = value
			map_changed.emit(location.map)

var position: Vector2:
		get: return location.position
		set(value):
			location.position = value

# var inventory: { uuid: int, stack: int }[]

var blueprint: Blueprint:
	get: return Global.ecs.blueprints.get(_blueprint, null)
	set(value): _blueprint = value.id


func _init(opts: Dictionary):
	print('Initializing entity with template: ', opts.blueprint)
	_blueprint = opts.blueprint
	uuid = opts.uuid if opts.has('uuid') else ResourceUID.create_id()
	return


func save() -> Dictionary:
	var dict := {}
	dict.blueprint = _blueprint
	dict.map = location.map
	dict.position = position
	dict.uuid = uuid
	return dict
