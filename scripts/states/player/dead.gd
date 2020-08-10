extends "../state.gd"

const CAM_ANIM_TIME = 0.2

func enter():
	owner.get_node("timer_regen").stop()
	
	owner.get_node("rotation_helper/player_sprite").hide()
	owner.get_node("rotation_helper/player_wisp").show()
	
	owner.get_node("Tween").interpolate_property(owner.get_node("rotation_helper/camera_rot/camera"), 
		"translation", 
		owner.get_node("rotation_helper/camera_rot/camera").translation, 
		Vector3(0, -0.5, 1), 
		CAM_ANIM_TIME)
	owner.get_node("Tween").start()
	
	if owner.is_in_group("player_alive"):
		owner.remove_from_group("player_alive")
		
	if not owner.is_in_group("player_dead"):
		owner.add_to_group("player_dead")
	owner.emit_signal("died")

func exit():
	if not owner.controlled:
		owner.get_node("rotation_helper/player_sprite").show()
	owner.get_node("rotation_helper/player_wisp").hide()
	
	owner.get_node("Tween").interpolate_property(owner.get_node("rotation_helper/camera_rot/camera"), 
		"translation", 
		owner.get_node("rotation_helper/camera_rot/camera").translation, 
		Vector3(0, 0, 0),
		CAM_ANIM_TIME)
	owner.get_node("Tween").start()
	
	owner.get_node("timer_regen").start()
	owner.add_to_group("player_alive")

func handle_input(event):
	return

func update(delta):
	return

func _on_animation_finished(anim_name):
	return
