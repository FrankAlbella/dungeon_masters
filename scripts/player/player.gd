extends KinematicBody

class_name player

signal died
signal score_changed

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

# PLAYER CONSTANTS
export(float) var MAX_HEALTH = 10.0
export(float) var MAX_MANA = 10.0

export var HEALTH_REGEN_RATE = .2
export var MANA_REGEN_RATE = .8

# PLAYER VARIABLES
var player_name = ""
var health = MAX_HEALTH
var mana = MAX_MANA
var spawn_id = 0
var score = 0
var is_hp_regen = false

var controlled = false
var fly_mode = false

#onready var _anim = $rotation_helper/player/AnimationPlayer

onready var _shoot_pos = $rotation_helper/camera_rot/camera/ShootPosition

export var projectile_scene = preload("res://scenes/props/magic_missile.tscn")

func _init():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ready():
	add_to_group("players")
	if is_network_master():
		controlled = true
	
	set_health(MAX_HEALTH)
	set_mana(MAX_MANA)
	
	if controlled:
		$GUI.set_max_health(MAX_HEALTH)
		$GUI.set_max_mana(MAX_MANA)
		$rotation_helper/camera_rot/camera.make_current()
		$Nametag.hide()
		$rotation_helper/player_sprite.hide()
		$rotation_helper/player_sprite.set_process(false)
		$timer_regen.start()
# warning-ignore:return_value_discarded
		connect("score_changed", $GUI, "_on_score_changed")
	else:
		$GUI.hide()
	
func set_is_hp_regen(hp_regen: bool) -> void:
	is_hp_regen = hp_regen

remotesync func add_score(points: int) -> void:
	score += points
	rpc("_update_score", score)
	
remotesync func _update_score(new_score: int) -> void: 
	score = new_score
	emit_signal("score_changed", new_score)

remotesync func set_player_name(new_player_name: String) -> void:
	player_name = new_player_name
	$Nametag.name_tag = player_name
	
remotesync func take_damage(dmg: float, _source: Node) -> void:
	health -= dmg
	
	if controlled:
		$GUI.update_health(health)
	
	if health <= 0:
		die()
		
remotesync func die():
	Global.log_normal(player_name + " has died! ahhhhhh", true)
	heal(MAX_HEALTH)
	
	emit_signal("died")
	
remotesync func heal(hp: float) -> void:
	health += hp
	if health > MAX_HEALTH:
		health = MAX_HEALTH
	$GUI.update_health(health)
	
remotesync func set_health(new_health: float) -> void:
	health = new_health
	
	if health > new_health:
		health = MAX_HEALTH
		
	if controlled:
		$GUI.update_health(health)
		
	if health <= 0:
		die()
	
remotesync func set_mana(new_mana: float) -> void:
	mana = new_mana
	
	if mana > MAX_MANA:
			mana = MAX_MANA
	
	if controlled:
		$GUI.update_mana(mana)

func set_spawn_id(id: int) -> void:
	spawn_id = id
	
func get_spawn_id() -> int:
	return spawn_id
	
remotesync func fire_bullet(shoot_transform: Transform) -> void:
	var bullet = projectile_scene.instance()
	if mana < bullet.mana_cost:
		bullet.queue_free()
		return 
	set_mana(mana - bullet.mana_cost)
	bullet.source = self
	bullet.set_transform(shoot_transform.orthonormalized())
	get_parent().add_child(bullet)
	bullet.set_linear_velocity(shoot_transform.basis[2].normalized() * bullet.speed)
	bullet.add_collision_exception_with(self) # Add it to bullet
	#if not $sound_shoot.is_playing():
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
			set_collision_mask_bit(0, int(!fly_mode))
			set_collision_layer_bit(0, int(!fly_mode))
		
func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
		
func process_input(delta):
	dir = Vector3()
	
	if controlled:
		var cam_xform = $rotation_helper/camera_rot.get_global_transform()
		
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
		
		if is_shooting:
			rpc("fire_bullet", _shoot_pos.get_global_transform())
		
		if puppet_dir != dir:
			puppet_dir = dir
			rset("puppet_dir", puppet_dir)
			
		if puppet_pos != translation:
			puppet_pos = translation
			rset("puppet_pos", puppet_pos)
			
	else:
		$rotation_helper.rotation = puppet_rotation
		$rotation_helper/camera_rot.rotation.x = puppet_camera_rotation
#		_player_skeleton.set_bone_pose(_player_head_id, puppet_head_rotation)
		translation = puppet_pos
		dir = puppet_dir
		
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
	
	vel = move_and_slide(vel, Vector3.UP, true, 4, deg2rad(40))
	
func _on_timer_regen_timeout():
	if health < MAX_HEALTH and is_hp_regen:
		rpc("set_health", health + HEALTH_REGEN_RATE)
	if mana < MAX_MANA:
		rpc("set_mana", mana + MANA_REGEN_RATE)
		
		
