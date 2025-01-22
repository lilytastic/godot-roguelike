extends Panel

func _ready():
	Global.player_changed.connect(func(player): _initialize())
	Global.game_loaded.connect(func(): _initialize())
	_initialize()

func _initialize():
	if %InventoryTab:
		%InventoryTab.entity = Global.player
		if Global.player.inventory:
			print('initializing character_menu with ', Global.player.inventory.items)
