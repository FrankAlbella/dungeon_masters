extends Spatial

export var iterations = 6

# TRANSITIONS
onready var staircase_scene = preload("res://scenes/prefab/transition/staircase.tscn")
onready var hallway_scene = preload("res://scenes/prefab/transition/hallway.tscn")

# ROOMS
onready var startroom_scene = preload("res://scenes/prefab/room/start_room.tscn")
onready var angleroom_scene = preload("res://scenes/prefab/room/angle_room.tscn")

# END ROOMS
onready var endroom_scene = preload("res://scenes/prefab/end_room/end_room.tscn")

onready var transition_scenes = [staircase_scene, hallway_scene]
onready var room_scenes = [startroom_scene, angleroom_scene]


# Called when the node enters the scene tree for the first time.
func _ready():
	generate_dungeon()
	UIMusic.play_explore_music()

func generate_dungeon() -> void:
	print("Generating dungeon")
	
	var rng = RandomNumberGenerator.new()
	rng.seed = Gamestate.get_rng_seed()
	
	var start_room = startroom_scene.instance()
	start_room.spawn_enemies = false
	$dungeon.add_child(start_room)
	
	var pending_nodes = [start_room]
	
	var is_starting_room = true
	var room_count = 0
	
	for i in range(iterations):
		is_starting_room = (i == 0)
		var new_exits = []
		for _j in range(pending_nodes.size()):
			var current_node = pending_nodes.pop_front()
			var available_exit_count = current_node.get_available_connection_points().size()
			var available_prefabs
		
			if i == iterations-1:
				available_prefabs = [endroom_scene]
			elif current_node.type == "Room":
				available_prefabs = transition_scenes
			else:
				available_prefabs = room_scenes
			
			for _k in range(available_exit_count):
				var next_node = available_prefabs[rng.randi()%available_prefabs.size()].instance()
				next_node.set_name(next_node.get_name() + str(room_count))
				room_count += 1
				$dungeon.add_child(next_node)
				next_node.move_and_match_exits(current_node, is_starting_room)
				new_exits.push_back(next_node)
				
		pending_nodes = new_exits
	

func _on_fall_area_body_entered(body):
	if body.has_method("get_spawn_id"):
		body.translation = get_node("spawn_points/" + str(body.get_spawn_id())).translation
