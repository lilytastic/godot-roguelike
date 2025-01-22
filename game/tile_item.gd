extends Button

var entity: Entity:
	get: return Global.ecs.entity(stack.entity) if stack and stack.entity else null
var stack: Dictionary

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
	entity = Global.ecs.entity(data)
	
func _process(delta):
	if entity == null:
		if self.icon:
			self.icon = null
		if !disabled:
			disabled = true
	else:
		if disabled:
			disabled = false
