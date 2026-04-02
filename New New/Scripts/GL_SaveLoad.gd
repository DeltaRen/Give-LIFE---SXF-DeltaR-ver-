extends Node
class_name GL_SaveLoad

const saveFileVersion : int = 1

func generate_savefile(title: String) -> String:

	var node_data = {
		"title": title,
		"author": "Anonymous",
		"timeCreated": Time.get_datetime_string_from_system(true),
		"lastUpdated": Time.get_datetime_string_from_system(true),
		"saveFileVersion": str(saveFileVersion),
		"projectVersion": ProjectSettings.get_setting("application/config/version"),
		"projectName": ProjectSettings.get_setting("application/config/name"),
		"channels": {},
		"media": {},
	}

	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	var save_dir = "user://My Precious Save Files/" + str(rng.randi())

	var dir_err = DirAccess.make_dir_recursive_absolute(save_dir)
	if dir_err != OK:
		push_error("Could not create save directory: " + save_dir)
		return ""

	var file = FileAccess.open(save_dir + "/data.json", FileAccess.WRITE)
	if not file:
		push_error("Could not create data.json in: " + save_dir)
		return ""

	file.store_string(JSON.stringify(node_data, "\t"))
	file.close()
	return save_dir

func load_savefile(save_dir: String) -> Dictionary:
	var file = FileAccess.open(save_dir + "/data.json", FileAccess.READ)
	if not file:
		push_error("Could not open save file at: " + save_dir)
		return {}
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("Failed to parse save file JSON: " + json.get_error_message())
		return {}
	
	return json.data

func save_to_folder(data: Dictionary, save_dir: String) -> void:
	var file = FileAccess.open(save_dir + "/data.json", FileAccess.WRITE)
	if not file:
		push_error("Could not open save file at: " + save_dir)
		return
	
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func copy_file_to_folder(file_path: String, save_dir: String) -> void:
	var err = DirAccess.copy_absolute(file_path, save_dir + "/" + file_path.get_file())
	if err != OK:
		push_error("Could not copy file from: " + file_path + " to: " + save_dir)
