extends Spatial

# Thread used to spawn enemies to prevent stutter
var spawn_thread

func _ready():
	pass

func _on_fall_area_body_entered(body):
	if body.has_method("get_spawn_id"):
		body.translation = get_node("spawn_points/" + str(body.get_spawn_id())).translation
