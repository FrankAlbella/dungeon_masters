extends Spatial

func _ready():
	if has_node("new_floor/multimesh_floor"):
		var start_x = 0
		var start_z = -7
		for x in range(0, 14):
			for z in range(0, 8):
				$new_floor/multimesh_floor.multimesh.set_instance_transform((z * 14) + x, Transform(Basis(), Vector3(start_x + x, 0, start_z+z)))
		
		for x in range(0, 14):
			for y in range(0, 4):
				$new_floor/multimesh_wall.multimesh.set_instance_transform((y * 14) + x, Transform(Basis(), Vector3(x, 0, -y)))

func _on_fall_area_body_entered(body):
	if body.has_method("get_spawn_id"):
		body.translation = get_node("spawn_points/" + str(body.get_spawn_id())).translation
	if body.is_in_group("enemy"):
		body.queue_free()
