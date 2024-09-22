extends Node3D

# Declare signals for interacting and stopping interaction
signal interacted

# Optional variables if your object needs specific states
var is_active: bool = true

# Make sure the object can respond to the interaction signal
func _ready():
	# Connect the signal to the interaction logic
		connect("interacted", Callable(self, "_on_interacted"))
		
		

# Function to handle interaction
func _on_interacted():
	if is_active:
		# Define what happens when the object is interacted with
		print("Interacting")
		
		
