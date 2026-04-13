extends Node

@onready var player : Player = $Player/CharacterBody3D

func _ready() -> void:
	print("Start Night")
	player.night_mode = true
