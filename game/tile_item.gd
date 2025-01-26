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
		set_slots()
		return value

signal item_dropped
signal double_click


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
	set_slots()
	connect('gui_input', on_input)
	
func _exit_tree():
	disconnect('gui_input', on_input)

func on_input(ev: InputEvent):
	if !ev is InputEventMouseButton:
		return
	if ev.double_click:
		double_click.emit(stack)
	set_slots()

func set_slots():
	var _entity = entity
	if _entity == null:
		if slot:
			var atlas = AtlasTexture.new()
			atlas.set_atlas(Glyph.tileset)
			var glyph = 'G_SWORD'
			match slot:
				'main hand':
					glyph = 'G_SWORD'
				'off-hand':
					glyph = 'G_DAGGER'
				'amulet':
					glyph = 'G_AMULET'
				'ring1':
					glyph = 'G_RING'
				'ring2':
					glyph = 'G_RING_ALT'
				'head':
					glyph = 'G_HELMET'
				'back':
					glyph = 'G_CLOAK'
				'torso':
					glyph = 'G_ARMOR'
				'hands':
					glyph = 'G_GLOVES'
				'feet':
					glyph = 'G_BOOTS'
			atlas.region = Glyph.get_atlas_region(glyph)
			self.icon = atlas
		else:
			self.icon = null
		disabled = true
	else:
		self.icon = _entity.glyph.to_atlas_texture()
		disabled = false
