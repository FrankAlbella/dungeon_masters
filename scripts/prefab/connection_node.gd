extends Position3D

class_name connection_node

var available = true
var neighbor = null
var door_locked = true setget set_door_locked,get_door_locked

func _ready():
	if has_node("door"):
		door_locked = $door.locked

func unlock_connection() -> void:
	set_door_locked(false)
		
	if neighbor != null:
		neighbor.set_door_locked(false)

func set_door_locked(new_value: bool) -> void:
	door_locked = new_value
	if has_node("door"):
		get_node("door").locked = false
		
func get_door_locked() -> bool:
	return door_locked
	
func set_neighbor(neighbor_node: connection_node) -> void:
	neighbor = neighbor_node
	available = false
	if has_node("door") and (not neighbor_node.door_locked or not door_locked):
		$door.locked = false
	
func get_neighbor() -> connection_node:
	return neighbor
	
func clear_neighbor() -> void:
	neighbor.queue_free()
	neighbor = null
	available = true
