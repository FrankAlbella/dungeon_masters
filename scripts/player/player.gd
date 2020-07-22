extends KinematicBody

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

var dir = Vector3()
var vel = Vector3()

# CAMERA CONSTANTS
const CAMERA_ROTATION_SPEED = 0.002
const CAMERA_X_ROT_MIN = -80
const CAMERA_X_ROT_MAX = 80
var camera_x_rot = 0.0

const FOV = 90
var SPRINT_FOV = FOV + 5

# PUPPET VARIABLES
puppet var puppet_pos := Vector3()
puppet var puppet_dir := Vector3()
puppet var puppet_rotation := Vector3()
puppet var puppet_head_rotation := Transform()
puppet var puppet_camera_rotation := 0.0
puppet var puppet_color := Color()

puppet var puppet_is_shooting = false

# PLAYER CONSTANTS
const MAX_HEALTH = 10

# PLAYER VARIABLES
var player_name = ""
var health = MAX_HEALTH
var spawn_id = 0

var controlled = false
var fly_mode = false

onready var _anim = $rotation_helper/player/AnimationPlayer

onready var _shoot_pos = $rotation_helper/camera_rot/camera/ShootPosition

func _init():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ready():
	add_to_group("players")
	if is_network_master():
		controlled = true
	
	if controlled:
		$rotation_helper/camera_rot/camera.make_current()
		var VR = ARVRServer.find_interface("OpenVR");
		# If the OpenVR interface was found and initialization is successful...
		if VR and VR.initialize():
			print("OpenVR interface found and initialized")
			# Turn the main viewport into a AR/VR viewport and turn off HDR
			get_viewport().arvr = true
			get_viewport().hdr = false
		
			# Let's disable VSync so the FPS is not capped and set the target FPS to 90,
			# which is standard for most VR headsets.
			#
			# This is not strictly required, but it will make the experience smoother for most VR headsets
			# and then the computer monitor's VSync will not effect the VR headset.
			OS.vsync_enabled = false
			Engine.iterations_per_second = 90
			$rotation_helper/ARVROrigin/ARVRCamera.make_current()
		$Nametag.hide()
		$player_sprite.hide()
	else:
		$GUI.hide()
		
	#_anim.play("walk")

remotesync func set_player_name(new_player_name: String) -> void:
	player_name = new_player_name
	$Nametag.set_name(player_name)
	
func set_spawn_id(id: int) -> void:
	spawn_id = id
	
func get_spawn_id() -> int:
	return spawn_id
	
func fire_bullet():
	var bullet = preload("res://scenes/props/bullet.scn").instance()
	bullet.set_transform($"rotation_helper/camera_rot/camera/ShootPosition".get_global_transform().orthonormalized())
	get_parent().add_child(bullet)
	bullet.set_linear_velocity($"rotation_helper/camera_rot/camera/ShootPosition".get_global_transform().basis[2].normalized() * 100)
	bullet.add_collision_exception_with(self) # Add it to bullet
	$sound_shoot.play()

func _input(event):
	if not controlled:
		return
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		$rotation_helper.rotate_y(-event.relative.x * CAMERA_ROTATION_SPEED)
		$rotation_helper.orthonormalize() # After relative transforms, camera needs to be renormalized.
		camera_x_rot += -event.relative.y * CAMERA_ROTATION_SPEED
		camera_x_rot = clamp(camera_x_rot, deg2rad(CAMERA_X_ROT_MIN), deg2rad(CAMERA_X_ROT_MAX))
		$rotation_helper/camera_rot.rotation.x = camera_x_rot
		
		puppet_camera_rotation = $rotation_helper/camera_rot.rotation.x
		rset("puppet_camera_rotation", puppet_camera_rotation)
		puppet_rotation = $rotation_helper.rotation
		rset("puppet_rotation", puppet_rotation)
	if event is InputEventKey and event.pressed:
		if Input.is_action_just_pressed("special"):
			fly_mode = !fly_mode
		
	
