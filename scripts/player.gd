extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4
const SENSITIVITY = 0.004

# Bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

# FOV variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Gravity
var gravity = 9.8

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var ui = $Head/Camera3D/UI  # Direct reference to UI

@export var max_health: int = 100
var health: int = max_health

var jumpAmt = 0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)  # Horizontal rotation
		camera.rotate_x(-event.relative.y * SENSITIVITY)  # Vertical rotation
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))  # Limit up/down view

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumpAmt+=1
	if Input.is_action_just_pressed("jump") and !(is_on_floor()) and jumpAmt == 1:
		velocity.y = JUMP_VELOCITY
		speed = 100 
		jumpAmt = 2
	
	# Handle Sprint
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get movement input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply movement based on floor status
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
	elif Input.is_action_just_pressed("jump") and !(is_on_floor()) and jumpAmt == 2 :
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0) 
		velocity.z = lerp(velocity.z, direction.z * speed * 100, delta * 3.0)
		jumpAmt = 0
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	# Head bobbing effect
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	# FOV adjustment based on movement speed
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()
	
func take_damage(amount):
	health -= amount
	health = max(health, 0)  # Prevent negative health
	ui.update_health(health)
	
func heal_health(amount):
	health += amount
	health = max(100, health)  # Prevent health being above 100
	ui.update_health(health)
	
#Updates Health
func _process(delta):
	if Input.is_action_just_pressed("damage"):  # Press "H" to lose health
		take_damage(10)
	if Input.is_action_just_pressed("heal"):  # Press "H" to lose health
		heal_health(10)

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
