extends CharacterBody3D

@export var speed := 7.0
@export var sprint_speed := 11.0
@export var mouse_sensitivity := 0.002
@export var gravity := 18.0  # tweak if you want heavier/lighter

var yaw := 0.0
var pitch := 0.0

@onready var cam := $Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
		rotation.y = yaw
		cam.rotation.x = pitch

	# Esc to release mouse
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Click to re-capture mouse (nice for testing)
	if event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Movement input
	var input_x := 0.0
	var input_z := 0.0

	if Input.is_action_pressed("move_left"):
		input_x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_x += 1.0
	if Input.is_action_pressed("move_forward"):
		input_z -= 1.0
	if Input.is_action_pressed("move_back"):
		input_z += 1.0

	var dir := (transform.basis.x * input_x + transform.basis.z * input_z)
	dir.y = 0.0
	dir = dir.normalized()

	# Choose speed (hold Shift to sprint if you add this action, otherwise it just uses speed)
	var current_speed := speed

	velocity.x = dir.x * current_speed
	velocity.z = dir.z * current_speed

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
