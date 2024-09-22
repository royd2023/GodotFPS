extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
@onready var player = $"../CharacterBody3D"

var SPEED = 3.0
var health = 1000

var can_attack = true

var nav_ready = false

signal enemy_hit

func _ready():
	# Add a small delay to allow the navigation map to synchronize
	await get_tree().create_timer(0.1).timeout
	update_target_location(player.global_transform.origin)
	nav_ready = true
	update_target_location(player.global_transform.origin)

func take_damage(amount):
	health -= amount
	emit_signal("enemy_hit")
	if health <= 0:
		die()
		
func die():
	queue_free()


func _physics_process(_delta):
	if nav_ready:
		var current_location = global_transform.origin
		var next_location = nav_agent.get_next_path_position()
		if next_location != Vector3():  # Check if next_location is valid
			var new_velocity = (next_location - current_location).normalized() * SPEED
			nav_agent.set_velocity(new_velocity)
	

func update_target_location(target_location):
	nav_agent.target_position = target_location
	
# when the enemy hits you
func _on_navigation_agent_3d_target_reached():
	await get_tree().create_timer(1).timeout
	if can_attack:
		print("You got hit")
		player.player_recieve_damage(10)
		can_attack = false
		await get_tree().create_timer(1).timeout
		can_attack = true


func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, .25)
	move_and_slide()
	

func update_player_reference(new_player):
	player = new_player

	

	
	
