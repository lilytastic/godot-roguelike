extends Node

var ecs = ECS.new()
var player: Entity
var maps_loaded: Dictionary = {}

signal player_changed
signal game_saved
signal game_loaded

var is_game_started: bool:
	get: return player != null
	
var map_view: MapView = null
var cursor: Sprite2D = null
var camera: Camera2D = null

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.PALETTE.BACKGROUND)
	Global.ecs.load_data()

func new_game() -> void:
	ecs.clear()
	maps_loaded.clear()
	var options = { 'blueprint': 'hero' }
	player = Entity.new(options)
	player.location = Location.new('Test', Vector2(0,0))
	player.inventory = InventoryProps.new()
	player.inventory.add({
		'entity': Global.ecs.create({ 'blueprint': 'greatsword' }).uuid,
		'num': 1
	})
	player.equipment = EquipmentProps.new({})
	player.equipment.equip(Global.ecs.create({ 'blueprint': 'sword' }))
	player_changed.emit(player)
	Global.ecs.add(player)
	# player.position = Coords.get_position(Vector2i(0, 0))

func clear_game() -> void:
	ecs.clear()
	player = null

func autosave():
	save_game('user://autosave.save')
	return

func quicksave():
	save_game('user://quicksave.save')
	return
	
func get_save_slots() -> Array[Dictionary]:
	var arr: Array[Dictionary] = [
		{'path': 'user://%s.save' % 'quicksave', 'type': 'quicksave'},
		{'path': 'user://%s.save' % 'autosave', 'type': 'autosave'}
	]
	for n in 3:
		var num = str(n+1)
		arr.append({'path': 'user://%s.save' % ('save' + num), 'type': 'manual'})
	return arr
	
func save_game(path: String):
	var data = get_save_data()
	Files.save(data, path)
	game_saved.emit()

func load_game(path: String):
	var data = load_from_save(path)

	if !data:
		return

	ecs.clear()
	var _entities: Array = data.entities
	for _entity in _entities:
		ecs.load_from_save(_entity)
	maps_loaded = data.maps_loaded if data.maps_loaded else {}
	player = ecs.entity(data.player)
		
	player_changed.emit(player)
	game_loaded.emit()

func load_from_save(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var text = file.get_line()
		file.close()
		var json = JSON.new()
		json.parse(text)
		return json.data
	return null
	
func get_save_data() -> Dictionary:
	var data = {}
	data.entities = Global.ecs.entities.keys().map(
		func(entity): return Global.ecs.entity(entity).save()
	)
	data.maps_loaded = maps_loaded
	data.player = player.uuid
	data.date_modified = Time.get_datetime_string_from_system()
	return data
