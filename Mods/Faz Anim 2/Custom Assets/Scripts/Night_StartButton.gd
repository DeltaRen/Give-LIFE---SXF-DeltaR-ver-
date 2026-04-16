extends Area3D

func interact():
	var new_scene_res = load("res://Mods/Faz Anim 2/Custom Assets/Night/FDs Night/FDs Night.tscn")
	var new_scene = new_scene_res.instantiate()
	var root = get_tree().root
	root.add_child(new_scene)
	get_tree().current_scene = new_scene
	for child in root.get_children():
		if child != new_scene:
			child.queue_free()
