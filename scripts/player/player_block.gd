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

# PLAYER MESH
onready var _player_mesh = $rotation_helper/player/Armature/Skeleton/Body
onready var _player_skeleton = $rotation_helper/player/Armature/Skeleton
onready var _player_head_id = _player_skeleton.find_bone("head")

onready var _anim = $rotation_helper/player/AnimationPlayer

func _init():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ready():
	if is_network_master():
		$rotation_helper/camera_rot/camera.make_current()
		$Nametag.hide()
		$rotation_helper/camera_rot/Eyes.hide()
	else:
		$GUI.hide()
		
	#_anim.play("walk")
	_player_mesh.material_override = (_player_mesh.material_override.duplicate(true))
	randomize_color()

func randomize_color() -> void:
	Global.log_normal("player_block: randomize_color()")
	var temp_color = Color(1,1,1,1)
	
	if is_network_master():
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var r = rng.randf_range(0,1)
		var g = rng.randf_range(0,1)
		var b = rng.randf_range(0,1)
	
		temp_color = Color(r, g, b, 1)
		rset("puppet_color", temp_color)
	else:
		temp_color = puppet_color
	
	rpc("set_color", temp_color)
	
remotesync func set_color(color: Color) -> void:
	Global.log_normal("player_block: set_color()")
	_player_mesh.material_override.albedo_color = color
	
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
	if not is_network_master():
		return
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		$rotation_helper.rotate_y(-event.relative.x * CAMERA_ROTATION_SPEED)
		$rotation_helper.orthonormalize() # After relative transforms, camera needs to be renormalized.
		camera_x_rot += -event.relative.y * CAMERA_ROTATION_SPEED
		camera_x_rot = clamp(camera_x_rot, deg2rad(CAMERA_X_ROT_MIN), deg2rad(CAMERA_X_ROT_MAX))
		var prev_x_rot = $rotation_helper/camera_rot.rotation.x
		$rotation_helper/camera_rot.rotation.x = camera_x_rot
		
		# Only adjust the head bone if camera rotation changes
		# To prevent head from spinning when the camera does not move
		# Temp fix. Unsure how to clamp type Transform
		if abs(prev_x_rot) - abs(camera_x_rot) != 0:
			var head_x_rot = event.relative.y * CAMERA_ROTATION_SPEED
			head_x_rot = clamp(head_x_rot, deg2rad(CAMERA_X_ROT_MIN), deg2rad(CAMERA_X_ROT_MAX))
		
			var head_rotation = _player_skeleton.get_bone_pose(_player_head_id)
			head_rotation = head_rotation.rotated(Vector3(1.0, 0.0, 0.0), head_x_rot)
			_player_skeleton.set_bone_pose(_player_head_id, head_rotation)
		
		puppet_head_rotation = _player_skeleton.get_bone_pose(_player_head_id)
		rset("puppet_head_rotation", puppet_head_rotation)
		puppet_camera_rotation = $rotation_helper/camera_rot.rotation.x
		rset("puppet_camera_rotation", puppet_camera_rotation)
		puppet_rotation = $rotation_helper.rotation
		rset("puppet_rotation", puppet_rotation)
		
	if event is InputEventKey:
		if Input.is_action_pressed("change_color"):
			randomize_color()
		
	
func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
		
func process_input(delta):
	dir = Vector3()
	var is_shooting = false
	
	if is_network_master():
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
			else:
				if Input.is_action_pressed("shoot_rapid"):
					is_shooting = true
			
			if Input.is_action_pressed("sprint"):
				is_sprinting = true
				$Tween.interpolate_property($rotation_helper/camera_rot/camera, "fov", $rotation_helper/camera_rot/camera.fov, SPRINT_FOV, 0.1)
			else: 
				is_sprinting = false
				$Tween.interpolate_property($rotation_helper/camera_rot/camera, "fov", $rotation_helper/camera_rot/camera.fov, FOV , 0.1)
		
			if not $Tween.is_active():
				$Tween.start()
		
			if is_on_floor():
				if Input.is_action_pressed("jump"):
					vel.y = JUMP_SPEED
				
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
		_player_skeleton.set_bone_pose(_player_head_id, puppet_head_rotation)
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
		
	if not is_network_master():
		puppet_pos = translation # To avoid jitter
		puppet_rotation = $rotation_helper.rotation

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()
	
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
	
	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(40))
	
	

