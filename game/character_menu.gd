extends Panel

func _ready():
	_initialize()
	Global.player_changed.connect(func(player): _initialize())
	Global.game_loaded.connect(func(): _initialize())

func _initialize():
	if %Inventory:
		%Inventory.entity = Global.player
		if Global.player and Global.player.inventory:
			print('initializing character_menu with ', Global.player.uuid)
	
