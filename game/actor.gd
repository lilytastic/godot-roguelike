class_name Actor
extends Node2D

var entity: Entity:
	get: return Global.ecs.entity(_entityId)
	set(value): self._load(value.uuid)

var _entityId: int

var blueprint: Blueprint:
	get: return entity.blueprint if entity else null

var glyph: Glyph:
	get: return blueprint.glyph if blueprint else null

signal destroyed

func _ready() -> void:
	# snap to grid
	position = Coords.get_position(
		Coords.get_coord(position),
		Vector2(0, 0)
	)
	if blueprint and blueprint.equipment:
		z_index = 1

func _process(delta: float) -> void:
	if entity:
		if !entity.location:
			destroyed.emit()
			queue_free()
		else:
			position = lerp(
				position,
				Coords.get_position(entity.location.position, Vector2(0, 0)),
				delta * 30
			)
	if glyph:
		modulate = modulate.lerp(glyph.fg, delta * 15)

func _load(id: int):
	_entityId = id
	name = 'Entity<' + str(entity.uuid) + '>'
	if entity.location:
		position = Coords.get_position(entity.location.position,  Vector2(0, 0))
	if glyph:
		if %Sprite2D:
			%Sprite2D.set_texture(glyph.to_atlas_texture())
		modulate = glyph.fg
	if entity.health:
		entity.health_changed.connect(
			func(amount):
				modulate = Color(1,0,0)
		)
	entity.on_death.connect(
		func():
			await get_tree().create_timer(0.1).timeout
			queue_free()
	)
