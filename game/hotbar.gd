extends HBoxContainer

func _process(delta):
	if Global.player:
		var target = ECS.entity(Global.player.targeting.current_target)
		var abilities = AgentManager.get_abilities(Global.player, target)
		var i = 0
		for child in get_children():
			if abilities.size() > i:
				var dict = abilities[i]
				var ability = ECS.abilities[dict.ability]
				if child is HotbarItem:
					var atlas_rect = Glyph.get_atlas_region(ability.icon.sprite)
					child.atlas_coords = Vector2(atlas_rect.position.x, atlas_rect.position.y)
					pass
				i += 1
			else:
				if child is HotbarItem:
					child.atlas_coords = Vector2(0, 0)
					pass
	pass
	
