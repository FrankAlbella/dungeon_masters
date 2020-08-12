extends KinematicBody

class_name player

# warning-ignore:unused_signal
signal died
signal score_changed

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
var is_hp_regen = false

var controlled = false
var fly_mode = false

# PLAYER STATS
var stat_kills = 0
var stat_deaths = 0
var stat_revives = 0

export var projectile_scene = preload("res://scenes/props/magic_missile.tscn")

func _init():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ready():
	if is_network_master():
		controlled = true
	set_health(MAX_HEALTH)
	set_mana(MAX_MANA)
	
# warning-ignore:return_value_discarded
	$state_machine.connect("shoot", self, "_on_shoot")
# warning-ignore:return_value_discarded
	$state_machine.connect("direction_changed", self, "set_dir")
	
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

func _on_shoot(shoot_transform):
	rpc("fire_bullet", shoot_transform)

func set_dir(new_dir):
	dir = new_dir

func set_is_hp_regen(hp_regen: bool) -> void:
	is_hp_regen = hp_regen

remotesync func add_score(points: int) -> void:
	stat_kills += points
	rpc("_update_score", stat_kills)
	
remotesync func _update_score(new_score: int) -> void: 
	stat_kills = new_score
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
	
remotesync func die() -> void:
	if $state_machine.get_state_name() == "dead" or $state_machine.get_state_name() == "game_over":
		return 
	
	stat_deaths += 1
	
	Global.log_normal(player_name + " has died!", true)
	$state_machine._change_state("dead")
	
remotesync func revive(hp: float) -> void:
	if $state_machine.get_state_name() != "dead":
		return 
	
	Global.log_normal(player_name + " has revived!", true)
	rpc("set_health", hp)
	$state_machine.current_state.emit_signal("finished", "alive")
	
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
	bullet.fire(shoot_transform.basis[2].normalized())
	bullet.add_collision_exception_with(self)
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
	
func _physics_process(_delta):
	update_puppets()
	
func update_puppets():
	if controlled:
		if puppet_dir != dir:
			puppet_dir = dir
			rset("puppet_dir", puppet_dir)
			
		if puppet_pos != translation:
			puppet_pos = translation
			rset("puppet_pos", puppet_pos)
	else:
		$rotation_helper.rotation = puppet_rotation
		$rotation_helper/camera_rot.rotation.x = puppet_camera_rotation
		translation = puppet_pos
		dir = puppet_dir
		
	if not controlled:
		puppet_pos = translation # To avoid jitter
		puppet_rotation = $rotation_helper.rotation
	
func _on_timer_regen_timeout():
	if health < MAX_HEALTH and is_hp_regen:
		rpc("set_health", health + HEALTH_REGEN_RATE)
	if mana < MAX_MANA:
		rpc("set_mana", mana + MANA_REGEN_RATE)
