class_name Actor
extends Sprite2D

var entity: Entity:
	get: return Global.ecs.entity(_entityId)
	set(value): self._load(value.uuid)

var _entityId: int

var blueprint: Blueprint:
	get: return entity.blueprint if entity else null

var glyph: Glyph:
	get: return blueprint.glyph
	

func _ready() -> void:
	print('actor ready ', _entityId)
	position = Coords.get_position(
		Coords.get_coord(position),
		Vector2(8, 8)
	)

func _process(delta: float) -> void:
	if entity and entity.position != null:
		position = lerp(
			position,
			Coords.get_position(entity.position, Vector2(8, 8)),
			delta * 30
		)

func _load(id: int):
	_entityId = id
	name = 'Entity<' + str(entity.uuid) + '>'
	position = Coords.get_position(entity.position,  Vector2(8, 8))
	if glyph:
		set_texture(glyph.to_atlas_texture())
		modulate = glyph.fg
