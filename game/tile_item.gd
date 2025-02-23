class_name TileItem
extends ListItem

func _draw_entity(_entity: Entity):
	self.icon = _entity.glyph.to_atlas_texture()
	self.text = ''
	var glyph = _entity.glyph
	if glyph.fg:
		self.add_theme_color_override(
			'icon_normal_color',
			glyph.fg
		)
