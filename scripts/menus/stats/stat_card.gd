extends Control

onready var player_name_node = $MarginContainer/MarginContainer/VBoxContainer/player_name
onready var kill_score = $MarginContainer/MarginContainer/VBoxContainer/stat_kills/score
onready var death_score = $MarginContainer/MarginContainer/VBoxContainer/stat_deaths/score
onready var revive_score = $MarginContainer/MarginContainer/VBoxContainer/stat_revives/score
onready var room_score = $MarginContainer/MarginContainer/VBoxContainer/stat_rooms/score
onready var floor_score = $MarginContainer/MarginContainer/VBoxContainer/stat_floors/score

# making the player_node type to player (player_node: player)
# results in a crash when exported, therefore player_node has no type for now
func update_all_stats(player_node) -> void:
	set_player_name(player_node.player_name)
	set_kills(player_node.stat_kills)
	set_deaths(player_node.stat_deaths)
	set_revives(player_node.stat_revives)
	set_rooms(0)
	set_floors(0)
	
func set_player_name(player_name: String) -> void:
	player_name_node.text = player_name
	
func set_kills(kill_count: int) -> void:
	kill_score.text = str(kill_count)

func set_deaths(death_count: int) -> void:
	death_score.text = str(death_count)
	
func set_revives(revive_count: int) -> void:
	revive_score.text = str(revive_count)
	
func set_rooms(room_count: int) -> void:
	room_score.text = str(room_count)
	
func set_floors(floor_count: int) -> void:
	floor_score.text = str(floor_count)
