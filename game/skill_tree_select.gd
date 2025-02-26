extends TabBar

var skill_trees := []

func _init():
	clear_tabs()
	
	skill_trees = AgentManager.skill_trees.values().filter(func(tree): return tree.is_visible)
	skill_trees.sort_custom(func(a, b): return a.sort_order < b.sort_order)
	for tree in skill_trees:
		add_tab(tree.name)
