extends "../state.gd"

const MAX_SPEED = 6

var dir = Vector3()
var vel = Vector3()
# Initialize the state. E.g. change the animation
func enter():
	owner.set_collision_mask_bit(0, 0)
	owner.set_collision_layer_bit(0, 0)

# Clean up the state. Reinitialize values like a timer
func exit():
	owner.set_collision_mask_bit(0, 1)
	owner.set_collision_layer_bit(0, 1)

func handle_input(event):
	if not owner.controlled:
		return
		
	if event is InputEventKey and event.pressed:
		if Input.is_action_just_pressed("special"):
			emit_signal("finished", "previous")

func update(delta):
	if owner.controlled:
		var cam_xform = owner.get_node("rotation_helper/camera_rot").get_global_transform()
		
		var input_movement_vector = Vector3()
		
		if Input.is_action_pressed("move_left"):
			input_movement_vector.x -= 1
		if Input.is_action_pressed("move_right"):
			input_movement_vector.x += 1
		if Input.is_action_pressed("move_forward"):
			input_movement_vector.z += 1
		if Input.is_action_pressed("move_backwards"):
			input_movement_vector.z -= 1
		if Input.is_action_pressed("jump"):
			input_movement_vector.y += 1
		if Input.is_action_pressed("ctrl"):
			input_movement_vector.y -= 1
		
		dir = Vector3()
		dir += -cam_xform.basis.z * input_movement_vector.z
		dir += cam_xform.basis.x * input_movement_vector.x
		dir.y = input_movement_vector.y 
		
		get_parent().set_look_direction(dir)
	process_movement(delta)

func process_movement(delta):
	dir = dir.normalized()
	dir *= MAX_SPEED * 100
	dir = owner.move_and_slide(dir * delta, Vector3.UP, true, 4, deg2rad(40))
