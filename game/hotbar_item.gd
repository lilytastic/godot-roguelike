class_name HotbarItem
extends Button

@export var label = '';
@export var hotkey = '';
@export var atlas_coords = Vector2(0,0);

func _process(delta):
	%Label.text = label
	%Hotkey.text = hotkey
	%TextureRect.texture.region = Rect2(atlas_coords.x * 16, atlas_coords.y * 16, 16, 16)
