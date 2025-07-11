extends Node

var entities := {}
var blueprints := {}
var abilities := {}

signal entity_added
signal entity_removed


func _ready() -> void:
	ECS.load_data()


func entity(id: String) -> Entity:
	if (entities.has(id)):
		return entities[id]
	return null

func add(_entity: Entity) -> String:
	entities[_entity.uuid] = _entity
	print('[ecs] added: ', _entity.blueprint.name, ' (', _entity.uuid, ')')
	entity_added.emit(_entity)
	return _entity.uuid

func remove(uuid: String) -> void:
	entity_removed.emit(uuid)
	print('[ecs] removed: ', uuid)
	entities.erase(uuid)
	
func load_from_save(data: Dictionary) -> void:
	var opts = { 'uuid': data.uuid, 'blueprint': data.blueprint }
	var entity = Entity.new(opts)
	entity.load_from_save(data)
	
func clear() -> void:
	entities.clear()
	
func create(opts: Dictionary) -> Entity:
	var new_entity = Entity.new(opts)
	var new_id = add(new_entity)
	return entity(new_id)

func load_data() -> void:
	var resources = Files.get_all_files('res://data')
	blueprints = Blueprint.load_from_files(resources)
	abilities = Ability.load_from_files(resources)

func find_by_location(location: Location) -> Array:
	return entities.values().filter(
		func(entity):
			if !entity.location:
				return false
			if entity.location.map == location.map and entity.location.position.x == location.position.x and entity.location.position.y == location.position.y:
				return true
	)
