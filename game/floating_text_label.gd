extends RichTextLabel

var life = 0.0
var lifespan = 2
var initial_color = modulate
var initial_position = position

func _ready():
	print(text, modulate)
	initial_position = position
	initial_color = modulate
	
func _process(delta):
	life += delta
	position = position.lerp(initial_position + Vector2(0, -20), delta * 4)
	modulate = Color(initial_color, 1 - life / lifespan)
	if life > lifespan:
		queue_free()
	pass
