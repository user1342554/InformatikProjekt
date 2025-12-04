extends CharacterBody3D

# ============================================
# BEWEGUNG KONSTANTEN
# ============================================
const SPEED = 5.0
const SPRINT_SPEED = 8.0
const SNEAK_SPEED = 2.5
const JUMP_VELOCITY = 4.5
const ACCELERATION = 20.0
const FRICTION = 15.0
const MAX_HORIZONTAL_SPEED = 15.0

# ============================================
# SNEAK/CROUCH KONSTANTEN
# ============================================
const STAND_HEIGHT = 1.6        # Normale Kamera-Höhe
const CROUCH_HEIGHT = 0.8       # Geduckte Kamera-Höhe
const SPHERE_STAND_HEIGHT = 1.0 # Normale Kugel-Höhe
const SPHERE_CROUCH_HEIGHT = 0.5 # Geduckte Kugel-Höhe
const CROUCH_SPEED = 10.0       # Wie schnell das Ducken animiert wird

# ============================================
# DODGE KONSTANTEN
# ============================================
const DODGE_SPEED = 10.0
const DODGE_DURATION = 0.35
const DODGE_COOLDOWN = 1.0

# ============================================
# STAMINA KONSTANTEN
# ============================================
const MAX_STAMINA = 100.0
const STAMINA_REGEN_RATE = 25.0
const STAMINA_REGEN_DELAY = 1.0
const DODGE_STAMINA_COST = 25.0
const SPRINT_STAMINA_COST = 15.0

# ============================================
# VARIABLEN - Bewegung
# ============================================
var is_sneaking = false
var dodge_timer = 0.0
var dodge_cooldown_timer = 0.0
var dodge_direction = Vector3.ZERO
var is_dodging = false
var was_on_floor_before_dodge = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# ============================================
# VARIABLEN - Stamina
# ============================================
var current_stamina = MAX_STAMINA
var stamina_regen_timer = 0.0
var can_sprint = true
var can_dodge = true

# ============================================
# VARIABLEN - Multiplayer
# ============================================
var is_local_player = false
var mouse_sensitivity = 0.003
var camera_rotation = Vector2.ZERO

# ============================================
# VARIABLEN - Input Buffering
# ============================================
var _input_buffer := Vector2.ZERO
var _sprint_pressed := false
var _jump_pressed := false
var _dodge_pressed := false
var _sneak_pressed := false

# ============================================
# CACHED NODES
# ============================================
@onready var head_node := $Head
@onready var camera_node := $Head/Camera3D
@onready var _rotation_root: Node3D = $CharacterRotationRoot
@onready var _sphere_mesh: MeshInstance3D = $CharacterRotationRoot/SphereMesh
@onready var health_component: HealthComponent = $HealthComponent

# ============================================
# READY
# ============================================
func _ready():
	add_to_group("player")
	
	collision_layer = 4  # Layer 4 for players
	collision_mask = 5  # Collide with world (1) + players (4)
	
	is_local_player = is_multiplayer_authority()
	
	# Connect Health Signals
	if health_component:
		health_component.died.connect(_on_player_died)
		health_component.damaged.connect(_on_player_damaged)
	
	print("Player ", name, " ready. Is local: ", is_local_player, " Authority: ", get_multiplayer_authority())
	
	if is_local_player:
		camera_node.make_current()
		
		# Verstecke Spielermodell für First-Person
		if _rotation_root:
			_rotation_root.visible = false
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		VoiceChat.start_recording()
		print("Local player camera activated (First Person)")
	else:
		camera_node.current = false
		if _rotation_root:
			_rotation_root.visible = true
		process_priority = 10
		print("Remote player, camera disabled")
	
	_setup_name_label()

# ============================================
# INPUT
# ============================================
func _input(event):
	if not is_local_player:
		return
	
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_rotation.x -= event.relative.y * mouse_sensitivity
		camera_rotation.y -= event.relative.x * mouse_sensitivity
		
		camera_rotation.x = clamp(camera_rotation.x, -PI/2, PI/2)
		
		head_node.rotation.x = camera_rotation.x
		rotation.y = camera_rotation.y
	
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# ============================================
# PROCESS - Input Buffering
# ============================================
func _process(_delta):
	if not is_local_player:
		return
	
	# Buffer movement input
	_input_buffer = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_sprint_pressed = Input.is_action_pressed("sprint")
	_jump_pressed = Input.is_action_just_pressed("jump")
	_dodge_pressed = Input.is_action_just_pressed("dodge")
	_sneak_pressed = Input.is_action_pressed("sneak")

# ============================================
# PHYSICS PROCESS
# ============================================
func _physics_process(delta):
	if is_multiplayer_authority():
		_update_stamina(delta)
		_handle_movement_input(delta)
		_update_crouch(delta)
		
		# Gravitation
		if not is_on_floor():
			velocity.y -= gravity * delta
		
		# Speed Cap
		_cap_horizontal_speed()
	
	move_and_slide()

# ============================================
# CROUCH/SNEAK ANIMATION
# ============================================
func _update_crouch(delta: float):
	var target_head_height = CROUCH_HEIGHT if is_sneaking else STAND_HEIGHT
	var target_sphere_height = SPHERE_CROUCH_HEIGHT if is_sneaking else SPHERE_STAND_HEIGHT
	
	# Smooth interpolation für Kamera
	head_node.position.y = lerp(head_node.position.y, target_head_height, CROUCH_SPEED * delta)
	
	# Smooth interpolation für Kugel (für andere Spieler sichtbar)
	if _sphere_mesh:
		_sphere_mesh.position.y = lerp(_sphere_mesh.position.y, target_sphere_height, CROUCH_SPEED * delta)


