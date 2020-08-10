extends Spatial

var start_pos
var end_pos

var bodies_inside = 0

const TIME = .25

export(bool) var _locked = true
export(bool) var _open = false

onready var open_area = $Area/CollisionShape


# Called when the node enters the scene tree for the first time.
func _ready():
	start_pos = $door_staticbody.translation
	end_pos = start_pos
	end_pos.y += 2
	
	set_locked(_locked)
	set_opened(_open)

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
		

func get_opened():
	return _open
	
func set_opened(new_value):
	_open = new_value
	if _open:
		open_door()
	else:
		close_door()

func get_locked():
	return _locked
	
func set_locked(new_value):
	_locked = new_value
	if open_area != null:
		open_area.disabled = new_value
		#Global.log_normal("Door: Lock value set successfully")
		if _locked:
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
