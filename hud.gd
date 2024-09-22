extends Control


@onready var ammo_val = %ammo
@onready var health_bar = $HealthBar
@onready var death_screen = $YouDied
@onready var interact_screen = $InteractOption

func _ready():
	death_screen.visible = false
	interact_screen.visible = false
	update_ammo(" ")
	
func update_ammo(value):
	ammo_val.text = str(value)

func _on_ammo_changed(value):
	update_ammo(value)
	
func _on_health_changed(hp):
	update_health(hp)

func update_health(hp):
	health_bar.value = hp

func show_death_screen():
	death_screen.visible = true
	
func _on_interact():
	interact_screen.visible = true

func _not_interacting():
	interact_screen.visible = false
	
	
