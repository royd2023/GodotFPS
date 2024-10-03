extends CharacterBody3D


const Normal_SPEED = 5.0
const Sprint_SPEED = 10.0
const JUMP_VELOCITY = 4.5
var current_speed = Normal_SPEED
var direction = Vector3()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var bullet = load("res://Scenes/Bullet.tscn")

var bullet_trail = load("res://Scenes/bullet_trail.tscn")
var instance 

# Weapon Switching
enum weapons {
	RIFLE,
	PISTOL,
	KATANA,
	SNIPER
}
var weapon = null
var can_shoot = false

# Dash parameters
const DASH_SPEED = 20.0
const DASH_DURATION = 0.4
const DASH_COOLDOWN = 1.0

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0

var jump_count = 0

var obstacles : Array
var is_climbing = false

# Ammo Counts
var rifle_ammo = 30
var pistol_ammo = 15
var sniper_ammo = 1
var current_ammo = 0

const RIFLE_RELOAD_TIME = 2.0
const PISTOL_RELOAD_TIME = 1.0
const SNIPER_RELOAD_TIME = 5.0
var is_reloading = false
var has_sword_out = false

# Health 
var player_health = 100
var current_health = player_health

# UI related signals
signal ammo_changed(value)
signal health_changed(health_value)
signal player_died
signal interacting
signal not_interacting

# Interaction variables
var sniper_equipped = false
var ak_equipped = false


@onready var hud = load("res://Scenes/hud.tscn")

@onready var weapon_switch = $"Neck/Camera3D/WeaponSwitching"
@onready var neck := $Neck
@onready var camera := $Neck/Camera3D

#Pistol
@onready var pistol = $Neck/Camera3D/Pistol
@onready var gun_anim := $Neck/Camera3D/Pistol/RootNode/AnimationPlayer
# pistol barrel raycast
@onready var gun_barrel = $Neck/Camera3D/Pistol/RootNode/RayCast3D

#Rifle
@onready var rifle = $Neck/Camera3D/Rifle
@onready var rifle_anim := $Neck/Camera3D/Rifle/RootNode/AnimationPlayer
@onready var rifle_ray := $Neck/Camera3D/RifleAimRay
@onready var rifle_barrel = $Neck/Camera3D/Rifle/RootNode/Barrel
@onready var aim_ray_end = $Neck/Camera3D/AimRayEnd

#Katana
@onready var katana = $Neck/Camera3D/Katana
@onready var katana_anim = $Neck/Camera3D/Katana/RootNode/AnimationPlayer
@onready var katana_hitbox = $Neck/Camera3D/Katana/RootNode/Katana/Area3D
# Dash visual and effects
@onready var dash_visual := $Neck/Camera3D/DashVisual
@onready var dash_effect := $Neck/Camera3D/DashEffect

#Sniper
@onready var sniper = $Neck/Camera3D/Sniper
@onready var sniper_anim = $Neck/Camera3D/Sniper/RootNode/AnimationPlayer
@onready var sniper_barrel = $Neck/Camera3D/Sniper/RootNode/SniperBarrel
@onready var sniper_ads_anim = $Neck/Camera3D/ADS
var zoomed_in = false

# Interaction
@onready var interact_ray = $Neck/Camera3D/InteractRay

# Dropping
@onready var dropped_rifle_scene = load("res://Scenes/interatableRifle.tscn")

