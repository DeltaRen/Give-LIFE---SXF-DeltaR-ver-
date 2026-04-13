extends CharacterBody3D

const SPEED: float = 5.0
const SPRINT_SPEED: float = 9.0
const CROUCH_SPEED: float = 2.0
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.002
const CSTICK_SENSITIVITY: float = 0.2
const MIN_ZOOM_FOV: float = 5.0
const MAX_ZOOM_FOV: float = 100.0
const ZOOM_SPEED: float = 5.0
const ZOOM_STEP_SPEED: float = 5.0
const TILT_SPEED: float = 0.05
const MAX_TILT: float = 0.6
const MIN_TILT: float = -0.6
const MIN_SPEED_MULTIPLIER: float = 0.5
const COLLISION_CHECK_MIN: float = 0.4
const COLLISION_CHECK_MAX: float = 4.0

const HOLD_THRESHOLD := 0.2
const MIN_SMOOTH_LERP := 0.01
const MAX_SMOOTH_LERP := 2.5
const SMOOTH_LERP_STEP := 0.05
const MIN_ACCEL_LERP := 0.01
const MAX_ACCEL_LERP := 2.5
const ACCEL_LERP_STEP := 0.05

const STAND_HEIGHT: float = 3.0
const CROUCH_HEIGHT: float = 1.2
const CROUCH_LERP: float = 10.0
const STAND_EYE_HEIGHT: float = 1.4
const CROUCH_EYE_HEIGHT: float = 0.6

@onready var camera = $Camera3D
@onready var foot_probe: Node3D = $FootProbe
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var rotation_y: float = 0.0
var rotation_x: float = 0.0
var rotation_z: float = 0.0
var target_tilt: float = 0.0
var target_fov: float = 70.0
var speed_mult_target: float = 1.0
var speed_mult: float = 1.0

var smooth_cam: bool = false
var smooth_cam_lerp: float = 1.0
var smooth_move: bool = false
var accel_lerp: float = 1.0
var fly_mode: bool = false

var smooth_held_time: float = 0.0
var was_smooth_pressed: bool = false
var is_adjusting_smooth: bool = false

var move_held_time: float = 0.0
var was_move_pressed: bool = false
var is_adjusting_move: bool = false

var settings_autorun: bool = false
var settings_always_crouch: bool = false

# Tracked crouch state — only flips when we have clearance to stand
var is_crouched: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = STAND_HEIGHT
		collision_shape.position.y = 0.0
	var t = (collision_shape.shape.height - CROUCH_HEIGHT) / (STAND_HEIGHT - CROUCH_HEIGHT)
	var target_cam_y = lerp(CROUCH_EYE_HEIGHT, STAND_EYE_HEIGHT, t)
	var cam_pos = camera.position

func _input(event):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotation_y -= event.relative.x * MOUSE_SENSITIVITY
			rotation_x = clamp(rotation_x - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-80), deg_to_rad(80))
		if Input.is_action_just_pressed("Scroll Up (Mouse)"):
			_process_scroll(1)
		if Input.is_action_just_pressed("Scroll Down (Mouse)"):
			_process_scroll(-1)

