extends MarginContainer


onready var player_list = $HBoxContainer/Players/PlayerList
onready var stage_select = $HBoxContainer/Options/StageSelect


func _ready():
	Gamestate.connect("player_list_changed", self, "refresh_lobby")
	refresh_lobby()
	populate_stages()
	$HBoxContainer/Players.visible = Global.is_multiplayer
	


remote func change_stage(id: int) -> void:
	stage_select.select(id)


func populate_stages():
	for stage in Global.stage_list.keys():
		stage_select.add_item(stage)


func refresh_lobby():
	Global.log_normal("Player list changed")
	var players = Gamestate.get_player_list()
	players.sort()
	player_list.clear()
	player_list.add_item(Gamestate.get_player_name() + " (You)")
	for p in players:
		Global.log_normal("Player added: " + p.name)
		player_list.add_item(p.name)

	$HBoxContainer/Options/Start.disabled = not get_tree().is_network_server()
	stage_select.disabled = not get_tree().is_network_server()


func _on_Start_pressed():
	Gamestate.begin_game(stage_select.get_item_text((stage_select.get_selected_id())))


func _on_Leave_pressed():
	Gamestate.end_game()
	Global.goto_scene(Global.MENU_SCENE_PATH)


func _on_StageSelect_item_selected(id):
	rpc("change_stage", id)
