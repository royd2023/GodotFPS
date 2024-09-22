extends Node3D

const SPEED = 40.0
var velocity = Vector3.ZERO

@onready var mesh = $MeshInstance3D
@onready var ray = $RayCast3D
@onready var particles = $GPUParticles3D
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += velocity * delta
	if ray.is_colliding():
		
		mesh.visible = false
		particles.emitting = true
		ray.enabled = false
		if ray.get_collider().is_in_group("enemies"):
			ray.get_collider().take_damage(25)
		
		await get_tree().create_timer(1.0).timeout
		queue_free()

func set_velocity(target):
	look_at(target)
	velocity = (global_position - target).normalized() * SPEED
			

func _on_timer_timeout():
	queue_free()
	
