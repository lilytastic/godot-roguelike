extends HBoxContainer

func _ready():
	var i = 0
	for child in get_children():
		if child is HotbarItem:
			var n = i
			child.pressed.connect(
				func():
					_on_click(n)
			)
			i += 1

func _on_click(index: int):
	var abilities = AgentManager.get_abilities(Global.player)
	if !Global.player or abilities.size() <= index:
		return

	var ability = abilities[index]
	var dict = { "target": ECS.entity(PlayerInput.targeting.current_target) }
	dict.merge(ability)
	var result = await PlayerInput.trigger_action(
		UseAbilityAction.new(
			ability.ability,
			dict
		)
	)

func _input(event: InputEvent):
	var i = 0
	var key_i = 1
	for child in get_children():
		if child is HotbarItem:
			if event.is_action_pressed('num_' + str(key_i)):
				_on_click(i)
			key_i += 1
		if key_i > 9:
			key_i = 0
		i += 1
	pass

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
	
