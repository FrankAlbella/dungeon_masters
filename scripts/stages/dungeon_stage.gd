extends Spatial

onready var staircase_scene = preload("res://scenes/prefab/transition/staircase.tscn")
onready var hallway_scene = preload("res://scenes/prefab/transition/hallway.tscn")
onready var startroom_scene = preload("res://scenes/prefab/room/start_room.tscn")
onready var angleroom_scene = preload("res://scenes/prefab/room/angle_room.tscn")
onready var endroom_scene = preload("res://scenes/prefab/end_room/end_room.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	generate_dungeon()
	UIMusic.play_explore_music()

func generate_dungeon():
	Global.log_normal("Generating dungeon")

	$dungeon/staircase.move_and_match_exits($dungeon/start_room, true)
	$dungeon/staircase2.move_and_match_exits($dungeon/start_room, true)
	$dungeon/start_room2.move_and_match_exits($dungeon/staircase2, false)
	$dungeon/hallway.move_and_match_exits($dungeon/start_room, true)
	
	var new_node = angleroom_scene.instance()
	$dungeon.add_child(new_node)
	
	new_node.move_and_match_exits($dungeon/hallway, false)
	
	var new_staircase = staircase_scene.instance()
	$dungeon.add_child(new_staircase)
	new_staircase.move_and_match_exits(new_node, false)
	
	var new_endroom = endroom_scene.instance()
	$dungeon.add_child(new_endroom)
	new_endroom.move_and_match_exits($dungeon/staircase, false)
	
	var new_endroom2 = endroom_scene.instance()
	$dungeon.add_child(new_endroom2)
	new_endroom2.move_and_match_exits(new_staircase, false)
	
	
func _on_fall_area_body_entered(body):
	if body.has_method("get_spawn_id"):
		body.translation = get_node("spawn_points/" + str(body.get_spawn_id())).translation
