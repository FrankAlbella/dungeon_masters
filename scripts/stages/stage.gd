extends Spatial

class_name stage

func _on_fall_area_body_entered(body):
	if body.has_method("get_spawn_id"):
		body.translation = get_node("spawn_points/" + str(body.get_spawn_id())).translation
