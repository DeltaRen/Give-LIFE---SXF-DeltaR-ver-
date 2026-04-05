extends Node
class_name GL_Playback
@onready var master : GL_Master = $".."
@onready var timeline : GL_Timeline = $"../../Full Editor/Data Timeline"
const _TIME_UNITS = 1.0 / 120.0

func _process(_delta):
	if master.currentlyLoadedPath != "":
		for key in master.currentlyLoadedFile["channels"]:
			var data = master.currentlyLoadedFile["channels"][key]["data"]
			if not data is Array or data.is_empty():
				continue
			var pipe = key.find("|")
			if pipe == -1:
				continue
			var group = key.left(pipe)
			var signal_key = key.substr(pipe + 1)
			var state = float(get_bool_state_at_time(data, timeline.timeCurrent))
			for node in get_tree().get_nodes_in_group(group):
				node._sent_signals(signal_key, state)

func get_bool_state_at_time(stamps: Array, current_time: float) -> bool:
	var current_time_int: int = int(current_time / _TIME_UNITS)
	var lo: int = 0
	var hi: int = stamps.size() - 1
	var result_idx: int = -1
	while lo <= hi:
		var mid: int = (lo + hi) / 2
		if stamps[mid] <= current_time_int:
			result_idx = mid
			lo = mid + 1
		else:
			hi = mid - 1
	if result_idx == -1:
		return false
	return result_idx % 2 == 0
