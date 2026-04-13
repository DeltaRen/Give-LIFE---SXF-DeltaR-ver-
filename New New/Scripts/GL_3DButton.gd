extends Area3D

func interact():
	print("Start Night")
	var target : Player = get_tree().get_first_node_in_group("Player")
	target.night_mode = true
