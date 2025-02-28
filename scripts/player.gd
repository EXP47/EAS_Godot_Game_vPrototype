extends CharacterBody3D

@export var max_health: int = 100
var health: int = max_health


var speed
@export var WALK_SPEED = 4.0
@export var SPRINT_SPEED = 8.0
@export_range (5, 10, 0.1) var CROUCHING_SPEED : float = 7.0
@export var JUMP_VELOCITY = 4
@export var SENSITIVITY = 0.004

# Bob variables
@export var BOB_FREQ = 2.4
@export var BOB_AMP = 0.08
@export var t_bob = 0.0

# FOV variables
@export var BASE_FOV = 75.0
@export var FOV_CHANGE = 1.5

# Gravity
var gravity = 9.8

@export var ANIMATION_PLAYER : AnimationPlayer
@export var CROUCH_SHAPECAST : Node3D


@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var ui = $Head/Camera3D/UI  # Direct reference to UI


var isCrouching:= false


#This is for getting the Camera Working
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	CROUCH_SHAPECAST.add_exception($".")
	
func _input(event):
	if event.is_action_pressed("debug_quit"):
		get_tree().quit()

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

	
	
	
	# Determine movement speed priority
	if Input.is_action_just_pressed("crouch"):
		toggle_crouch()
	# Handle Sprint
	elif Input.is_action_pressed("sprint"):
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
	if Input.is_action_just_pressed("debug_damage"):  # Press "H" to lose health
		take_damage(10)
	if Input.is_action_just_pressed("debug_heal"):  # Press "H" to lose health
		heal_health(10)

func toggle_crouch():
	if isCrouching == true and CROUCH_SHAPECAST.is_colliding() == false:
		print(isCrouching)
		ANIMATION_PLAYER.play("Debug_Crouch", -1, -CROUCHING_SPEED, true)
	elif isCrouching == false:
		ANIMATION_PLAYER.play("Debug_Crouch", -1, -CROUCHING_SPEED * -1, false)
	isCrouching = !isCrouching

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
