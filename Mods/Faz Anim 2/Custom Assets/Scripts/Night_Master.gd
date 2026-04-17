extends Node
class_name NightMaster

@onready var player : Player = $Player/CharacterBody3D

func _ready() -> void:
	print("Start Night")
	player.night_mode = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
