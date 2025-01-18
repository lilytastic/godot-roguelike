class_name Entity

var uuid: int = ResourceUID.create_id()
var _blueprint: String

var blueprint: Blueprint:
	get:
		return null

func _init(opts: EntityCreationOptions):
	print(opts.blueprint)
	_blueprint = opts.blueprint
	return
