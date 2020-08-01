extends Spatial

onready var warrior_scene = preload("res://scenes/enemies/enemy_warrior.tscn")
var spawn_thread


func _ready():
	spawn_enemies()
	
func spawn_enemies():
	if get_tree().is_network_server():
		spawn_thread = Thread.new()
		spawn_thread.start(self, "_spawn_enemies")

func _spawn_enemies(_data = null):
	var count = 0
	for n in $enemy_sp.get_children():
		rpc("spawn_enemy", "Warrior" + str(count), n.global_transform)
		count += 1
		
remotesync func spawn_enemy(e_name: String, pos: Transform) -> void:
	var enemy = warrior_scene.instance()
	enemy.global_transform = pos
	enemy.connect("died", self, "_on_enemy_died")
	enemy.set_name(e_name)
		
	call_deferred("add_child", enemy)
	Global.log_normal(str(enemy)+" Spawned")


func _on_enemy_died():
	if get_tree().get_nodes_in_group("enemy").size() == 0:
		spawn_enemies()
		
func _on_fall_area_body_entered(body):
	if body.has_method("get_spawn_id"):
		body.translation = get_node("spawn_points/" + str(body.get_spawn_id())).translation
	if body.is_in_group("enemy"):
		body.queue_free()
