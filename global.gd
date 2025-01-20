extends Node

var ecs = ECS.new()
var player: Entity

signal player_changed
signal game_saved

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.PALETTE.BACKGROUND)
	Global.ecs.load_data()
  

func new_game() -> void:
	var options = EntityCreationOptions.new()
	options.blueprint = 'hero'
	player = Global.ecs.create(options)
	player.map = 'Test'
	player_changed.emit(player)
	# player.position = Coords.get_position(Vector2i(0, 0))

func autosave():
	print('autosave')
	save_game('user://autosave.save')
	return

func quicksave():
	save_game('user://quicksave.save')
	return
	
func save_game(path: String):
	var data = get_save_data()
	Files.save(data, path)
	game_saved.emit(data, path)

func load_game(path: String):
	var data = load_from_save(path)

	if !data:
		print('no data at ', path)
		return

	print('loading game: ' + str(data))

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
	data.entities = Global.ecs.entities.values().map(
		func(entity): return entity.save()
	)
	data.player = player.uuid
	return data
