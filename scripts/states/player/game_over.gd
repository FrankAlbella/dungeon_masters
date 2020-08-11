extends "../state.gd"

# Initialize the state. E.g. change the animation
func enter():
	if owner.is_in_group("player_alive"):
		owner.remove_from_group("player_alive")
	if owner.controlled:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		owner.get_node("GUI").hide()
		owner.get_node("stat_menu").populate_players()
		owner.get_node("stat_menu").show()
		UIMusic.stop()

# Clean up the state. Reinitialize values like a timer
func exit():
	return

func handle_input(event):
	return

func update(delta):
	return

func _on_animation_finished(anim_name):
	return
