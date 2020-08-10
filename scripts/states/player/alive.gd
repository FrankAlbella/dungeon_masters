extends "../state.gd"

var _shoot_pos

# MOVEMENT CONSTANTS
const GRAVITY = -26
const MAX_SPEED = 6
const JUMP_SPEED = 8
const ACCEL = 10
const DEACCEL = 16
const DEACCEL_AIR = 1

const MAX_SPRINT_SPEED = 8
const SPRINT_ACCEL = 7
var is_sprinting = false

# CAMERA CONSTANTS
const FOV = 90
var SPRINT_FOV = FOV + 5

var dir = Vector3()
var vel = Vector3()

func enter():
	_shoot_pos = owner.get_node("rotation_helper/camera_rot/camera/ShootPosition")
	
func exit():
	dir = Vector3()
	vel = Vector3()

func handle_input(event):
	if not owner.controlled:
		return
	
	if event is InputEventKey and event.pressed:
		if Input.is_action_just_pressed("special"):
			emit_signal("finished", "no_clip")

func update(delta):
	dir = Vector3()
	
	if owner.controlled:
		var cam_xform = owner.get_node("rotation_helper/camera_rot").get_global_transform()
		
		var input_movement_vector = Vector2()
		
		var is_shooting = false
		
		# Don't process input if game is paused
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if Input.is_action_pressed("move_left"):
				input_movement_vector.x -= 1
			if Input.is_action_pressed("move_right"):
				input_movement_vector.x += 1
			if Input.is_action_pressed("move_forward"):
				input_movement_vector.y += 1
			if Input.is_action_pressed("move_backwards"):
				input_movement_vector.y -= 1
			
			if Input.is_action_just_pressed("shoot"):
				is_shooting = true
			elif Input.is_action_pressed("shoot_rapid"):
					is_shooting = true
			
			
			if Input.is_action_pressed("sprint"):
				is_sprinting = true
				owner.get_node("Tween").interpolate_property(owner.get_node("rotation_helper/camera_rot/camera"), "fov", owner.get_node("rotation_helper/camera_rot/camera").fov, SPRINT_FOV, 0.1)
				owner.get_node("sound_footstep").pitch_scale = 0.5
			else: 
				is_sprinting = false
				owner.get_node("Tween").interpolate_property(owner.get_node("rotation_helper/camera_rot/camera"), "fov", owner.get_node("rotation_helper/camera_rot/camera").fov, FOV , 0.1)
				owner.get_node("sound_footstep").pitch_scale = 0.4
				
			if not owner.get_node("Tween").is_active():
				owner.get_node("Tween").start()
		
		input_movement_vector = input_movement_vector.normalized()
		
		dir += -cam_xform.basis.z * input_movement_vector.y
		dir += cam_xform.basis.x * input_movement_vector.x
			
		owner.rotation_degrees = cam_xform.basis.y
		
		if is_shooting:
			get_parent().shoot(_shoot_pos.get_global_transform())
		
		get_parent().set_look_direction(dir)
	process_movement(delta)

func process_movement(delta):
	#dir.y = 0
	dir = dir.normalized()
	
	if not owner.is_on_floor():
		vel.y += delta * GRAVITY
	
	# Horizonal velocity
	var hvel = vel
	hvel.y = dir.y
	
	var target = dir
	
	if is_sprinting:
		target *= MAX_SPRINT_SPEED
	else:
		target *= MAX_SPEED
	
	var accel
	if dir.dot(hvel) > 0:
		if is_sprinting:
			accel = SPRINT_ACCEL
		else:
			accel = ACCEL
	else:
		if owner.is_on_floor():
			accel = DEACCEL
		else:
			accel = DEACCEL_AIR
		
	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	
	if (dir.x != 0 or dir.z != 0) and owner.is_on_floor():
		if not owner.get_node("sound_footstep").playing:
			owner.get_node("sound_footstep").play()
	
	vel = owner.move_and_slide(vel, Vector3.UP, true, 4, deg2rad(40))