func _ready():
	# Connect the katana hitbox signal
	katana_hitbox.connect("body_entered", Callable(self, "_on_katana_hitbox_body_entered"))
	dash_visual.visible = false
	rifle.visible = false
	pistol.visible = false
	katana.visible = false
	sniper.visible = false
	
	# Load and instance the HUD scene
	var hud_instance = hud.instantiate()
	add_child(hud_instance)

	# Connect the ammo_changed signal to the HUD's _on_ammo_changed function
	connect("ammo_changed", Callable(hud_instance, "_on_ammo_changed"))
	emit_signal("ammo_changed", current_ammo)
	
	connect("health_changed", Callable(hud_instance, "_on_health_changed"))
	emit_signal("health_changed", current_health)
	
	connect("player_died", Callable(hud_instance, "show_death_screen"))
	
	connect("interacting", Callable(hud_instance, "_on_interact"))
	
	connect("not_interacting", Callable(hud_instance, "_not_interacting"))
	
	

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.01)
			camera.rotate_x(-event.relative.y * 0.01)	
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
func _physics_process(delta):
	
	# Sprinting
	if Input.is_action_pressed("sprint"):
		current_speed = Sprint_SPEED
	else:
		current_speed = Normal_SPEED
		
	# Add the gravity.
	if not is_on_floor() and not is_dashing and not is_climbing:
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			jump_count = 1  # First jump
		elif jump_count < 2 and not is_on_floor():
			velocity.y = JUMP_VELOCITY * 2
			jump_count = 2  # Second jump
			
	 # Reset jump count when on the floor
	if is_on_floor():
		jump_count = 0

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, Normal_SPEED)
		velocity.z = move_toward(velocity.z, 0, Normal_SPEED)
	move_and_slide()
	
	# Vaulting with place_to_land detection and animation.
	vaulting(delta)
	
	
	
	# Attacking
	if Input.is_action_pressed("shoot") and can_shoot:
		match weapon:
			weapons.RIFLE:
				_shoot_rifle()
			weapons.PISTOL:
				_shoot_pistol()
			weapons.KATANA:
				_swing_sword()
			weapons.SNIPER:
				_shoot_sniper()
	
	
				
	if Input.is_action_just_pressed("reload"):
		if !has_sword_out:
			is_reloading = true
			match weapon:
				weapons.RIFLE:
					_reload("rifle", RIFLE_RELOAD_TIME)
				weapons.PISTOL:
					_reload("pistol", PISTOL_RELOAD_TIME)
				weapons.SNIPER:
					_reload("sniper", SNIPER_RELOAD_TIME)
		

	# Weapon Switching
	if !is_reloading and !weapon == null:		
		if Input.is_action_just_pressed("Weapon 1"):
			if weapon != weapons.RIFLE and ak_equipped:
				equip_ak()
				sniper_equipped = false

			if weapon != weapons.SNIPER and sniper_equipped:
				equip_sniper()
				ak_equipped = false
			
		if Input.is_action_just_pressed("Weapon 2"):
			equip_pistol()
		if Input.is_action_just_pressed("Melee Weapon"):
			equip_katana()
			

		
	# Dashing
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			dash_visual.visible = false
			dash_cooldown_timer = DASH_COOLDOWN
		velocity = neck.transform.basis.z * -DASH_SPEED
		move_and_slide()
	else:
		if dash_cooldown_timer > 0:
			dash_cooldown_timer -= delta
			
		# Change the 'dash' key to something else later
		if weapon == weapons.KATANA and Input.is_action_pressed("SecondaryFire"):
			_slash_sword()
			return

	# Aiming Down Sights
	if weapon == weapons.SNIPER and Input.is_action_pressed("SecondaryFire") and zoomed_in == false:
		_ads_sniper()
		zoomed_in = true
		
	if weapon == weapons.SNIPER and Input.is_action_just_released("SecondaryFire") and zoomed_in == true:
		_exit_ads()
		zoomed_in = false
	
	
	# Interaction
	interact()
	
	if Input.is_action_just_pressed("Drop"):
		drop()
		
		
		
#---------------------------------------------------------------------------------------------------------------------

# DROPPING VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV

func drop():
	if weapon == weapons.RIFLE:
		_drop_rifle()

# CURRENT PROBLEM: After dropping the ak, you can't pick it up again. 
# WHY? The script isn't running after being dropped. For debugging, the interactable
# rifle script prints "weapon dropped" when it runs, but it doesn't after dropping. hmmm

func _drop_rifle():
	# Hide current rifle in player's hand
	rifle.visible = false
	# Update weapon states to "unarmed" after dropping
	weapon = null
	current_ammo = 0
	emit_signal("ammo_changed", 0)
	
	# Load the dropped rifle scene
	var dropped_rifle_instance = dropped_rifle_scene.instantiate()
	# Add the dropped rifle to the scene tree
	get_tree().root.add_child(dropped_rifle_instance)
	
	# Set the position of the dropped rifle to the player's position
	dropped_rifle_instance.global_transform.origin = global_transform.origin + Vector3(0, 1, 0)
	
	# Add some force to make it drop slightly in front of the player
	if dropped_rifle_instance.has_method("apply_impulse"):
		dropped_rifle_instance.apply_impulse(Vector3(), camera.global_transform.basis.z * 3)
	
	
	
	

	

# DROPPING ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#---------------------------------------------------------------------------------------------------------------------
		
# INTERACTION VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV

func interact():
	var coll = interact_ray.get_collider()
	
	if interact_ray.is_colliding():
		if coll:
			# Get the parent node that should have the group
			var parent = coll.get_parent()
			# print("Collider: ", coll, ", Parent: ", parent, ", Groups: ", parent.get_groups())
			if parent and parent.is_in_group("Interact"):
				emit_signal("interacting")
				#print("looking at interactable")
				if Input.is_action_just_pressed("interact"):
					# print("Is Interacting successfully")
					parent.emit_signal("interacted") # Trigger the interaction				
			else:
				emit_signal("not_interacting")
		else:
			emit_signal("not_interacting")	
	else:
		emit_signal("not_interacting")		
						
