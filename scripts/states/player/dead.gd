extends state

const CAM_ANIM_TIME = 0.2

func enter():
	if owner.is_in_group("player_alive"):
		owner.remove_from_group("player_alive")
		
	if not owner.is_in_group("player_dead"):
		owner.add_to_group("player_dead")
	owner.emit_signal("died")
	
	owner.get_node("timer_regen").stop()
	
	owner.get_node("rotation_helper/player_sprite").hide()
	owner.get_node("rotation_helper/player_wisp").show()
	
	owner.set_collision_layer_bit(2, 0)
	
	owner.get_node("Tween").interpolate_property(owner.get_node("rotation_helper/camera_rot/camera"), 
		"translation", 
		owner.get_node("rotation_helper/camera_rot/camera").translation, 
		Vector3(0, -0.5, 1), 
		CAM_ANIM_TIME)
	owner.get_node("Tween").start()

func exit():
	
	owner.set_collision_layer_bit(2, 1)
	owner.get_node("timer_regen").start()

func handle_input(_event):
	return

func update(_delta):
	# Temporary
	if get_tree().get_nodes_in_group("player_alive").size() == 0:
		emit_signal("finished", "game_over")
