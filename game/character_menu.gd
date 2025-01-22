extends Panel

const CHARACTER: StringName = &"CHARACTER"
const INVENTORY: StringName = &"INVENTORY"
const JOURNAL: StringName = &"JOURNAL"

var _current_tab := INVENTORY
var current_tab: String:
	get: return _current_tab
	set(value):
		_current_tab = value
		_tab_changed()

signal tab_changed


func _ready():
	Global.player_changed.connect(func(player): _initialize())
	Global.game_loaded.connect(func(): _initialize())
	tab_changed.connect(func(tab): _tab_changed())
	%CharacterTab.pressed.connect(func(): current_tab = CHARACTER)
	%InventoryTab.pressed.connect(func(): current_tab = INVENTORY)
	%JournalTab.pressed.connect(func(): current_tab = JOURNAL)
	_initialize()

func _tab_changed():
	%CharacterTab.modulate = Color(1,1,1,0.5)
	%InventoryTab.modulate = Color(1,1,1,0.5)
	%JournalTab.modulate = Color(1,1,1,0.5)
	%CharacterMenu.visible = current_tab == CHARACTER
	%InventoryMenu.visible = current_tab == INVENTORY
	%JournalMenu.visible = current_tab == JOURNAL

	match current_tab:
		CHARACTER:
			%CharacterTab.modulate = Color(1,1,1,1)
			return
		INVENTORY:
			%InventoryTab.modulate = Color(1,1,1,1)
			return
		JOURNAL:
			%JournalTab.modulate = Color(1,1,1,1)
			return

func _initialize():
	if %InventoryMenu:
		%InventoryMenu.entity = Global.player
		if Global.player and Global.player.inventory:
			print('initializing character_menu with ', Global.player.uuid)
	
	_tab_changed()
