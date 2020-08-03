extends MarginContainer

func _ready():
# warning-ignore:return_value_discarded
	Global.connect("log_message", self, "_on_log_message")
	
func _input(event):
	if event is InputEventKey:
		if Input.is_action_just_pressed("chat"):
			pass

func _on_log_message(msg: String) -> void:
	$HBoxContainer/VBoxContainer2/Log.text += msg + '\n'
	
func set_max_health(max_health: float) -> void:
	$player_hud.set_max_health(max_health)
	
func set_max_mana(max_mana: float) -> void:
	$player_hud.set_max_mana(max_mana)
	
func update_health(health: float) -> void:
	$player_hud.set_health(health)
	
func update_mana(mana: float) -> void:
	$player_hud.set_mana(mana)
	
func update_score(new_score: int) -> void:
	return
	
func _on_score_changed(new_score: int) -> void: 
	update_score(new_score)
