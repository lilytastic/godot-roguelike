extends Sprite2D

var entity: Entity:
	get:
		return ECS.entity(_entity)

var _entity: int

func load(__entity: int):
	_entity = __entity
	var atlas = AtlasTexture.new()
	atlas.set_atlas(preload('res://monochrome-transparent_packed.png'))
	atlas.region = Rect2(432, 0, 16, 16)
	set_texture(atlas)
	modulate = entity.blueprint.glyph.fg
