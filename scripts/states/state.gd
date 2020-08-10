extends Node

class_name state

export(NodePath) var player_path
var player_node 

signal finished(next_state_name)

# Initialize the state. E.g. change the animation
func enter():
	Global.log_warning(name+" state: enter not implemented")
	return

# Clean up the state. Reinitialize values like a timer
func exit():
	Global.log_warning(name+" state: exit not implemented")
	return

func handle_input(event):
	Global.log_warning(name+" state: handle_input not implemented")
	return

func update(delta):
	Global.log_warning(name+" state: update not implemented")
	return

func _on_animation_finished(anim_name):
	Global.log_warning(name+" state: _on_animation_finished not implemented")
	return
