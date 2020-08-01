extends Spatial

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_teleport_area_body_entered(body):
	if body.has_method("get_spawn_id"):
		body.translation = Gamestate.get_spawn_points().get_node(str(body.get_spawn_id())).translation
	elif body.has_method("get_source"):
		body.translation = Gamestate.get_spawn_points().get_node(str(body.source.get_spawn_id())).translation