func equip_sniper():
	if weapon != weapons.SNIPER:
		_raise_weapon(weapons.SNIPER)
		has_sword_out = false
		current_ammo = sniper_ammo
		emit_signal("ammo_changed", sniper_ammo)
		sniper.visible = true
		pistol.visible = false
		rifle.visible = false
		katana.visible = false
		sniper_equipped = true
		ak_equipped = false
		
func equip_ak():
	if weapon != weapons.RIFLE:
		_raise_weapon(weapons.RIFLE)
		has_sword_out = false
		current_ammo = rifle_ammo
		emit_signal("ammo_changed", rifle_ammo)
		rifle.visible = true
		pistol.visible = false
		katana.visible = false
		sniper.visible = false
		ak_equipped = true
	
func equip_pistol():
	if weapon != weapons.PISTOL:
		_raise_weapon(weapons.PISTOL)
		has_sword_out = false
		current_ammo = pistol_ammo
		emit_signal("ammo_changed", pistol_ammo)
		pistol.visible = true
		rifle.visible = false
		katana.visible = false
		sniper.visible = false
	
func equip_katana():
	if weapon != weapons.KATANA:
		has_sword_out = true
		_raise_weapon(weapons.KATANA)
		current_ammo = 0
		emit_signal("ammo_changed", 0)
		katana.visible = true
		pistol.visible = false
		rifle.visible = false
		sniper.visible = false
# INTERACTION ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#---------------------------------------------------------------------------------------------------------------------

# HEALTH VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV

func player_recieve_damage(dmg):
	current_health -= dmg
	emit_signal("health_changed", current_health)
	#print(current_health)
	if current_health <= 0:
		die()

func die():
	print("player died")
	emit_signal("player_died")
	queue_free()


func player_recieve_health(hp):
	current_health = 100	
	emit_signal("health_changed", current_health)
	#print(current_health)
	
# HEALTH ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#---------------------------------------------------------------------------------------------------------------------

# RELOADING VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
func _reload(ammo_var: String, reload_time: float):
	
	match ammo_var:
		"rifle":
			rifle_ammo = 0
			rifle_anim.play("rifle_reload")
		"pistol":
			pistol_ammo = 0
			gun_anim.play("pistol_reload")
		"sniper":
			sniper_ammo = 0
			sniper_anim.play("sniper_reload")
	print("reloading...")
	
	await get_tree().create_timer(reload_time).timeout
	match ammo_var:
		"rifle":
			rifle_ammo = 30
			emit_signal("ammo_changed", rifle_ammo)
		"pistol":
			pistol_ammo = 15
			emit_signal("ammo_changed", pistol_ammo)
		"sniper":
			sniper_ammo = 1
			emit_signal("ammo_changed", sniper_ammo)
	print("reloaded")
	is_reloading = false
	
# RELOADING ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#---------------------------------------------------------------------------------------------------------------------
# CODE FOR WEAPONS VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV

func _slash_sword():
	if !katana_anim.is_playing():
		katana_anim.play("slash_dash")
		dash_visual.visible = true
		dash_effect.play("dash_effect")
		is_dashing = true
		dash_timer = DASH_DURATION
		velocity = camera.global_transform.basis.z * -DASH_SPEED
	
var swing_count = 0
func _swing_sword():
	if !katana_anim.is_playing():
		katana_anim.play("katana_swing")
		if swing_count % 2 == 0:
			katana_anim.play("katana_swing2")	
		swing_count += 1	
		
	await get_tree().create_timer(0.5).timeout
		
func _on_katana_hitbox_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(100)  # Apply damage to the enemy
			
func _shoot_pistol():
	if Input.is_action_pressed("shoot") and pistol_ammo > 0:
		if !gun_anim.is_playing():
			pistol_ammo -= 1
			emit_signal("ammo_changed", pistol_ammo)
			gun_anim.play("Shoot")
			instance = bullet.instantiate()
			instance.position = gun_barrel.global_position
			get_parent().add_child(instance)
			
			var target_position: Vector3
			if gun_barrel.is_colliding():
				target_position = gun_barrel.get_collision_point()
				
			else:
				target_position = gun_barrel.global_transform.basis.z * 100 + gun_barrel.global_position
			instance.set_velocity(target_position)	
	
func _shoot_rifle():
	if Input.is_action_pressed("shoot") and rifle_ammo > 0:
		if !rifle_anim.is_playing():
			rifle_ammo -= 1
			emit_signal("ammo_changed", rifle_ammo)
			rifle_anim.play("Shoot")
			instance = bullet_trail.instantiate()
			get_parent().add_child(instance)
			
			if rifle_ray.is_colliding():
				instance.init(rifle_barrel.global_position, rifle_ray.get_collision_point())
				var collided_object = rifle_ray.get_collider()
				if collided_object.is_in_group("enemies"):
					collided_object.take_damage(30)  # Adjust damage value as needed
					
			else:
				instance.init(rifle_barrel.global_position, aim_ray_end.global_position)
				get_parent().add_child(instance)

