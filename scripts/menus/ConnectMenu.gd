extends PopupPanel

signal host
signal join

onready var player_name = $CenterContainer/VBoxContainer/NameContainer/Name
onready var ip_address = $CenterContainer/VBoxContainer/AddressContainer/IPAddress
onready var port = $CenterContainer/VBoxContainer/PortContainer/Port
onready var max_players = $CenterContainer/VBoxContainer/MaxPlayerContainer/MaxPlayers

onready var max_player_container = $CenterContainer/VBoxContainer/MaxPlayerContainer

onready var connect_button = $CenterContainer/VBoxContainer/ButtonContainer/Connect
onready var cancel_button = $CenterContainer/VBoxContainer/ButtonContainer/Cancel

var is_host

var prev_ip

func _ready():
	Gamestate.connect("connection_failed", self, "_on_connection_failed")
	load_settings()
	
func load_settings():
	player_name.text = Utility.get_config_value("connect", "player_name", "")
	ip_address.text = Utility.get_config_value("connect", "ip_address", "127.0.0.1")
	prev_ip = ip_address.text
	port.text = Utility.get_config_value("connect", "port", "25565")
	max_players.text = Utility.get_config_value("connect", "max_players", "4")
	
func save_settings():
	Utility.set_config_value("connect", "player_name", player_name.text)
	Utility.set_config_value("connect", "ip_address", prev_ip)
	Utility.set_config_value("connect", "port", port.text)
	Utility.set_config_value("connect", "max_players", max_players.text)
	
func _on_connection_failed():
	display_and_log_error("Connection failed!")
	
	# Sometimes causes a crash? Unsure.
	player_name.editable = true
	ip_address.editable = true
	port.editable = true
	
	connect_button.disabled = false
	cancel_button.disabled = false

func display_and_log_error(msg):
	Global.log_error(msg)
	$CenterContainer/VBoxContainer/Error.text = "ERROR: " + msg

# TODO: Horrible function name change later
func _on_Host_pressed(host):
	is_host = host
	
	if ip_address.text != "127.0.0.1":
		prev_ip = ip_address.text
	
	if host:
		ip_address.text = "127.0.0.1"
		ip_address.editable = false
		$CenterContainer/VBoxContainer/Title.text = "Host"
		max_player_container.show()
	else:
		ip_address.text = prev_ip
		ip_address.editable = true
		$CenterContainer/VBoxContainer/Title.text = "Connect"
		max_player_container.hide()
	
	show()
	
func _on_Cancel_pressed():
	hide()


func _on_Connect_pressed() -> void: 
	if player_name.text == "":
		display_and_log_error("Invalid player name!")
		return
	if ip_address.text == "" or not ip_address.text.is_valid_ip_address():
		display_and_log_error("Invalid IP address!")
		return
	if port.text == "" or not port.text.is_valid_integer():
		display_and_log_error("Invalid port!")
		return
	if is_host and (max_players.text == "" or not max_players.text.is_valid_integer()):
		display_and_log_error("Invalid max players!")
		return
	
	if ip_address.text != "127.0.0.1":
		prev_ip = ip_address.text
	
	save_settings()
		
	if is_host:
		emit_signal("host", player_name.text, int(port.text), int(max_players.text))
	else:
		$CenterContainer/VBoxContainer/Error.text = ""
		player_name.editable = false
		ip_address.editable = false
		port.editable = false
		
		connect_button.disabled = true
		cancel_button.disabled = true
		emit_signal("join", player_name.text, ip_address.text, int(port.text))
		
