extends KinematicBody

class_name projectile

export var speed = 15
export var damage = 1
export var heal = 0
export var mana_cost = 0.5
export var friendly_fire = true
export var despawn_time = 3
var time_passed = 0

var source 
var velocity

func fire(vel) -> void:
	velocity = vel

func _physics_process(delta):
	time_passed += delta
	
	var collision_data = move_and_collide(velocity * delta * speed)
	if collision_data:
		_on_magic_missile_body_entered(collision_data.collider)
		
	if time_passed >= despawn_time:
		queue_free()

func get_source():
	return source

func _on_magic_missile_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage, source)
		body.heal(heal)
	
	queue_free()
