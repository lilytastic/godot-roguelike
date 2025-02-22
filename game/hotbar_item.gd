class_name HotbarItem
extends Button

@export var label = '';
@export var hotkey = '';
@export var atlas_coords = Vector2(0,0);

func _ready():
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = %TextureRect.texture.atlas
	%TextureRect.texture = atlas_texture

func _process(delta):
	%Label.text = label
	%Hotkey.text = hotkey
	%TextureRect.texture.region = Rect2(atlas_coords.x, atlas_coords.y, 16, 16)
