extends Node3D

@onready var player : Player = $"../.."

func _ready() -> void:
	await get_tree().process_frame
	if not player.night_mode:
		queue_free()
