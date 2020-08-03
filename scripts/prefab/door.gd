extends Spatial

var start_pos
var end_pos

var bodies_inside = 0

const TIME = .25

export(bool) var locked setget _set_locked, _get_locked
export(bool) var open setget _set_opened, _get_opened

onready var open_area = $Area/CollisionShape


# Called when the node enters the scene tree for the first time.
func _ready():
	start_pos = $door_staticbody.translation
	end_pos = start_pos
	end_pos.y += 2
	
	_set_locked(locked)

func _on_Area_body_entered(body):
	if body.is_in_group("player"):
		bodies_inside += 1
		if bodies_inside > 0:
			open_door()
		

func _on_Area_body_exited(body):
	if body.is_in_group("player"):
		bodies_inside -= 1
		if bodies_inside == 0:
			close_door()
		

func _get_opened():
	return open
	
func _set_opened(new_value):
	open = new_value
	if open:
		open_door()
	else:
		close_door()

func _get_locked():
	return locked
	
func _set_locked(new_value):
	locked = new_value
	if open_area != null:
		open_area.disabled = new_value
		#Global.log_normal("Door: Lock value set successfully")
		if locked:
			close_door()
	else:
		Global.log_warning("Door: open_area is null")
		
func open_door():
	$Tween.interpolate_property($door_staticbody, "translation", $door_staticbody.translation, end_pos, TIME, Tween.TRANS_LINEAR)
	$Tween.start()
	$door_staticbody/AudioStreamPlayer3D.play()
	
func close_door():
	
	$Tween.interpolate_property($door_staticbody, "translation", $door_staticbody.translation, start_pos, TIME, Tween.TRANS_LINEAR)
	$Tween.start()
	$door_staticbody/AudioStreamPlayer3D.play()
