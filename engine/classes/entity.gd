class_name Entity

var _uuid: String = ''
var uuid: String:
	get: return _uuid
	set(value):
		ECS.entities.erase(_uuid)
		_uuid = value

var _blueprint: String
var blueprint: Blueprint:
	get: return ECS.blueprints.get(_blueprint, null)
	set(value): _blueprint = value.id

var _glyph: Glyph = null
var glyph: Glyph:
	get: return _glyph if _glyph else blueprint.glyph if blueprint else null
	set(value):
		_glyph = value

var location: Location = null
var inventory: InventoryProps = null
var equipment: EquipmentProps = null
var targeting: Targeting = null
var actor: Actor = null
var destination: Dictionary = {}

var health: Meter = null

var energy := 0.00
var is_acting = false
var is_touched = false

var visible_tiles := {}
var known_entity_locations := {}

var animation: AnimationSequence = null

var screen_position: Vector2:
	get:
		if !actor:
			return Vector2(0,0)
		return actor.get_global_transform_with_canvas().origin

signal map_changed
signal health_changed
signal on_death
signal action_performed

const uuid_util = preload('res://addons/uuid/uuid.gd')


func _init(opts: Dictionary):
	_blueprint = opts.blueprint
	uuid = opts.uuid if opts.has('uuid') else uuid_util.v4()
	targeting = Targeting.new()

	if blueprint.baseHP:
		health = Meter.new(20)
		health_changed.connect(
			func(amount):
				if !health or health.current <= 0:
					on_death.emit()
		)
		
	update_fov()


func update_fov():
	if Global.player and uuid != Global.player.uuid:
		return
	if !MapManager.current_map or !location or MapManager.current_map.uuid != location.map:
		return # Don't update for things that aren't here!
		
	var max_vision = 8
	visible_tiles.clear()
	FOV.compute_fov(
		location.position,
		func(tile): return !MapManager.can_walk(tile),
		func(tile):
			if Global.player and Global.player.uuid == uuid and MapManager.current_map:
				if Global.player.location.position.distance_to(tile) > max_vision:
					return
				MapManager.current_map.tiles_known[tile] = true
				visible_tiles[tile] = true
	)
	_update_known_entities()


func _update_known_entities():
	for actor in MapManager.actors.keys():
		var actor_entity = MapManager.actors[actor]
		if !actor_entity or !actor_entity.location:
			if known_entity_locations.has(actor):
				known_entity_locations.erase(actor)
			continue
		if visible_tiles.has(Vector2i(actor_entity.location.position)):
			known_entity_locations[actor] = Vector2i(actor_entity.location.position)
		if known_entity_locations.has(actor):
			if visible_tiles.has(Vector2i(known_entity_locations[actor])) and known_entity_locations[actor] != Vector2i(actor_entity.location.position):
				known_entity_locations.erase(actor)


func change_location(_location: Location):
	location = _location
	map_changed.emit(location.map)
	MapManager.entity_moved.emit(uuid)

func save() -> Dictionary:
	var dict := {}
	
	dict.uuid = uuid
	dict.blueprint = _blueprint
	dict.energy = energy
	if location:
		dict.map = location.map
		dict.position = location.position
	if inventory: dict.inventory = inventory.save()
	if equipment: dict.equipment = equipment.save()
	if destination: dict.destination = destination
	if known_entity_locations: dict.known_entity_locations = known_entity_locations
	if health: dict.health = health.current

	return dict

func load_from_save(data: Dictionary) -> void:
	var new_id = ECS.add(self)
	var json = JSON.new()
	
	if data.has('position'):
		var _pos = Global.string_to_vector(data.position)
		change_location(Location.new(data.map, _pos))

	energy = data.energy if data.has('energy') else 0
	
	if data.has('inventory'): inventory = InventoryProps.new(data.inventory)
	if data.has('equipment'): equipment = EquipmentProps.new(data.equipment)
	if data.has('destination'):
		destination = data.get('destination', {})
		if destination.has('position'):
			destination.position = Global.string_to_vector(destination.position)
	if data.has('known_entity_locations'): known_entity_locations = data.get('known_entity_locations', {})
	for entity in known_entity_locations:
		known_entity_locations[entity] = Global.string_to_vector(known_entity_locations[entity])
	if data.has('health'): health.current = data.health
	
	update_fov()


func damage(opts: Dictionary):
	var damage = opts.get('damage', 1)
	if health:
		health.deduct(damage)
		var source = opts.get('source', null)
		health_changed.emit(-damage)
		if source and (source.uuid == Global.player.uuid or uuid == Global.player.uuid):
			PlayerInput.camera_shake += (location.position - source.location.position).normalized() * 2
		if damage > 0:
			await Global.sleep(150)
			Global.add_floating_text(
				str(damage),
				screen_position + Vector2.UP * 12,
				{ 'color': Color('d92139') }
			)


static func init_from_node(node: Node2D):
	var opts = {
		'blueprint': node.get_meta('blueprint', 'quadropus')
	}
	var props = node.get_meta('props', {})

	var new_entity = Entity.new(opts)
	var coords = Coords.get_coord(node.position)
	if new_entity.location:
		new_entity.location.position = coords
	else: 
		new_entity.location = Location.new('', coords)
	for prop in props:
		new_entity[prop] = props[prop]

	return new_entity
