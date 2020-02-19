extends Spatial

func _ready():
	pass

func set_name(name: String) -> void:
	$Viewport/Label.text = name

func _on_Label_resized():
	Global.log_normal("Nametag label size changed")
	
	$Viewport.size = $Viewport/Label.rect_size
