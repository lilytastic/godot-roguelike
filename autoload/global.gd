extends Node

var player: Entity

var ui_visible := false

const STEP_LENGTH = 0.15

signal player_changed
signal game_saved
signal game_loaded
signal floating_text_added

var has_game_started = false
var is_game_started: bool:
	get: return player != null


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.PALETTE.BACKGROUND)
	ECS.load_data()

func new_game() -> Entity:
	if has_game_started:
		ECS.clear()
	MapManager.maps_loaded.clear()
	var options = { 'blueprint': 'hero' }
	player = Entity.new(options)
	var starting_map = MapManager.add(Map.new('Test'))
	player.location = Location.new(starting_map.uuid, Vector2(0,0))
	print(player.location.map)
	player.inventory = InventoryProps.new()
	player.inventory.add({
		'entity': ECS.create({ 'blueprint': 'greatsword' }).uuid,
		'num': 1
	})
	player.equipment = EquipmentProps.new({})
	player.equipment.equip(ECS.create({ 'blueprint': 'sword' }))
	player_changed.emit(player)
	ECS.add(player)
	has_game_started = true
	MapManager.switch_map(starting_map)
	return player
	# player.position = Coords.get_position(Vector2i(0, 0))

func clear_game() -> void:
	ECS.clear()
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
	print(data)

	if !data:
		return

	ECS.clear()
	
	print('maps loaded: ', data.maps)
	if data.maps:
		if data.maps.maps_loaded:
			var _dict := {}
			for __id in data.maps.maps_loaded:
				_dict[__id] = true
			MapManager.maps_loaded = _dict
		if data.maps.maps:
			var maps = data.maps.maps
			print(maps)
			for map_data in maps:
				MapManager.add(Map.load_from_data(map_data))
	print(MapManager.maps_loaded)
	
	var _entities: Array = data.entities
	for _entity in _entities:
		ECS.load_from_save(_entity)
	var new_maps := {}

	player = ECS.entity(data.player)
	
	print(player.location.map)

	MapManager.switch_map(MapManager.maps[player.location.map])

	player_changed.emit(player)
	game_loaded.emit()

func load_from_save(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var text = file.get_line()
		file.close()
		var json = JSON.new()
		json.parse(text)
		print(json.data)
		return json.data
	return null
	
func get_save_data() -> Dictionary:
	var data = {}
	data.entities = ECS.entities.keys().map(
		func(entity): return ECS.entity(entity).save()
	)
	data.maps = MapManager.get_save_data()
	data.player = player.uuid
	data.date_modified = Time.get_datetime_string_from_system()
	return data

func sleep(ms: float) -> void:
	await get_tree().create_timer(ms / 1000).timeout
	
func add_floating_text(text: String, position: Vector2, opts := {}):
	floating_text_added.emit(text, position, opts)