func _shoot_sniper():
	if Input.is_action_pressed("shoot") and sniper_ammo > 0:
		if !sniper_anim.is_playing():
			sniper_ammo -= 1
			emit_signal("ammo_changed", sniper_ammo)
			sniper_anim.play("sniper_shoot")
			instance = bullet_trail.instantiate()
			get_parent().add_child(instance)
			
			if rifle_ray.is_colliding():
				instance.init(sniper_barrel.global_position, rifle_ray.get_collision_point())
				var collided_object = rifle_ray.get_collider()
				if collided_object.is_in_group("enemies"):
					collided_object.take_damage(200)  # Adjust damage value as needed
					
			else:
				instance.init(sniper_barrel.global_position, aim_ray_end.global_position)
				get_parent().add_child(instance)
		
func _ads_sniper():
	if !sniper_ads_anim.is_playing():
		sniper_ads_anim.play("sniper_ads")
		
func _exit_ads():
	sniper_ads_anim.play_backwards("sniper_ads")

func _lower_weapon():
	match weapon:
		weapons.RIFLE:
			weapon_switch.play("Lower Rifle")
		weapons.PISTOL:
			weapon_switch.play("Lower Pistol")
		weapons.KATANA:
			weapon_switch.play("Lower Sword")
		weapons.SNIPER:
			weapon_switch.play("Lower Sniper")

func _raise_weapon(new_weapon):
	can_shoot = false
	_lower_weapon()
	await get_tree().create_timer(0.3).timeout
	match new_weapon:
		weapons.RIFLE:
			weapon_switch.play_backwards("Lower Rifle")
		weapons.PISTOL:
			weapon_switch.play_backwards("Lower Pistol")
		weapons.KATANA:
			weapon_switch.play_backwards("Lower Sword")
		weapons.SNIPER:
			weapon_switch.play_backwards("Lower Sniper")
	weapon = new_weapon
	can_shoot = true

# CODE FOR WEAPONS ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#--------------------------------------------------------------------------------------------------------------------

# CODE FOR MANTLING VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV

# Creating RayCast via code for vaulting
func raycast(from: Vector3, to: Vector3):
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to, 2)
	query.collide_with_areas = true
	return space.intersect_ray(query)
	
# Calculating the place_to_land position and initiating the vault animation.
func vaulting(_delta):
	if Input.is_action_pressed("mantle") and is_on_wall():
		
		# Player's RayCast to detect climbable areas.
		var start_hit = raycast(camera.transform.origin, camera.to_global(Vector3(0, 0, -1)))
		
		if start_hit and obstacles.is_empty():
			# RayCast to detect the perfect place to land. 
			var place_to_land = raycast(start_hit.position + self.to_global(Vector3.FORWARD) * $CollisionShape3D.shape.radius + 
			(Vector3.UP * $CollisionShape3D.shape.height), Vector3.DOWN * ($CollisionShape3D.shape.height))
			
			if place_to_land:
				# Playing the animation
				vault_animation(place_to_land)
								
# Animation for vaulting/climbing.
func vault_animation(place_to_land):
	# Player is climbing. This variable prevents hiccups along the process of climbing.
	is_climbing = true
	
	# First Tween animation will make player move up.
	var vertical_climb = Vector3(global_transform.origin.x, place_to_land.position.y, global_transform.origin.z)
	# If your player controller's pivot is located in the middle use this: 
	#var vertical_climb = Vector3(global_transform.origin.x, (place_to_land.position.y + $CollisionShape3D.shape.height / 2), global_transform.origin.z)
	var vertical_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	vertical_tween.tween_property(self, "global_transform:origin", vertical_climb, 0.4)
	
	# We wait for the animation to finish.
	await vertical_tween.finished
	
	# Debug prints to check the camera's basis and forward direction
	#print("Camera Basis: ", camera.global_transform.basis)
	#print("Camera Global Transform: ", camera.global_transform)
	
	# Calculate the forward direction based on the camera's current orientation.
	var forward_direction = -camera.global_transform.basis.z.normalized()
	#print("Forward Direction: ", forward_direction)
	
	# Second Tween animation will make the player move forward where the player is facing.
	var forward = global_transform.origin + (forward_direction * 1.2)
	#print("Forward Position: ", forward)
	var forward_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	forward_tween.tween_property(self, "global_transform:origin", forward, 0.3)
	
	# We wait for the animation to finish.
	await forward_tween.finished
	
	# Player isn't climbing anymore.
	is_climbing = false
					
# Obstacle detection above the head.
func _on_obstacle_detector_body_entered(body):
	if body != self:
		obstacles.append(body)

func _on_obstacle_detector_body_exited(body):
	if body != self :
		obstacles.remove_at(obstacles.find(body))	

# CODE FOR MANTLING ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

