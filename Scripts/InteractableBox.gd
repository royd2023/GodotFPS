extends Node3D

@onready var health_bar = $HealthBar
@onready var player = $"../CharacterBody3D"

# Declare signals for interacting and stopping interaction
signal interacted

# Optional variables if your object needs specific states
var is_active: bool = true

# Make sure the object can respond to the interaction signal
func _ready():
	# Connect the signal to the interaction logic
	
		connect("interacted", Callable(self, "_on_interacted"))
		connect("stop_interacting", Callable(self, "_on_stop_interacting"))
		

# Function to handle interaction
func _on_interacted():
	if is_active:
		# Define what happens when the object is interacted with
		print("Full Healed!")
		player.player_recieve_health(100)
		await get_tree().create_timer(20).timeout
		
		
	
		





		
		
		
		
		
