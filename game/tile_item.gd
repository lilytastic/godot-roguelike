class_name TileItem
extends Button

var entity: Entity:
	get:
		if stack and stack.entity:
			return Global.ecs.entity(stack.entity)
		return null

@export var slot := ''

var _stack: Dictionary
var stack: Dictionary:
	get:
		return _stack
	set(value):
		if value.entity:
			print(value)
			_stack = value
			_set_slots()
		return value

signal item_dropped

func _get_drag_data(at_position: Vector2) -> Variant:
	if entity:
		return entity.uuid
	return null
	
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data and Global.ecs.entities.has(data):
		return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	print(data)
	item_dropped.emit(data)
	
func _ready():
	_set_slots()
			
func _set_slots():
	var _entity = entity
	if _entity == null:
		if self.icon:
			self.icon = null
		if !disabled:
			disabled = true
	else:
		if !self.icon and _entity.blueprint.glyph:
			self.icon = _entity.glyph.to_atlas_texture()
		if disabled:
			disabled = false
