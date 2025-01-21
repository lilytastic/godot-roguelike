extends Button

var entity: Entity # Global.ecs.create({ 'blueprint': 'sword' })

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
	if self.icon and entity == null:
		self.icon = null
