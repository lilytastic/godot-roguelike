extends Button

var entity: Entity:
	get: return Global.ecs.entity(stack.entity) if stack and stack.entity else null

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
	stack = {
		'entity': data
	}
	
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
