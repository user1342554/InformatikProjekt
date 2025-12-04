extends Control

## Combat HUD - Displays stamina, power, and combat info

@onready var stamina_bar: ProgressBar = $VBoxContainer/StaminaBar
@onready var power_bar: ProgressBar = $VBoxContainer/PowerBar
@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var combat_state_label: Label = $VBoxContainer/CombatStateLabel

var player: CharacterBody3D = null


func _ready():
	# Try to find local player
	await get_tree().create_timer(0.5).timeout
	find_local_player()


func find_local_player():
	"""Find the local player in the scene"""
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.is_multiplayer_authority():
			player = p
			print("CombatHUD: Connected to player ", player.name)
			break


func _process(_delta):
	if not player:
		find_local_player()
		return
	
	# Update bars
	if stamina_bar:
		stamina_bar.value = player.get_stamina_percent() * 100.0
	
	if power_bar:
		power_bar.value = player.get_power_percent() * 100.0
	
	if health_bar:
		health_bar.value = player.get_health_percent() * 100.0
	
	# Update combat state
	if combat_state_label:
		var state_text = ""
		
		if player.is_attacking:
			state_text = "ATTACKING"
		elif player.is_blocking:
			state_text = "BLOCKING"
		elif player.is_dodging:
			state_text = "DODGING"
		else:
			state_text = "Ready"
		
		combat_state_label.text = state_text

