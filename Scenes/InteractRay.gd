extends RayCast3D



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# Check for collisions
	if self.is_colliding():
		var coll = self.get_collider()
		
		if coll and coll.is_in_group("Interactable"):
			print("raycast is detecting interactable object")
			if Input.is_action_just_pressed("interact"):
				print("Interacting")
