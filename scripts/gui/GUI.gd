extends MarginContainer

onready var coin_label = $HBoxContainer/VBoxContainer/Stats/Coins/Count

var coins = 0

func _ready():
	coin_label.text = str(coins)
	Global.connect("log_message", self, "_on_log_message")
	
func _input(event):
	if event is InputEventKey:
		if Input.is_key_pressed(KEY_UP):
			_on_coin_collected()

func _on_log_message(msg: String) -> void:
	$HBoxContainer/Log.text += msg + '\n'

func _on_coin_collected():
	# Update coin count
	coins += 1
	coin_label.text = str(coins)
	
	# Animate from yellow to white
	var start_color = Color(1.0, 1.0, 0, 1.0)
	var end_color = Color(1.0, 1.0, 1.0, 1.0)
	
	$Tween.interpolate_property($HBoxContainer/VBoxContainer/Stats/Coins, "modulate", start_color, end_color, 0.8, Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	if not $Tween.is_active():
		$Tween.start()
