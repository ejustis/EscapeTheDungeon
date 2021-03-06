extends KinematicBody

const GRAVITY = -24.8
var vel = Vector3()
const MAX_SPEED = 4
const MAX_SPRINT_SPEED = 9
#const JUMP_SPEED = 18
const ACCEL = 2
const SPRINT_ACCEL = 4

var max_stamina = 50
var cur_stamina = max_stamina
const STAMINA_REGEN = 0.1
const STAMINA_DRAIN = .5
var SPRINT_EXHAUSTION = max_stamina/2
var exhausted = false

var dir = Vector3()

const DEACCEL= 16
const MAX_SLOPE_ANGLE = 40

var camera
var rotation_helper
var flashlight
var look_raycast

var memory_count = 0

var MOUSE_SENSITIVITY = 0.05

var JOYPAD_SENSITIVITY = 2
const JOYPAD_DEADZONE = 0.25

var is_sprinting = false

func _ready():
	camera = $CameraPivot/Camera
	rotation_helper = $CameraPivot
	look_raycast = $CameraPivot/RayCast
	flashlight = $CameraPivot/Linterna

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
	process_view_input(delta)

func process_input(delta):

	# ----------------------------------
	# Walking
	dir = Vector3()
	var cam_xform = camera.get_global_transform()

	var input_movement_vector = Vector2()

	if Input.is_action_pressed("movement_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("movement_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("movement_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("movement_right"):
		input_movement_vector.x += 1
	
	is_sprinting = false
	if Input.is_action_pressed("sprint"):
		is_sprinting = true
		
	if Input.get_connected_joypads().size() > 0:

		var joypad_vec = Vector2(0, 0)

		if OS.get_name() == "Windows":
			joypad_vec = Vector2(Input.get_joy_axis(0, 0), -Input.get_joy_axis(0, 1))
		elif OS.get_name() == "X11":
			joypad_vec = Vector2(Input.get_joy_axis(0, 1), Input.get_joy_axis(0, 2))
		elif OS.get_name() == "OSX":
			joypad_vec = Vector2(Input.get_joy_axis(0, 1), Input.get_joy_axis(0, 2))

		if joypad_vec.length() < JOYPAD_DEADZONE:
			joypad_vec = Vector2(0, 0)
		else:
			joypad_vec = joypad_vec.normalized() * ((joypad_vec.length() - JOYPAD_DEADZONE) / (1 - JOYPAD_DEADZONE))

		input_movement_vector += joypad_vec

	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x
	# ----------------------------------

	# ----------------------------------
	# Turning the flashlight on/off
	if Input.is_action_just_pressed("flashlight"):
		flashlight.toggle_light()
	# ----------------------------------
	
	# ----------------------------------
	# TESTING - change energy
	if Input.is_action_just_pressed("ui_up"):
		flashlight.energy_current_set(flashlight.energy_current_get() + 0.1)
	if Input.is_action_just_pressed("ui_down"):
		flashlight.energy_current_set(flashlight.energy_current_get() - 0.1)
	# ----------------------------------
	
	# ----------------------------------
	# Interact
	if Input.is_action_just_pressed("interact"):
		check_for_interaction()
	# ----------------------------------

	# ----------------------------------
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------

func check_for_interaction():
	if look_raycast.is_colliding():
		var obj = look_raycast.get_collider().get_parent()
		print(obj.get_name())
		if obj.is_in_group("Memories"):
			obj.disable_and_hide()

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()

	vel.y += delta * GRAVITY

	var hvel = vel
	hvel.y = 0

	var target = dir
	
	if is_sprinting && !exhausted:
		cur_stamina = clamp(cur_stamina - STAMINA_DRAIN, 0, max_stamina)
		if cur_stamina == 0:
			exhausted = true
		
		target *= MAX_SPRINT_SPEED
	else:
		cur_stamina = clamp(cur_stamina + STAMINA_REGEN, 0, max_stamina)
		if exhausted && cur_stamina >= SPRINT_EXHAUSTION:
			exhausted = false
		target *= MAX_SPEED

	var accel
	if dir.dot(hvel) > 0:
		if is_sprinting:
			accel = SPRINT_ACCEL
		else:
			accel = ACCEL
	else:
		accel = DEACCEL
		
#	print("Stamina: ", cur_stamina)

	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))

func process_view_input(delta):

	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	# NOTE: Until some bugs relating to captured mice are fixed, we cannot put the mouse view
	# rotation code here. Once the bug(s) are fixed, code for mouse view rotation code will go here!

	# ----------------------------------
	# Joypad rotation

	var joypad_vec = Vector2()
	if Input.get_connected_joypads().size() > 0:

		if OS.get_name() == "Windows":
			joypad_vec = Vector2(Input.get_joy_axis(0, 2), Input.get_joy_axis(0, 3))
		elif OS.get_name() == "X11":
			joypad_vec = Vector2(Input.get_joy_axis(0, 3), Input.get_joy_axis(0, 4))
		elif OS.get_name() == "OSX":
			joypad_vec = Vector2(Input.get_joy_axis(0, 3), Input.get_joy_axis(0, 4))

		if joypad_vec.length() < JOYPAD_DEADZONE:
			joypad_vec = Vector2(0, 0)
		else:
			joypad_vec = joypad_vec.normalized() * ((joypad_vec.length() - JOYPAD_DEADZONE) / (1 - JOYPAD_DEADZONE))

		rotation_helper.rotate_x(deg2rad(joypad_vec.y * JOYPAD_SENSITIVITY * -1))

		rotate_y(deg2rad(joypad_vec.x * JOYPAD_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot
	# ----------------------------------

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot


func _on_Memory_activated():
	memory_count += 1
	flashlight.energy_current_set(flashlight.energy_current_get() + 0.5)


func _on_ShadowBoi_touched_player():
	if memory_count > 0:
		memory_count -= 1
	else:
		flashlight.energy_current_set(flashlight.energy_current_get() - 0.5)
