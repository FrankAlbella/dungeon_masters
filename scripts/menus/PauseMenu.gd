extends PopupPanel

func _ready():
	set_process_input(true)
	#show()
	
func _input(event):
	if event is InputEventKey:
		if Input.is_action_just_pressed("ui_cancel"):
			toggle_pause()

func toggle_pause():
	if visible:
		unpause()
	else:
		pause()

func pause():
	Global.log_normal("Game paused")
	#set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()
	
	if not Global.is_multiplayer:
		get_tree().paused = true

func unpause():
	Global.log_normal("Game unpaused")
	#set_process_input(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()
	
	if not Global.is_multiplayer:
		get_tree().paused = false

func _on_Resume_pressed():
	unpause()

func _on_Options_pressed():
	$CenterContainer/VBoxContainer/Options.show()
	$CenterContainer/VBoxContainer/Pause.hide()

func _on_ReturnToMenu_pressed():
	get_tree().paused = false
	Gamestate.end_game()
	Global.goto_scene(Global.MENU_SCENE_PATH)

func _on_Exit_pressed():
	Gamestate.end_game()
	get_tree().quit()

func _on_Back_pressed():
	$CenterContainer/VBoxContainer/Options.hide()
	$CenterContainer/VBoxContainer/Pause.show()

func _on_PauseMenu_visibility_changed():
	$CenterContainer/VBoxContainer/Options.hide()
	$CenterContainer/VBoxContainer/Pause.show()
