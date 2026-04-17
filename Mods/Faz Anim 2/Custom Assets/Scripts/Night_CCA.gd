extends Node3D

var positions = {
	"Pick Up": {
		"Pos": Vector3(-18.911, 0, -3.165),
		"Rot": -50.8,
		"Move": ["Breaker Magic Room","Back Door","Back Hall Forward","Bar Showroom"]
	},
	"Breaker Magic Room": {
		"Pos": Vector3(-7.697, 0, -9.478),
		"Rot": 71.9,
		"Move": ["Pick Up"]
	},
	"Back Door": {
		"Pos": Vector3(-13.849, 0, 0.652),
		"Rot": 65,
		"Move": ["Pick Up","Breaker Magic Room","Playground","Breaker Outside"]
	},
	"Playground": {
		"Pos": Vector3(-21.917, 0, 14.713),
		"Rot": -16.0,
		"Move": ["Back Door","Breaker Outside"]
	},
	"Breaker Outside": {
		"Pos": Vector3(-29.293, 0, 4.002),
		"Rot": 180.0,
		"Move": ["Playground","Back Door"]
	},
	"Back Hall Forward": {
		"Pos": Vector3(-21.275, 0, -11.037),
		"Rot": -85.9,
		"Move": ["Pick Up","Kitchen","Breaker Office"]
	},
	"Back Hall Backward": {
		"Pos": Vector3(-27.584, 0, -10.981),
		"Rot": -85.9,
		"Move": ["Pick Up","Kitchen","Breaker Office"]
	},
	"Kitchen": {
		"Pos": Vector3(-27.337, 0, -0.78),
		"Rot": -111.5,
		"Move": ["Back Hall Backward"]
	},
	"Breaker Office": {
		"Pos": Vector3(-24.657, 0, -14.789),
		"Rot": -27.367,
		"Move": ["Kitchen"]
	},
	"Bar Showroom": {
		"Pos": Vector3(-13.567, 0, -17.521),
		"Rot": -239.3,
		"Move": ["Pick Up","Bar Window","Games Gallery In"]
	},
	"Bar Window": {
		"Pos": Vector3(-0.912, 0, -21.774),
		"Rot": -177.8,
		"Move": ["Bar Showroom","Pinball Room","Entrance"]
	},
	"Pinball Room": {
		"Pos": Vector3(-3.521, 0, -27.565),
		"Rot": -79.9,
		"Move": ["Bar Window"]
	},
	"Entrance": {
		"Pos": Vector3(-13.93, 0, -24.217),
		"Rot": -80,
		"Move": ["Bar Window","Pinball Room","Games Gallery In"]
	},
	"Games Gallery Out": {
		"Pos": Vector3(-27.617, 0, -20.157),
		"Rot": -52.0,
		"Move": ["Entrance", "Bar Showroom"]
	},
	"Games Gallery In": {
		"Pos": Vector3(-23.068, 0, -23.891),
		"Rot": 115.8,
		"Move": ["Breaker Gallery"]
	},
	"Breaker Gallery": {
		"Pos": Vector3(-21.106, 0, -27.367),
		"Rot": -27.367,
		"Move": ["Games Gallery Out"]
	},
}

var currentLocation = "Pinball Room"
var timer = 20

@onready var anim_player = $AnimationPlayer
const poses = 6

func _ready() -> void:
	move()


func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0:
		move()
		
func move() -> void:
	timer = randf_range(1, 2)
	causeFlicker()
	
	if currentLocation.contains("Breaker"):
		endBreaker() 
	
	var moves = positions[currentLocation]["Move"]
	currentLocation = moves[randi() % moves.size()]
	global_position = positions[currentLocation]["Pos"]
	global_rotation.y = positions[currentLocation]["Rot"]
	reset_physics_interpolation()
	
	var random_pose = "Pose " + str(randi() % poses)
	anim_player.play(random_pose)
	causeFlicker()
	
	if currentLocation.contains("Breaker"):
		startBreaker()
	
	print("C. Ca Moved to " + currentLocation)
	
func causeFlicker() -> void:
	for light in get_tree().get_nodes_in_group("NightLight"):
		var dist = global_position.distance_to(light.global_position)
		if dist <= light.omni_range:
			light.flicker()
			
func startBreaker() -> void:
	var breaker : Night_Breaker = get_tree().get_first_node_in_group(currentLocation).get_node("Area3D") as Night_Breaker
	breaker.manipulate_start()
	
func endBreaker() -> void:
	var breaker : Night_Breaker = get_tree().get_first_node_in_group(currentLocation).get_node("Area3D") as Night_Breaker
	breaker.manipulate_end()
