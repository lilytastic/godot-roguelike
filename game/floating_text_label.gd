extends Label

var life = 0.0
var lifespan = 1.6
var initial_color = modulate
var initial_scale = scale
var initial_position = position
var last_camera_position = null
var camera_movement = Vector2(0, 0)

func _ready():
	var camera = get_viewport().get_camera_2d()
	last_camera_position = camera.position
	initial_position = position
	initial_scale = scale
	initial_color = modulate
	
func _process(delta):
	life += delta
	var camera = get_viewport().get_camera_2d()
	if last_camera_position:
		camera_movement += last_camera_position - camera.position
	last_camera_position = camera.position
	position = (position - camera_movement).lerp(
		initial_position + Vector2(0, -16),
		delta * 8 * camera.zoom.length()
	) + camera_movement
	modulate = Color(initial_color, sin(life * 3 + 0.5) + 0.3)
	# scale = initial_scale * camera.zoom * (0.6 + sin(life * 3) * 0.5)
	# rotation_degrees += delta * 35
	if life > lifespan:
		queue_free()
	pass
