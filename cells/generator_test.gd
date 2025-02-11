extends Node2D

@export var packed_scene: PackedScene = null

func _input(ev: InputEvent):
	if ev is InputEventMouseButton and ev.is_released():
		for child in %Generator.get_children():
			child.queue_free()
		%Generator.add_child(packed_scene.instantiate())
