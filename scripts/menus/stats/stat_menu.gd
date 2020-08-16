extends Control

onready var stat_card_container = $CenterContainer/VBoxContainer/player_stat_cards
onready var stat_card = preload("res://scenes/menus/stats/stat_card.tscn")
onready var player_nodes = $"/root/world/players"

func populate_players():
	for n in stat_card_container.get_children():
		stat_card_container.remove_child(n)
		n.queue_free()
		
	for player_node in player_nodes.get_children():
		# player_node is player is resulting in a crash when exported
		# so we use this workaround for now...
		if not player_node.has_method("set_player_name"):
			continue
		var card = stat_card.instance()
		stat_card_container.add_child(card)
		card.update_all_stats(player_node)
		
func _on_button_mainmenu_pressed():
	get_tree().paused = false
	Gamestate.end_game()
	Global.goto_scene(Global.MENU_SCENE_PATH)

func _on_button_exit_pressed():
	Gamestate.end_game()
	get_tree().quit()

