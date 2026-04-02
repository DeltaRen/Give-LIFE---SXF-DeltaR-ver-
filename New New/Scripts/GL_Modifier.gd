extends Node
@onready var master : GL_Master = $"../../../Master"
@onready var saveLoad : GL_SaveLoad = $"../../../Master/SaveLoad"
@onready var settings : TabContainer = $Settings
@onready var startNew : Control = $"Start New"
@onready var timeline : GL_Timeline = $"../../Data Timeline"
@onready var titleVar : LineEdit = $Settings/General/MarginContainer/VBoxContainer/Title/LineEdit
@onready var authorVar : LineEdit = $Settings/General/MarginContainer/VBoxContainer/Author/LineEdit
@onready var createdVar : Label = $Settings/General/MarginContainer/VBoxContainer/Created/Label2

const defaultShowName = "My Unnamed Show"

func _ready() -> void:
	startNew.visible = true
	settings.visible = false

func _create_new_show():
	var path = saveLoad.generate_savefile(defaultShowName)
	if path != "":
		if master.load_show(path):
			_load_settings_general()
			timeline.reload_timeline()

func _load_settings_general() -> void:
	startNew.visible = false
	settings.visible = true
	titleVar.text = master.currentlyLoadedFile.get("title")
	authorVar.text = master.currentlyLoadedFile.get("author")
	createdVar.text = master.currentlyLoadedFile.get("timeCreated")
