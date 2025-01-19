extends Node

var ecs = ECS.new()
var player: Entity

signal player_changed


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
	save()
	

func save() -> void:
	var data = {}
	data.entities = Global.ecs.entities.values().map(
		func(entity): return entity.save()
	)
	data.player = player.uuid
	Files.save(data)
