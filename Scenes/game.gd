extends Node3D

@onready var crosshair = $Crosshair
@onready var hitmarker = $Hitmarker

@onready var player = $CharacterBody3D
@onready var enemy = $Enemy
@onready var game_manager = $GameManager



# Called when the node enters the scene tree for the first time.
func _ready():
	center_crosshair_and_hitmarker()
	# Connect to the viewport's size_changed signal to handle window resizing
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))
	enemy.connect("enemy_hit", Callable(self, "on_enemy_hit"))
	player.connect("player_died", Callable(self, "_on_player_died"))

func _on_viewport_size_changed():
	# Recenter the crosshair and hitmarker when the viewport size changes
	center_crosshair_and_hitmarker()

func center_crosshair_and_hitmarker():
	# Assuming the crosshair and hitmarker are 20x20 pixels
	var crosshair_size = 20
	crosshair.position = Vector2(get_viewport().size.x / 2 - crosshair_size / 2, get_viewport().size.y / 2 - crosshair_size / 2)
	hitmarker.position = Vector2(get_viewport().size.x / 2 - crosshair_size / 2, get_viewport().size.y / 2 - crosshair_size / 2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	get_tree().call_group("enemies", "update_target_location", player.global_transform.origin)

func on_enemy_hit():
	hitmarker.visible = true
	await show_hitmarker()

func show_hitmarker():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.05
	timer.one_shot = true
	timer.start()
	await timer.timeout
	hitmarker.visible = false
	timer.queue_free()	

# Player death and respawn logic
func _on_player_died():
	player.queue_free()
	game_manager.respawn_player()
	# Update enemy target location to new player instance
	update_enemy_target_location()

func update_enemy_target_location():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.update_target_location(player.global_transform.origin)
	


		
