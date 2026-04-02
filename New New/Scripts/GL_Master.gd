extends Node
class_name GL_Master
@onready var saveLoad = $SaveLoad

var currentlyLoadedPath : String = ""
var currentlyLoadedFile : Dictionary = {}

func _ready() -> void:
	saveLoad = get_child(0) as GL_SaveLoad
	pass 

func load_show(path: String) -> bool:
	if path != "":
		currentlyLoadedFile = saveLoad.load_savefile(path)
		if currentlyLoadedFile != {}:
			currentlyLoadedPath = path
			return true
		return false
	return false

func create_channel(type: String) -> bool:
	if currentlyLoadedFile == {}:
		print("Can't Create Channel, No File")
		return false
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	var id = type + "_" + str(rng.randi())
	var index = currentlyLoadedFile["channels"].size()
	currentlyLoadedFile["channels"][id] = {"type": type, "data": "","index": index}
	print("Created Channel: (" + str(id) + ") "+ str(currentlyLoadedFile["channels"][id]))
	save()
	return true
	
func save() -> void:
	if currentlyLoadedPath == "":
		print("Couldn't Save, Missing Path")
		return
	saveLoad.save_to_folder(currentlyLoadedFile,currentlyLoadedPath)
	print("Saved to " + currentlyLoadedPath)
