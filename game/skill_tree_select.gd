extends TabBar

func _ready():
	tab_clicked.connect(
		func(tab: int):
			print(tab)
			%SkillTree.current_tree = tab
			pass
	)
