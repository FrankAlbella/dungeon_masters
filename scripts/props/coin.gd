extends Area

# Member variables
var taken = false

func _ready():
	pass

func _on_coin_body_enter(body):
	if not taken and body.has_node("GUI"):
		get_node("anim").play("take")
		taken = true
		body.get_node("GUI")._on_coin_collected()