func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
	process_sprite()
	
func process_sprite():
	if not controlled:
		var player_node = get_viewport().get_camera()
		var dir = $rotation_helper/camera_rot.global_transform.basis.z
		var pos = $rotation_helper/camera_rot.global_transform.origin
		var plyrPos = player_node.get_global_transform().origin
		var a = Vector2(dir.x, dir.z) # Direction Sprite is looking
		var dir2Plyr = Vector2(plyrPos.x - pos.x, plyrPos.z - pos.z)
		var angle = a.angle_to(dir2Plyr)
		angle = rad2deg(angle) - 22.5
		if(angle < 0):
			angle += 360
			
		var xcord = 1536 * int(angle/45)
		$player_sprite.texture.region = Rect2(xcord, 0, 1536, 2048)
		#Global.log_normal("angle:" + str(angle) +"\n\tx:" + str(int(angle/45)))
		
func process_input(delta):
	dir = Vector3()
	var is_shooting = false
	
	if controlled:
		var cam_xform = $rotation_helper/camera_rot.get_global_transform()
		
		var input_movement_vector = Vector2()
		
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
					
			if fly_mode:
				if Input.is_action_pressed("jump"):
					translate(Vector3(0, MAX_SPEED*delta, 0))
				if Input.is_action_pressed("ctrl"):
					translate(Vector3(0, -MAX_SPRINT_SPEED*delta, 0))
			
			if Input.is_action_pressed("sprint"):
				is_sprinting = true
				$Tween.interpolate_property($rotation_helper/camera_rot/camera, "fov", $rotation_helper/camera_rot/camera.fov, SPRINT_FOV, 0.1)
				$sound_footstep.pitch_scale = 0.5
			else: 
				is_sprinting = false
				$Tween.interpolate_property($rotation_helper/camera_rot/camera, "fov", $rotation_helper/camera_rot/camera.fov, FOV , 0.1)
				$sound_footstep.pitch_scale = 0.4
				
			if not $Tween.is_active():
				$Tween.start()
			
			# Jumping disabled
			#if is_on_floor():
			#	if Input.is_action_pressed("jump"):
			#		vel.y = JUMP_SPEED
				
		input_movement_vector = input_movement_vector.normalized()
		
		dir += -cam_xform.basis.z * input_movement_vector.y
		dir += cam_xform.basis.x * input_movement_vector.x
			
		rotation_degrees = cam_xform.basis.y
		
		rset("puppet_dir", dir)
		rset("puppet_pos", translation)
		rset("puppet_is_shooting", is_shooting)
	else:
		$rotation_helper.rotation = puppet_rotation
		$rotation_helper/camera_rot.rotation.x = puppet_camera_rotation
#		_player_skeleton.set_bone_pose(_player_head_id, puppet_head_rotation)
		translation = puppet_pos
		dir = puppet_dir
		is_shooting = puppet_is_shooting
		
	if is_shooting:
		fire_bullet()
		
	# If no movement
	#if dir == Vector3():
	#	_anim.play("default", -1, 0.8)
	#else:
	#	if is_sprinting:
	#		_anim.play("walk", -1, 1.3)
	#	else:
	#		_anim.play("walk", -1)
		
	if not controlled:
		puppet_pos = translation # To avoid jitter
		puppet_rotation = $rotation_helper.rotation

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()
	
	if not is_on_floor():
		vel.y += delta * GRAVITY
	
	# Horizonal velocity
	var hvel = vel
	hvel.y = 0
	
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
		if is_on_floor():
			accel = DEACCEL
		else:
			accel = DEACCEL_AIR
		
	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	
	if fly_mode:
		if vel.y < 0:
			vel.y = 0
	
	if (dir.x != 0 or dir.z != 0) and is_on_floor():
		if not $sound_footstep.playing:
			$sound_footstep.play()
	#else:
	#	$sound_footstep.stop()
	
	vel = move_and_slide(vel, Vector3.UP, true, 4, deg2rad(40))
	
	

