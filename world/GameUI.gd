extends CanvasLayer

@onready var crosshair = $Crosshair
@onready var hp_bar = $CombatStats/HPBar
@onready var hp_label = $CombatStats/HPBar/HPLabel
@onready var stamina_bar = $CombatStats/StaminaBar
@onready var stamina_label = $CombatStats/StaminaBar/StaminaLabel
@onready var pause_menu = $PauseMenu
@onready var fps_counter = $FPSCounter

func _ready():
	add_to_group("game_ui")  # For pause menu to find us
	
	# Show crosshair
	crosshair.visible = true
	
	# Connect pause menu signals
	if pause_menu:
		pause_menu.disconnect_pressed.connect(_on_disconnect_pressed)
	
	# Listen for settings changes
	GraphicsSettings.settings_changed.connect(_on_settings_changed)
	_update_fps_visibility()

func _process(_delta):
	# Update stats every frame
	_update_ui()
	_update_fps()

func _on_disconnect_pressed():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	NetworkManager.disconnect_from_game()

func _update_fps():
	if fps_counter and fps_counter.visible:
		var fps = Engine.get_frames_per_second()
		fps_counter.text = "FPS: %d" % fps
		
		# Color based on performance
		if fps >= 60:
			fps_counter.modulate = Color(0.2, 1.0, 0.4)  # Green
		elif fps >= 30:
			fps_counter.modulate = Color(1.0, 0.8, 0.0)  # Yellow
		else:
			fps_counter.modulate = Color(1.0, 0.3, 0.2)  # Red

func _update_fps_visibility():
	if fps_counter:
		fps_counter.visible = GraphicsSettings.show_fps_counter

func _on_settings_changed():
	_update_fps_visibility()

func _update_ui():
	var local_player = NetworkManager.get_local_player()
	if not local_player or not is_instance_valid(local_player):
		return
	
	# Update Stamina
	var stamina_percent = local_player.get_stamina_percent()
	if stamina_bar:
		stamina_bar.value = stamina_percent * 100
		
		# Color based on stamina level
		if stamina_percent > 0.5:
			stamina_bar.modulate = Color(0.2, 1.0, 0.3)  # Green
		elif stamina_percent > 0.25:
			stamina_bar.modulate = Color(1.0, 0.8, 0.0)  # Yellow
		else:
			stamina_bar.modulate = Color(1.0, 0.3, 0.2)  # Red
	
	if stamina_label:
		stamina_label.text = "Stamina: %d / %d" % [local_player.current_stamina, local_player.MAX_STAMINA]
	
	# Update HP
	var hp_percent = local_player.get_health_percent()
	if hp_bar:
		hp_bar.value = hp_percent * 100
		
		# Color based on HP level
		if hp_percent > 0.5:
			hp_bar.modulate = Color(0.3, 1.0, 0.3)  # Green
		elif hp_percent > 0.25:
			hp_bar.modulate = Color(1.0, 0.8, 0.0)  # Yellow
		else:
			hp_bar.modulate = Color(1.0, 0.2, 0.2)  # Red
	
	if hp_label and local_player.has_node("HealthComponent"):
		var health = local_player.get_node("HealthComponent")
		hp_label.text = "HP: %d / %d" % [health.current_health, health.max_health]
