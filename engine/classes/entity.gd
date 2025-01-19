class_name Entity

var uuid: int = ResourceUID.create_id()
var _blueprint: String
var location := Location.new()

signal map_changed

var map: String:
		get: return location.map
		set(value):
			location.map = value
			map_changed.emit(location.map)

var position: Vector2:
		get: return location.position if location.position else Vector2(0,0)
		set(value):
			location.position = value

# var inventory: { uuid: int, stack: int }[]

var blueprint: Blueprint:
	get: return Global.ecs.blueprints.get(_blueprint, null)
	set(value): _blueprint = value.id


func _init(opts: EntityCreationOptions):
	print('Initializing entity with template: ', opts.blueprint)
	_blueprint = opts.blueprint
	return


func save() -> Dictionary:
	var dict := {}
	dict.blueprint = _blueprint
	dict.map = location.map
	dict.position = position
	dict.uuid = uuid
	return dict
