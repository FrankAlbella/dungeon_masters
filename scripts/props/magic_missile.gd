extends KinematicBody

class_name projectile

export var speed = 15
export var damage = 1
export var heal = 0
export var mana_cost = 0.5
export var friendly_fire = true

var source 
var velocity

func _ready():
	set_process(false)

func fire(vel) -> void:
	velocity = vel
	set_process(true)

func _process(delta):
	var collision_data = move_and_collide(velocity * delta * speed)
	if collision_data:
		_on_magic_missile_body_entered(collision_data.collider)

func get_source():
	return source

func _on_magic_missile_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage, source)
		body.heal(heal)
	
	queue_free()

func _on_Timer_timeout():
	queue_free()
