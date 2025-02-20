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

var directions = [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.PALETTE.BACKGROUND)
	

func new_game() -> Entity:
	if has_game_started:
		clear_game()
	MapManager.maps_loaded.clear()
	MapManager.maps.clear()
	MapManager.map = ''

	player = Entity.new({ 'blueprint': 'hero' })
	player.inventory = InventoryProps.new()
	player.inventory.add({
		'entity': ECS.create({ 'blueprint': 'greatsword' }).uuid,
		'num': 1
	})
	player.equipment = EquipmentProps.new({})
	player.equipment.equip(ECS.create({ 'blueprint': 'sword' }))
	player_changed.emit(player)
	ECS.add(player)
	
	"""
	var starting_map = await MapManager.resolve_destination({
		'branch': 'privateers_hideout',
		'depth': 1,
		'connections': [{'prefab': 'test'}]
	}, player)
	"""
	var starting_map = await MapManager.resolve_destination({
		'worldspace': 'domino',
		'cell': Vector2i(0, 0),
		'connections': [{'branch': 'privateers_hideout', 'depth': 1 }]
	}, player)
	MapManager.teleport(starting_map, player)
	print('created starting_map: ', starting_map)

	has_game_started = true
	return player

func clear_game() -> void:
	ECS.clear()
	Scheduler.finish_turn()
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
	
func get_save_data() -> Dictionary:
	var data = {}
	data.entities = ECS.entities.keys().map(
		func(entity): return ECS.entity(entity).save()
	)
	data.maps = MapManager.get_save_data()
	data.player = player.uuid
	data.date_modified = Time.get_datetime_string_from_system()
	return data

func load_game(path: String):
	PlayerInput.overlay_opacity = 1.0
	var data = load_from_save(path)

	if !data:
		return

	clear_game()
	
	if data.maps:
		if data.maps.maps_loaded:
			var _dict := {}
			for __id in data.maps.maps_loaded:
				_dict[__id] = true
			MapManager.maps_loaded = _dict
		if data.maps.maps:
			var maps = data.maps.maps
			for map_data in maps:
				MapManager.add(await Map.load_from_data(map_data))
	
	var _entities: Array = data.entities
	for _entity in _entities:
		ECS.load_from_save(_entity)

	player = ECS.entity(data.player)

	MapManager.switch_map(MapManager.maps[player.location.map], player)

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
	

func sleep(ms: float) -> void:
	await get_tree().create_timer(ms / 1000).timeout


func add_floating_text(text: String, position: Vector2, opts := {}):
	floating_text_added.emit(text, position, opts)

func string_to_vector(str) -> Vector2i:
	if str is Vector2i:
		return str
	if str is Vector2:
		return Vector2(str)
	var coords = str.substr(1, str.length() - 2).split(',')
	if coords.size() < 2:
		return Vector2i(0,0)
	return Vector2i(int(coords[0]), int(coords[1]))
