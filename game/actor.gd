class_name Actor
extends Sprite2D

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
	print('actor ready ', _entityId)
	Global.ecs.entity_removed.connect(
		func(uuid):
			if uuid == _entityId:
				queue_free()
	)
	# snap to grid
	position = Coords.get_position(
		Coords.get_coord(position),
		Vector2(8, 8)
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
				Coords.get_position(entity.location.position, Vector2(8, 8)),
				delta * 30
			)

func _load(id: int):
	_entityId = id
	name = 'Entity<' + str(entity.uuid) + '>'
	if entity.location:
		position = Coords.get_position(entity.location.position,  Vector2(8, 8))
	if glyph:
		set_texture(glyph.to_atlas_texture())
		modulate = glyph.fg
