extends Spatial

class_name prefab

signal room_cleared

export(String, "Transition", "Room", "End Room") var  type
export var spawn_enemies = false
export(NodePath) var navigation

var cleared = false
var available_connection_points = []
onready var geometry_node = $geometry

onready var warrior_scene = preload("res://scenes/enemies/enemy_warrior.tscn")

# Thread used to spawn enemies to prevent stutter
var spawn_thread = null

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("prefab")
	
	if not is_connected("tree_exiting", self, "_on_tree_exiting"):
# warning-ignore:return_value_discarded
		connect("tree_exiting", self, "_on_tree_exiting")
	
	geometry_node.hide()
	#remove_child(geometry_node)
	
	for i in $connection_points.get_children():
		available_connection_points.push_back(i)
	

func get_navigation() -> Node:
	return get_node(navigation)

func lock_doors():
	for n in $connection_points.get_children():
		n.set_door_locked(true)
	
func unlock_doors():
	for n in $connection_points.get_children():
		#if not n.available:
		n.unlock_connection()
			

func _spawn_enemies(_data):
	var count = 0
	for n in $spawn_points.get_children():
		rpc("spawn_enemy", "Warrior" + str(count), n.global_transform)
		count += 1

remotesync func spawn_enemy(e_name: String, pos: Transform) -> void:
	var enemy = warrior_scene.instance()
	enemy.global_transform = pos
	enemy.connect("died", self, "_on_enemy_died")
	enemy.set_name(e_name)
		
	get_parent().call_deferred("add_child", enemy)
	Global.log_normal(str(enemy)+" Spawned")
	
func _on_enemy_died():
	if get_tree().get_nodes_in_group("enemy").size() == 0:
		unlock_doors()
		UIMusic.play_explore_music()
		cleared = true
		get_tree().call_group("player", "set_is_hp_regen", false)
		emit_signal("room_cleared")
		
func _on_room_cleared():
	unlock_doors()
	
	if not spawn_enemies:
		emit_signal("room_cleared")

func get_available_connection_points():
	return available_connection_points
	
func get_connection_point(idx):
	var point = available_connection_points[idx]
	available_connection_points.remove(idx)
	return point

# Moves this node to match another node
func move_and_match_exits(prefab_node: prefab, is_starting_room: bool) -> void:
	if available_connection_points.size() == 0:
		Global.log_error(name + " does not have available connection nodes")
		return
	
	var rng = RandomNumberGenerator.new()
	rng.seed = Gamestate.get_rng_seed()
	var rand_base_connection = rng.randi() % prefab_node.get_available_connection_points().size()
	var rand_new_connection = rng.randi() % get_available_connection_points().size()
	
	var base_connection = prefab_node.get_connection_point(rand_base_connection)
	var new_connection = get_connection_point(rand_new_connection)
	
	var rot_diff = base_connection.get_global_transform().basis.get_euler() - new_connection.get_global_transform().basis.get_euler()
	global_rotate(Vector3(0, 1, 0), rot_diff.y)
	
	var pos_diff = base_connection.get_global_transform().origin - new_connection.get_global_transform().origin
	global_translate(pos_diff)
	
	base_connection.set_neighbor(new_connection)
	new_connection.set_neighbor(base_connection)
	
# warning-ignore:return_value_discarded
	prefab_node.connect("room_cleared", self, "_on_room_cleared")
	
	if is_starting_room:
		unlock_doors()
	
	# Workaround because CSG meshes do not update collision meshes when moved 
	for node in $geometry.get_children():
		if node is CSGShape:
			toggle_csg_collision(node)
	#remove_child(geometry_node)

func toggle_csg_collision(csg_node):
	if not csg_node.has_method("set_use_collision"):
		Global.log_warning("toggle_csg_collision: node does not have set_use_collision")
		return
	
	csg_node.use_collision = !csg_node.use_collision
	csg_node.use_collision = !csg_node.use_collision
	

func _on_visible_area_body_entered(body):
	if body.is_in_group("player"):
		if geometry_node:
			geometry_node.show()
			#add_child(geometry_node)

func _on_visible_area_body_exited(body):
	if body.is_in_group("player"):
		if geometry_node and $visible_area.get_overlapping_bodies().size() - 1 == 0:
			geometry_node.hide()
			#remove_child(geometry_node)

func _on_inside_area_body_entered(body):
	assert(body.is_in_group("players"))
	if spawn_enemies and not cleared and $inside_area.get_overlapping_bodies().size() == Gamestate.get_player_count():
		lock_doors()
		UIMusic.play_combat_music()
		cleared = true
		get_tree().call_group("player", "set_is_hp_regen", true)
		
		if get_tree().is_network_server():
			spawn_thread = Thread.new()
			spawn_thread.start(self, "_spawn_enemies")

func _on_tree_exiting():
	if spawn_thread != null:
		spawn_thread.wait_to_finish()
