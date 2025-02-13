extends Node2D

@export var packed_scene: PackedScene = null

func _ready():
	for child in %Generator.get_children():
		child.queue_free()
	var new_generator = packed_scene.instantiate()
	%Generator.add_child(new_generator)
	new_generator.generate(randi_range(0,99999999), 3)


func _input(ev: InputEvent):
	if ev is InputEventMouseButton and ev.is_released():
		_ready()
