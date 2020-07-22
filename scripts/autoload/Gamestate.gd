extends Node

# Signals to let lobby GUI know what's going on
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(error)

puppet var stage_path := ""

# Player info, associate ID to data
var player_info = {} # Players who are in the lobby
var player_ready = [] # Players who are ready
# Info we send to other players
var my_info = { name = "Unknown", server_name = "Unknown", hero = "" }

var repeat_names = {}

var rng_seed = 1

func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
func get_rng_seed() -> int:
	return rng_seed

remote func set_rng_seed(_seed: int) -> void:
	rng_seed = _seed
	
remote func give_rng_seed() -> void:
	Global.log_normal("give_rng_seed")
	rpc_id(get_tree().get_rpc_sender_id(), "set_rng_seed", rng_seed)

func _player_connected(id) -> void:
	# Called on both clients and server when a peer connects. Send my info to it.
	rpc_id(id, "register_player", my_info)

func _player_disconnected(id) -> void:
	unregister_player(id) # Erase player from info.

func _connected_ok() -> void:
	# We just connected to a server
	emit_signal("connection_succeeded")
	
	# Get repeat name list from server
	rpc_id(0, "give_repeat_names")
	
	rpc_id(0, "give_rng_seed")
	
	Global.log_normal("After give_repeat_names")

# Callback from SceneTree, only for clients (not server)
func _server_disconnected() -> void:
	end_game()
	emit_signal("game_error", "Server disconnected")

func _connected_fail() -> void:
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")

remote func register_player(info: Dictionary) -> void:
	# Get the id of the RPC sender.
	var id = get_tree().get_rpc_sender_id()
	
	# Extremely buggy
	# Names are only accurate after the 1st repeat
	# 1st repeat won't register the repeat
	# Subsequent will have their own names set accurately, but the names of others will be in validated
	info.name = validate_username(info.name)
	rpc_id(id, "set_player_name", info.name)
	
	Global.log_normal(info.name + " (" + str(id) + ") connected", true)
	
	# Store the info
	player_info[id] = info
	emit_signal("player_list_changed")
	
func unregister_player(id) -> void:
	Global.log_normal(player_info[id].name + " (" + str(id) + ") disconnected", true)
	player_info.erase(id)
	
	if not Global.get_current_scene().get_node("players/" + str(id)) == null:
		Global.get_current_scene().get_node("players/" + str(id)).queue_free()
	emit_signal("player_list_changed")
	
# Checks if the username is already in the lobby
# If it is, it appends a (#) counter for how often the name appears
func validate_username(username: String) -> String:
	if repeat_names.has(username):
		Global.log_normal("Repeat name connected: " + username)
		repeat_names[username] += 1
	else: 
		repeat_names[username] = 0
	
	var count = repeat_names[username]
	#for p_id in player_info:
		
			
	if count > 0:
		username += " (" + str(count) + ")"
		
	return username

remote func pre_start_game(spawn_points) -> void:
	UIMusic.stop()
	Global.free_current_scene()
	
	# Change scene
	Global.log_normal("Changing stage to: " + Global.stage_list[stage_path])
	var world = Global.load_scene(Global.stage_list[stage_path]).instance()
	Global.set_current_scene(world)
	get_tree().get_root().add_child(world)

	var player_scene = load("res://scenes/player/player.tscn")

	for p_id in spawn_points:
		Global.log_normal("Setting player spawn at " + "spawn_points/" + str(spawn_points[p_id]))
		var spawn_pos = world.get_node("spawn_points/" + str(spawn_points[p_id])).translation
		
		Global.log_normal("Instancing player")
		var player = player_scene.instance()

		Global.log_normal("Setting player properies")
		player.set_name(str(p_id)) # Use unique ID as node name
		player.set_spawn_id(spawn_points[p_id])
		player.translation=spawn_pos
		player.set_network_master(p_id) #set unique id as master

		if p_id == get_tree().get_network_unique_id():
			# If node for this peer id, set name
			player.set_player_name(my_info.name)
		else:
			# Otherwise set name from peer
			player.set_player_name(player_info[p_id].server_name)
		
		Global.log_normal("Adding player to world")
		world.get_node("players").add_child(player)
		
	#get_tree().set_pause(true) DOES NOT WORK
	if not get_tree().is_network_server():
		# Tell server we are ready to start
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif player_info.size() == 0:
		post_start_game()

remote func post_start_game() -> void:
	get_tree().set_pause(false) # Unpause and unleash the game!

remote func ready_to_start(id) -> void:
	assert(get_tree().is_network_server())

	if not id in player_ready:
		player_ready.append(id)

	if player_ready.size() == player_info.size():
		for p in player_info:
			rpc_id(p, "post_start_game")
		post_start_game()

func host_game(player_name, port, max_players) -> void:
	my_info.name = player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(port, max_players)
	get_tree().set_network_peer(host)
	
	repeat_names[player_name] = 0
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	set_rng_seed(rng.seed)
	
	if max_players > 1:
		Global.is_multiplayer = true

func join_game(player_name: String, ip: String, port: int) -> void:
	my_info.name = player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, port)
	get_tree().set_network_peer(host)
	
remote func set_repeat_names(names: Dictionary) -> void:
	Global.log_normal("set_repeat_names")
	repeat_names = names
	
remote func give_repeat_names() -> void:
	Global.log_normal("give_repeat_names")
	rpc_id(get_tree().get_rpc_sender_id(), "set_repeat_names", repeat_names)

func get_player_list() -> Array:
	return player_info.values()

func get_player_name() -> String:
	Global.log_normal("My username getted")
	return my_info.name

remote func set_player_name(new_name) -> void:
	Global.log_normal("Username set by server")
	my_info.server_name = new_name

func begin_game(stage_id: String) -> void:
	assert(get_tree().is_network_server())
	
	stage_path = stage_id
	rset("stage_path", stage_id)

	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing
	var spawn_points = {}
	spawn_points[1] = 0 # Server in spawn point 0
	var spawn_point_idx = 1
	for p in player_info:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1
	# Call to pre-start game with the spawn points
	for p in player_info:
		rpc_id(p, "pre_start_game", spawn_points)

	call_deferred("pre_start_game", spawn_points)

func end_game() -> void:
	if not has_node("/root/3DMenu"): # Game is not in the menus
		# Go to main menu
		Global.goto_scene(Global.MENU_SCENE_PATH)
	# Clear repeat name list for future connections
	repeat_names = {}
	emit_signal("game_ended")
	player_info.clear()
	get_tree().set_network_peer(null) # End networking
	Global.is_multiplayer = false
