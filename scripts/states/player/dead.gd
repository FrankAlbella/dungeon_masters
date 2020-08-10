extends "../state.gd"

func enter():
	owner.get_node("timer_regen").stop()
	
	owner.get_node("rotation_helper/player_sprite").hide()
	owner.get_node("rotation_helper/player_wisp").show()
	owner.get_node("rotation_helper/camera_rot/camera").translation.z = 1
	
	if owner.is_in_group("player_alive"):
		owner.remove_from_group("player_alive")
	owner.emit_signal("died")

func exit():
	if not owner.controlled:
		owner.get_node("rotation_helper/player_sprite").show()
	owner.get_node("rotation_helper/player_wisp").hide()
	owner.get_node("rotation_helper/camera_rot/camera").translation.z = 0
	owner.add_to_group("player_alive")

func handle_input(event):

	return

func update(delta):
	return

func _on_animation_finished(anim_name):

	return