# ============================================
# BEWEGUNGS INPUT
# ============================================
func _handle_movement_input(delta):
	# Sneak
	is_sneaking = _sneak_pressed and not is_dodging
	
	# Dodge timers
	if dodge_timer > 0:
		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false
	
	if dodge_cooldown_timer > 0:
		dodge_cooldown_timer -= delta
	
	# Dodge
	if _dodge_pressed and not is_dodging and dodge_cooldown_timer <= 0 and is_on_floor() and can_dodge:
		if try_use_stamina(DODGE_STAMINA_COST):
			start_dodge()
	
	# Jump
	if _jump_pressed and is_on_floor() and not is_dodging and not is_sneaking:
		velocity.y = JUMP_VELOCITY
	
	# Bewegung
	if is_dodging:
		if was_on_floor_before_dodge and is_on_floor():
			velocity.y = -2.0
		
		velocity.x = dodge_direction.x * DODGE_SPEED
		velocity.z = dodge_direction.z * DODGE_SPEED
	else:
		var direction := Vector3.ZERO
		if _input_buffer.length_squared() > 0.01:
			direction = (transform.basis * Vector3(_input_buffer.x, 0, _input_buffer.y)).normalized()
		
		var target_speed = SPEED
		
		if is_sneaking:
			target_speed = SNEAK_SPEED
		elif _sprint_pressed and can_sprint and current_stamina > 0:
			if direction != Vector3.ZERO:
				var stamina_cost = SPRINT_STAMINA_COST * delta
				if current_stamina >= stamina_cost:
					current_stamina -= stamina_cost
					stamina_regen_timer = STAMINA_REGEN_DELAY
					target_speed = SPRINT_SPEED
				else:
					can_sprint = false
		
		if direction != Vector3.ZERO:
			var accel_rate = ACCELERATION * delta
			velocity.x = move_toward(velocity.x, direction.x * target_speed, accel_rate)
			velocity.z = move_toward(velocity.z, direction.z * target_speed, accel_rate)
		else:
			var friction_rate = FRICTION * delta
			velocity.x = move_toward(velocity.x, 0, friction_rate)
			velocity.z = move_toward(velocity.z, 0, friction_rate)


func _update_stamina(delta):
	if stamina_regen_timer > 0:
		stamina_regen_timer -= delta
	else:
		if current_stamina < MAX_STAMINA:
			current_stamina = min(current_stamina + STAMINA_REGEN_RATE * delta, MAX_STAMINA)
	
	can_sprint = current_stamina > SPRINT_STAMINA_COST * 0.5
	can_dodge = current_stamina >= DODGE_STAMINA_COST

func try_use_stamina(cost: float) -> bool:
	if current_stamina >= cost:
		current_stamina -= cost
		stamina_regen_timer = STAMINA_REGEN_DELAY
		return true
	return false

func get_stamina_percent() -> float:
	return current_stamina / MAX_STAMINA

# ============================================
# HELPER
# ============================================
func _cap_horizontal_speed():
	var horizontal_speed_sq = velocity.x * velocity.x + velocity.z * velocity.z
	if horizontal_speed_sq > MAX_HORIZONTAL_SPEED * MAX_HORIZONTAL_SPEED:
		var horizontal_speed = sqrt(horizontal_speed_sq)
		var scale_factor = MAX_HORIZONTAL_SPEED / horizontal_speed
		velocity.x *= scale_factor
		velocity.z *= scale_factor

func has_invincibility_frames() -> bool:
	return false  # i-Frames disabled

# ============================================
# DODGE
# ============================================
func start_dodge():
	is_dodging = true
	dodge_timer = DODGE_DURATION
	dodge_cooldown_timer = DODGE_COOLDOWN
	was_on_floor_before_dodge = is_on_floor()
	
	if is_on_floor():
		velocity.y = 0
	
	if _input_buffer.length_squared() > 0.01:
		dodge_direction = (transform.basis * Vector3(_input_buffer.x, 0, _input_buffer.y)).normalized()
	else:
		dodge_direction = -transform.basis.z

# ============================================
# NAME LABEL
# ============================================
func _setup_name_label():
	# Kein Name-Label für den lokalen Spieler - man soll sich selbst nicht sehen
	if is_local_player:
		return
	
	var label = Label3D.new()
	label.text = "Player " + name
	label.font_size = 32
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.3, 0)
	label.modulate = Color.WHITE
	add_child(label)

# ============================================
# HEALTH CALLBACKS
# ============================================
func _on_player_died():
	"""Spieler ist gestorben"""
	print("Player ", name, " died!")
	
	# Respawn nach 3 Sekunden
	await get_tree().create_timer(3.0).timeout
	_respawn()

func _on_player_damaged(amount: float):
	"""Visuelles Feedback bei Schaden"""
	print("Player ", name, " took ", amount, " damage")

func _respawn():
	"""Respawn Spieler"""
	if health_component:
		health_component.respawn()
	
	current_stamina = MAX_STAMINA
	
	print("Player ", name, " respawned!")
	# TODO: Teleport zu Spawn-Punkt

func get_health_percent() -> float:
	"""Returns HP als Prozent für UI"""
	if health_component:
		return health_component.get_health_percent()
	return 1.0

func take_damage(damage: float, _breaks_guard: bool = false):
	"""Called by external damage sources"""
	if health_component:
		health_component.take_damage(damage)
	print("Player ", name, " took ", damage, " damage")

# ============================================
# CLEANUP
# ============================================
func _exit_tree():
	if is_local_player:
		VoiceChat.stop_recording()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
