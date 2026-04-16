extends Light3D

@onready var player : Player = $"../.."
var timer = 0
var initialEnergy = 0
const timerSpeed = 2

func _ready() -> void:
	await get_tree().process_frame
	if not player.night_mode:
		queue_free()
	initialEnergy = light_energy
		
func _process(delta: float) -> void:
	timer = maxf(0,timer - (delta * timerSpeed))
	if timer != 0:
		light_energy = lerpf(initialEnergy,0,maxf(0,timer + randf_range(-0.1,0.1)))
	else:
		light_energy = initialEnergy

func flicker()-> void:
	timer = 1
	light_energy = 0
