tool
extends Spatial

export(String) var name_tag setget set_name, get_name

func _ready():
	#set_name(name_tag)
	pass

func get_name():
	return name_tag

func set_name(name: String) -> void:
	$Viewport/Label.text = name

func _on_Label_resized():
	Global.log_normal("Nametag label size changed")
	
	$Viewport.size = $Viewport/Label.rect_size
