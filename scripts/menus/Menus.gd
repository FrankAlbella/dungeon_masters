extends MarginContainer

onready var main_menu = $HBoxContainer/VBoxContainer/MainMenu
onready var connect_menu = $ConnectMenu

func _ready():
	#Gamestate.connect("connection_failed", self, "_on_connection_failed")
	Gamestate.connect("connection_succeeded", self, "_on_connection_success")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if not UIMusic.playing:
		UIMusic.play()
	

func _on_Singleplayer_pressed():
	_on_ConnectMenu_host("", 0, 1)

func _on_Exit_pressed():
	get_tree().quit()

func _on_Multiplayer_pressed():
	main_menu.hide()
	$HBoxContainer/VBoxContainer/MultiplayerMenu.show()

func _on_Options_pressed():
	main_menu.hide()
	$HBoxContainer/VBoxContainer/OptionsMenu.show()

func _on_Back_pressed(node_path):
	if(has_node(node_path)):
		get_node(node_path).hide()
		connect_menu.hide()
		main_menu.show()

func _on_connection_success():
	Global.is_multiplayer = true
	Global.goto_scene("res://scenes/menus/Lobby.tscn")

func _on_ConnectMenu_host(player_name: String, port: int, max_players: int) -> void:
	Global.log_normal("Server started with the following settings:")
	Global.log_normal("player_name: " + player_name)
	Global.log_normal("port: " + str(port))
	Global.log_normal("max_players: " + str(max_players))
	
	Global.goto_scene("res://scenes/menus/Lobby.tscn")
	Gamestate.host_game(player_name, port, max_players)


func _on_ConnectMenu_join(player_name: String, ip: String, port: int) -> void:
	Global.log_normal("Server started with the following settings:")
	Global.log_normal("player_name: " + player_name)
	Global.log_normal("ip: " + ip)
	Global.log_normal("port: " + str(port))
	
	Gamestate.join_game(player_name, ip, port)
