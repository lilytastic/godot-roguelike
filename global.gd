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
	save('user://autosave.save')
	return

func quicksave():
	save('user://quicksave.save')
	return
	
func save(path: String):
	var data = get_save_data()
	Files.save(data, path)
	game_saved.emit(data, path)
	
func get_save_data() -> Dictionary:
	var data = {}
	data.entities = Global.ecs.entities.values().map(
		func(entity): return entity.save()
	)
	data.player = player.uuid
	return data
