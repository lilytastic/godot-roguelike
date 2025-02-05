extends Node2D

var _fov_map := {}
var last_position: Vector2


func _ready() -> void:
	get_viewport().connect("size_changed", render)
	render()
	
func _process(delta):
	if last_position != Global.player.location.position:
		last_position = Global.player.location.position
		render()


func render() -> void:
	for child in get_children():
		child.free()
	
	if !MapManager.map_view:
		return

	var tiles = MapManager.map_view.get_used_cells().filter(
		func(tile):
			# TODO: filter for visible area
			return Global.player and AIManager.can_see(Global.player, tile) # tile.y == Global.player.location.position.y or tile.x == Global.player.location.position.x
	)

	for tile in tiles:
		add_child(MapTile.generate_tile(tile, MapManager.map_view))
