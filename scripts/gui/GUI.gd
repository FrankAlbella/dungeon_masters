extends MarginContainer

onready var coin_label = $HBoxContainer/VBoxContainer/Stats/Coins/Count
onready var health_label = $HBoxContainer/VBoxContainer/Stats/Health/Count
onready var mana_bar = $HBoxContainer/VBoxContainer/mana_bar

var coins = 0

var mana_bar_max_length

func _ready():
	coin_label.text = str(0)
# warning-ignore:return_value_discarded
	Global.connect("log_message", self, "_on_log_message")
	mana_bar_max_length = mana_bar.rect_size.x
	
func _input(event):
	if event is InputEventKey:
		if Input.is_action_just_pressed("chat"):
			pass

func _on_log_message(msg: String) -> void:
	$HBoxContainer/VBoxContainer2/Log.text += msg + '\n'
	
func update_health(health: int) -> void:
	health_label.text = str(health)
	
func update_mana_percent(percent: float) -> void: 
	mana_bar.rect_size.x = mana_bar_max_length * percent
	
func update_score(new_score: int) -> void:
	coin_label.text = str(new_score)
	
	var start_color = Color(1.0, 1.0, 0, 1.0)
	var end_color = Color(1.0, 1.0, 1.0, 1.0)
	
	$Tween.interpolate_property($HBoxContainer/VBoxContainer/Stats/Coins, "modulate", start_color, end_color, 0.8, Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	if not $Tween.is_active():
		$Tween.start()
	
func _on_score_changed(new_score: int) -> void: 
	update_score(new_score)
