extends TabBar

var trees: Array[SkillTree] = []

func _ready():
	clear_tabs()
	
	var resources = Files.get_all_files('res://data/skills')
	print(resources)
	trees = []
	for resource in resources:
		var tree = load(resource)
		if tree is SkillTree:
			trees.append(tree)
			add_tab(tree.name)
	print(trees)
	

	tab_clicked.connect(
		func(tab: int):
			print(tab)
			%SkillTree.current_tree = trees[tab]
			pass
	)