func _process(delta: float) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	var look_x = Input.get_action_strength("Look Right") - Input.get_action_strength("Look Left")
	var look_y = Input.get_action_strength("Look Down") - Input.get_action_strength("Look Up")
	if abs(look_x) > 0.05 or abs(look_y) > 0.05:
		rotation_y -= look_x * CSTICK_SENSITIVITY * 20.0 * delta
		rotation_x = clamp(rotation_x - look_y * CSTICK_SENSITIVITY * 20.0 * delta, deg_to_rad(-80), deg_to_rad(80))

	if Input.is_action_pressed("Scroll Up"):
		_process_scroll(1)
	if Input.is_action_pressed("Scroll Down"):
		_process_scroll(-1)

	if Input.is_action_pressed("Smooth Cam"):
		smooth_held_time += delta
		if smooth_held_time >= HOLD_THRESHOLD:
			is_adjusting_smooth = true
			if not smooth_cam:
				smooth_cam = true
	else:
		if was_smooth_pressed:
			if smooth_held_time < HOLD_THRESHOLD:
				smooth_cam = !smooth_cam
				if not smooth_cam:
					rotation_x = camera.rotation.x
					rotation_y = camera.rotation.y
		smooth_held_time = 0.0
		is_adjusting_smooth = false

	was_smooth_pressed = Input.is_action_pressed("Smooth Cam")

	if Input.is_action_pressed("Smooth Movement"):
		move_held_time += delta
		if move_held_time >= HOLD_THRESHOLD:
			is_adjusting_move = true
			if not smooth_move:
				smooth_move = true
	else:
		if was_move_pressed:
			if move_held_time < HOLD_THRESHOLD:
				smooth_move = !smooth_move
		move_held_time = 0.0
		is_adjusting_move = false

	was_move_pressed = Input.is_action_pressed("Smooth Movement")

	if Input.is_action_just_pressed("Fly"):
		fly_mode = !fly_mode

	if not Input.is_action_pressed("Cam Tilt Modifier"):
		target_tilt = 0

	rotation_z = lerp(rotation_z, target_tilt, delta * ZOOM_SPEED)
	camera.fov = lerp(camera.fov, target_fov, delta * ZOOM_SPEED)

	if smooth_cam:
		camera.rotation = Vector3(
			lerp(camera.rotation.x, rotation_x, delta * smooth_cam_lerp),
			lerp(camera.rotation.y, rotation_y, delta * smooth_cam_lerp),
			rotation_z
		)
	else:
		camera.rotation = Vector3(rotation_x, rotation_y, rotation_z)

	var t = (collision_shape.shape.height - CROUCH_HEIGHT) / (STAND_HEIGHT - CROUCH_HEIGHT)
	var target_cam_y = lerp(CROUCH_EYE_HEIGHT, STAND_EYE_HEIGHT, t)
	var cam_pos = camera.position
	cam_pos.y = lerp(cam_pos.y, target_cam_y, delta * CROUCH_LERP)
	camera.position = cam_pos


func _wants_crouch() -> bool:
	if fly_mode:
		return false
	if settings_always_crouch:
		return not Input.is_action_pressed("Sprint")
	return Input.is_action_pressed("Crouch")


func _can_stand_up() -> bool:
	var world = get_viewport().find_world_3d()
	if world == null:
		return false
	var space_state = world.direct_space_state
	if space_state == null:
		return false

	# Feet are at origin.y since position.y is always 0
	var feet_y = global_transform.origin.y - (CROUCH_HEIGHT * 0.5)
	var ray_start = Vector3(global_transform.origin.x, feet_y + 0.1, global_transform.origin.z)
	var ray_end = Vector3(global_transform.origin.x, feet_y + STAND_HEIGHT, global_transform.origin.z)

	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result.is_empty()


func _process_scroll(direction: int):
	if Input.is_action_pressed("Cam Zoom Modifier"):
		target_fov = clamp(target_fov - (direction * ZOOM_STEP_SPEED), MIN_ZOOM_FOV, MAX_ZOOM_FOV)
	if Input.is_action_pressed("Cam Tilt Modifier"):
		target_tilt = clamp(target_tilt + (direction * TILT_SPEED), MIN_TILT, MAX_TILT)
	if is_adjusting_smooth:
		smooth_cam_lerp = clamp(smooth_cam_lerp + (direction * SMOOTH_LERP_STEP), MIN_SMOOTH_LERP, MAX_SMOOTH_LERP)
	if is_adjusting_move:
		accel_lerp = clamp(accel_lerp + (direction * ACCEL_LERP_STEP), MIN_ACCEL_LERP, MAX_ACCEL_LERP)


