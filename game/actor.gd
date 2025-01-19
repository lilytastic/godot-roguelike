extends Sprite2D

var entity: Entity:
	get: return ECS.entity(_entityId)
	set(value): load(value.id)

var _entityId: int

var blueprint: Blueprint:
	get: return entity.blueprint

var glyph: Glyph:
	get: return blueprint.glyph


func _process(delta: float) -> void:
	if entity and entity.position != null:
		position = lerp(position, Coords.get_position(entity.position), delta * 30)


func load(id: int):
	_entityId = id
	if glyph:
		set_texture(glyph.to_atlas_texture())
		modulate = glyph.fg
