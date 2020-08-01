tool
extends Spatial

export(bool) var rotate = true
var frame = 3

func _ready():

	if rotate:
		$Timer.start()
		
func _on_Timer_timeout() -> void:
	frame += 1
	if frame > 7:
		frame = 0
	var xcord = 1536 * frame
	$Sprite3D.texture.region = Rect2(xcord, 0, 1536, 2048)