func _physics_process(delta: float) -> void:
	if not is_on_floor() and not fly_mode:
		velocity.y += get_gravity().y * delta

	var input_dir := Vector2.ZERO
	var currentSpeed = SPEED
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		input_dir = Vector2(
			Input.get_action_strength("Move Right") - Input.get_action_strength("Move Left"),
			Input.get_action_strength("Move Forward") - Input.get_action_strength("Move Backward")
		).normalized()

		if Input.is_action_just_pressed("Jump") and is_on_floor() and not fly_mode:
			velocity.y = JUMP_VELOCITY

		if Input.is_action_pressed("Sprint") or settings_autorun:
			currentSpeed = SPRINT_SPEED

		var crouch_button_held := Input.is_action_pressed("Crouch")
		if is_crouched and not fly_mode:
			if crouch_button_held or not settings_always_crouch:
				currentSpeed = CROUCH_SPEED

	var forward = -camera.global_basis.z
	var right = camera.global_basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var direction = (right * input_dir.x + forward * input_dir.y).normalized()

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if fly_mode:
			var vertical_input := Input.get_action_strength("Move Up") - Input.get_action_strength("Move Down")
			var target_y = vertical_input * currentSpeed
			if smooth_move:
				velocity.y = lerp(velocity.y, target_y, delta * accel_lerp)
			else:
				velocity.y = target_y

	speed_mult_target = get_collision_speed_multiplier()
	speed_mult = lerp(speed_mult, speed_mult_target, delta * 0.5)

	var target_vel := Vector3.ZERO
	if direction:
		target_vel.x = direction.x * currentSpeed * speed_mult
		target_vel.z = direction.z * currentSpeed * speed_mult

	if smooth_move:
		velocity.x = lerp(velocity.x, target_vel.x, delta * accel_lerp)
		velocity.z = lerp(velocity.z, target_vel.z, delta * accel_lerp)
	else:
		velocity.x = target_vel.x
		velocity.z = target_vel.z

	if not direction and not fly_mode:
		if smooth_move:
			velocity.x = lerp(velocity.x, 0.0, delta * accel_lerp)
			velocity.z = lerp(velocity.z, 0.0, delta * accel_lerp)
		else:
			velocity.x = move_toward(velocity.x, 0, currentSpeed)
			velocity.z = move_toward(velocity.z, 0, currentSpeed)

	move_and_slide()

	# --- Crouch state machine ---
	var wants := _wants_crouch()

	if wants and not is_crouched:
		# Crouch immediately — no clearance check needed to go down
		is_crouched = true
	elif not wants and is_crouched:
		# Only stand up if there's room, but always attempt it when crouch is released
		if _can_stand_up():
			is_crouched = false

	var target_height := CROUCH_HEIGHT if is_crouched else STAND_HEIGHT

	if collision_shape.shape is CapsuleShape3D:
		var new_height = lerp(collision_shape.shape.height, target_height, delta * CROUCH_LERP)
		collision_shape.shape.height = new_height
		# Keep position.y at 0 — we compensate by lifting the body when standing
		collision_shape.position.y = 0.0

		# When growing taller, push the body upward so feet stay on the floor
		# rather than letting the capsule expand downward into it
		if not is_crouched and is_on_floor():
			var height_diff = STAND_HEIGHT - new_height
			if height_diff > 0.01:
				global_transform.origin.y += (STAND_HEIGHT - new_height) * delta * CROUCH_LERP * 0.5


func get_collision_speed_multiplier() -> float:
	var shortest_dist := COLLISION_CHECK_MAX
	for ray in foot_probe.get_children():
		if ray is RayCast3D and ray.is_colliding():
			var dist = ray.get_collision_point().distance_to(ray.global_transform.origin)
			if dist < shortest_dist:
				shortest_dist = dist
	return clamp((shortest_dist - COLLISION_CHECK_MIN) / (COLLISION_CHECK_MAX - COLLISION_CHECK_MIN), MIN_SPEED_MULTIPLIER, 1.0)

func on_settings_applied(settings: Dictionary) -> void:
	settings_autorun = settings["auto_run"]
	settings_always_crouch = settings.get("always_crouch", false)
