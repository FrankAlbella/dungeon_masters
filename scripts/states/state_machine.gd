extends Node

class_name state_machine

signal state_changed
signal direction_changed(new_direction)
signal shoot(shoot_pos)

var states_stack = []
var current_state = null
var look_direction = Vector3() setget set_look_direction

onready var states_map = {
	"alive": $alive,
	"dead": $dead,
	"no_clip": $no_clip
}

func _ready():
	for state_node in get_children():
		state_node.connect("finished", self, "_update_state")

	states_stack.push_front($alive)
	current_state = states_stack[0]
	_change_state("alive")

func _physics_process(delta):
	current_state.update(delta)

func _input(event):
	current_state.handle_input(event)

func _on_animation_finished(anim_name):
	current_state._on_animation_finished(anim_name)

func _update_state(state_name):
	rpc("_change_state", state_name)
	
func get_state_name():
	return current_state.name
	
remotesync func _change_state(state_name):
	if current_state:
		current_state.exit()

	if state_name == "previous":
		states_stack.pop_front()
	elif state_name in ["no_clip"]:
		states_stack.push_front(states_map[state_name])
	else:
		var new_state = states_map[state_name]
		states_stack[0] = new_state

	current_state = states_stack[0]
	if state_name != "previous":
		# We don"t want to reinitialize the state if we're going back to the previous state
		current_state.enter()
	emit_signal("state_changed", states_stack)

func take_damage(attacker, amount, effect=null):
	if self.is_a_parent_of(attacker):
		return

func set_dead(value):
	set_process_input(not value)
	set_physics_process(not value)
	$CollisionPolygon2D.disabled = value
	
func set_look_direction(value):
	look_direction = value
	emit_signal("direction_changed", value)
	
func shoot(shoot_pos):
	emit_signal("shoot", shoot_pos)
