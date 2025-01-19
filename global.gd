extends Node

var ecs = ECS.new()
var player: Entity

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.PALETTE.BACKGROUND)
	Global.ecs.load_data()
  

func new_game() -> void:
	var options = EntityCreationOptions.new()
	options.blueprint = 'hero'
	player = Global.ecs.create(options)
	player.map = 'Test'
	# player.position = Coords.get_position(Vector2i(0, 0))
	save()
	

func save() -> void:
	var data = {}
	data.entities = Global.ecs.entities.values().map(
		func(entity): return entity.save()
	)
	data.player = player.uuid
	Files.save(data)


func move_pc(direction: StringName) -> void:
	if !player:
		return

	var coord: Vector2i = player.position
	
	match direction:
		InputTag.MOVE_LEFT:
			coord += Vector2i.LEFT
		InputTag.MOVE_RIGHT:
			coord += Vector2i.RIGHT
		InputTag.MOVE_UP:
			coord += Vector2i.UP
		InputTag.MOVE_DOWN:
			coord += Vector2i.DOWN

	player.position = coord
