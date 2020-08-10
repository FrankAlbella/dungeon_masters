extends Spatial

export(bool) var rotate = true
var frame = 3

func _ready():
	if rotate:
		$Timer.start()
	
func _on_Timer_timeout() -> void:
	$sprite.rotate_y(deg2rad(45))
