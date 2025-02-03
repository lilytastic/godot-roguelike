extends RichTextLabel

var life = 0.0
var lifespan = 1.6
var initial_color = modulate
var initial_scale = scale
var initial_position = position

func _ready():
	print(text, modulate)
	initial_position = position
	initial_scale = scale
	initial_color = modulate
	
func _process(delta):
	life += delta
	position = position.lerp(initial_position + Vector2(0, -64), delta * 8)
	modulate = Color(initial_color, sin(life * 3 + 0.5) + 0.1)
	scale = initial_scale * (0.6 + sin(life * 3) * 0.5)
	rotation_degrees += delta * 35
	if life > lifespan:
		queue_free()
	pass
