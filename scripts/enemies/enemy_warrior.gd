extends KinematicBody

signal died

export(String) var enemy_name
export var MAX_HEALTH = 10
export var health = 5
export var move_speed = 3
export var attack_range = 5
export var min_distance = 3
#export var max_distance = 2
export var projectile_scene = preload("res://scenes/props/magic_missile.tscn")

var target = null
var path = null
puppet var vel = Vector3()
puppet var dir = Vector3()
puppet var look_at_target = Vector3()
puppet var puppet_pos = Vector3()
puppet var in_range = false

const GRAVITY = 0
const ACCEL = 10
const DEACCEL = 16

# Called when the node enters the scene tree for the first time.
func _ready():
	if target == null:
		if not get_tree().is_network_server():
			return
		ai_acquire_target()
	puppet_pos = translation
	
func _process(delta):	
	if get_tree().is_network_server():
		if target == null:
			ai_acquire_target()
		ai_update_direction()
	
		var origin = get_global_transform().origin
		var target_origin = target.get_global_transform().origin
		
		#ai_acquire_path(origin, target_origin)
		var dist_to_player = origin.distance_to(target_origin)
		
		in_range = true
		if dist_to_player > min_distance:
			in_range = false 
		if dist_to_player > attack_range:
				$shoot_cooldown.stop()
		else:
			if $shoot_cooldown.is_stopped():
				$shoot_cooldown.start()
				
		look_at_target = target.translation
		look_at_target.y = translation.y
		
		puppet_pos = translation
		rset("in_range", in_range)
		rset("puppet_pos", puppet_pos)
		rset("look_at_target", look_at_target)
		
	translation = puppet_pos
	if translation != look_at_target:
		look_at(look_at_target, Vector3.UP)
	if not in_range:
		process_movement(delta)

func ai_acquire_path(current_pos, dest_pos) -> void:
	if get_parent().has_method("get_navigation"):
		path = get_parent().get_navigation().get_simple_path(current_pos, dest_pos)
	
func ai_acquire_target() -> void:
	var players = get_tree().get_nodes_in_group("player_alive")
	if players.size() != 0: 
		target = players[Gamestate.get_random_int(players.size(), 0)]
		#rpc("set_target", target.get_path())

func ai_update_direction():
	if target != null:
		dir = (target.translation - self.translation).normalized()
		rset("dir", dir)
	
func process_movement(delta):
	dir.y = 0
	
	if not is_on_floor():
		vel.y += delta * GRAVITY
	
	# Horizonal velocity
	var hvel = vel
	hvel.y = 0
	
	var move_target = dir
	
	move_target *= move_speed
	
	var accel
	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL
		
	hvel = hvel.linear_interpolate(move_target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	
	if (dir.x != 0 or dir.z != 0) and is_on_floor():
		if not $sound_footstep.playing:
			$sound_footstep.play()
	
	vel = move_and_slide(vel, Vector3.UP, true, 4, deg2rad(40))
	
remotesync func fire_bullet(shoot_transform: Transform) -> void:
	var bullet = projectile_scene.instance()
	bullet.source = self
	bullet.set_transform(shoot_transform.orthonormalized())
	bullet.set_collision_mask_bit(2, 0)
	get_parent().add_child(bullet)
	bullet.set_linear_velocity(-shoot_transform.basis[2].normalized() * bullet.speed)
	bullet.add_collision_exception_with(self) # Add it to bullet
	#if not $sound_shoot.is_playing():
	$sound_shoot.play()
	
func take_damage(dmg: int, source: Node) -> void:
	if get_tree().is_network_server():
		rpc("_take_damage", dmg, source)
		
remotesync func _take_damage(dmg: int, source: Node) -> void:
	health -= dmg
	$sound_hurt.play()
	
	if health <= 0:
		if source != null and source.has_method("add_score"):
			source.add_score(1)
		die()
		#rpc("die") seems to cause issues. 
	
remotesync func die():
	set_process(false)
	Global.log_normal(name + " has died!", true)
	remove_from_group("enemy")
	emit_signal("died")
	
	call_deferred("queue_free")
	#queue_free()
	
remotesync func heal(hp: int) -> void:
	health += hp
	

func _on_shoot_cooldown_timeout():
	if target != null and get_tree().is_network_server():
		rpc("fire_bullet", $shoot_position.get_global_transform())
