class_name TileItem
extends Button

@export var slot := ''

var entity: Entity:
	get:
		if stack and stack.entity:
			return Global.ecs.entity(stack.entity)
		return null

var _stack: Dictionary
var stack: Dictionary:
	get:
		return _stack
	set(value):
		_stack = value
		update()
		return value

signal item_dropped


func _get_drag_data(at_position: Vector2) -> Variant:
	if entity:
		PlayerInput.dragging = {
			'entity': entity.uuid,
			'source': slot if slot else 'inventory'
		}
		return entity.uuid
	return null
	
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if PlayerInput.entity_dragging != null:
		return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if PlayerInput.entity_dragging != null:
		print(PlayerInput.dragging, ' -> ', slot if slot else 'inventory')
		item_dropped.emit(PlayerInput.entity_dragging.uuid)
	PlayerInput.dragging = {}
	
func _init():
	update()
	connect('gui_input', on_input)
	
func _exit_tree():
	disconnect('gui_input', on_input)

func on_input(ev: InputEvent):
	if !ev is InputEventMouseButton:
		return
	if ev.double_click:
		PlayerInput.double_click.emit(stack)
	update()

func update():
	var _entity = entity
	if _entity == null:
		_draw_space()
		disabled = true
	else:
		_draw_entity(_entity)
		disabled = false

func _draw_space():
	if slot:
		var atlas = AtlasTexture.new()
		atlas.set_atlas(Glyph.tileset)
		atlas.region = Glyph.get_atlas_region(Glyph.get_slot_glyph(slot))
		self.icon = atlas
	else:
		self.icon = null
	
func _draw_entity(_entity: Entity):
	self.icon = _entity.glyph.to_atlas_texture()
	var glyph = _entity.glyph
	if glyph.fg:
		self.add_theme_color_override(
			'icon_normal_color',
			glyph.fg
		)
