extends "../state.gd"

# Initialize the state. E.g. change the animation
func enter():
	# Make this a common setget
	owner.get_node("rotation_helper/player_sprite").hide()
	owner.get_node("rotation_helper/player_wisp").show()
	owner.get_node("rotation_helper/camera_rot/camera").translation.z = 2
	
	if owner.is_in_group("player_alive"):
		owner.remove_from_group("player_alive")
	owner.emit_signal("died")
		
	owner.get_node("timer_regen").stop()
	

# Clean up the state. Reinitialize values like a timer
func exit():
	if not owner.controlled:
		owner.get_node("rotation_helper/player_sprite").show()
	owner.get_node("rotation_helper/player_wisp").hide()
	owner.get_node("rotation_helper/camera_rot/camera").translation.z = 0

func handle_input(event):

	return

func update(delta):
	return

func _on_animation_finished(anim_name):

	return
