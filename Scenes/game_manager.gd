extends Node

@export var player_scene: PackedScene
@export var respawn_point: Node3D

func _ready():
	set_physics_process(false)  # Disable physics processing initially

func respawn_player():
	var player_instance = player_scene.instantiate()
	player_instance.global_transform.origin = respawn_point.global_transform.origin
	get_tree().current_scene.add_child(player_instance)
	get_node("/root/MainScene").player = player_instance  # Update the player reference in the main script
	player_instance.connect("player_died", Callable(get_node("/root/MainScene"), "_on_player_died"))

	# Update the player reference in all enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.update_player_reference(player_instance)
