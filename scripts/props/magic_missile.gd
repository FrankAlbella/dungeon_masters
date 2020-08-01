extends RigidBody

class_name projectile

export var speed = 10
export var damage = 1
export var heal = 0
export var mana_cost = 0.5
export var friendly_fire = true

var source 

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_source():
	return source

func _on_magic_missile_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage, source)
		body.heal(heal)
	
	queue_free()


func _on_Timer_timeout():
	queue_free()
