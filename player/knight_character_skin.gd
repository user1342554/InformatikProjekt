class_name KnightCharacterSkin
extends Node3D

## Knight combat character with melee system
signal stepped
signal hit_landed(damage: float, breaks_guard: bool)
signal parry_success

# Nodes
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var skeleton: Skeleton3D = $knight/Armature/Skeleton3D if has_node("knight/Armature/Skeleton3D") else null
@onready var weapon_socket: BoneAttachment3D = $knight/Armature/Skeleton3D/WeaponSocket if has_node("knight/Armature/Skeleton3D/WeaponSocket") else null
@onready var melee_hitbox: Area3D = $knight/Armature/Skeleton3D/WeaponSocket/MeleeHitbox if has_node("knight/Armature/Skeleton3D/WeaponSocket/MeleeHitbox") else null
@onready var hitbox_collision: CollisionShape3D = $knight/Armature/Skeleton3D/WeaponSocket/MeleeHitbox/CollisionShape3D if has_node("knight/Armature/Skeleton3D/WeaponSocket/MeleeHitbox/CollisionShape3D") else null

# Combat State
enum CombatState {
	IDLE,
	LIGHT_ATTACK,
	HEAVY_ATTACK,
	BLOCKING,
	PARRYING,
	STUNNED
}

var current_state: CombatState = CombatState.IDLE
var is_hitbox_active: bool = false
var is_blocking: bool = false
var can_parry: bool = false
var hit_entities: Array = []

# Combat Stats (managed by Player.gd)
var current_stamina: float = 100.0
var current_power: float = 0.0

# Movement
var moving: bool = false : set = set_moving
var move_speed: float = 0.0 : set = set_moving_speed

# Animation paths
const ANIM_PATHS = {
	"idle": "res://player/MCKnight/sword and shield idle.fbx",
	"walk": "res://player/MCKnight/sword and shield walk.fbx",
	"walk2": "res://player/MCKnight/sword and shield walk (2).fbx",
	"run": "res://player/MCKnight/sword and shield run.fbx",
	"run2": "res://player/MCKnight/sword and shield run (2).fbx",
}

var current_animation: String = "idle"
var animation_library: AnimationLibrary = null


func _ready():
	# Load animations from FBX files
	_load_animations()
	
	# Start with idle
	if animation_player and animation_library:
		play_animation("idle", true)
	
	# Disable hitbox initially
	if melee_hitbox:
		melee_hitbox.monitoring = false
		melee_hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# Check bone attachment
	if weapon_socket:
		print("KnightCharacterSkin: WeaponSocket ready on bone: ", weapon_socket.bone_name)


func _load_animations():
	"""Load animations from separate FBX files"""
	animation_library = AnimationLibrary.new()
	
	print("=== KnightCharacterSkin: Loading animations ===")
	
	for anim_name in ANIM_PATHS:
		var path = ANIM_PATHS[anim_name]
		var scene = load(path)
		
		if scene:
			var instance = scene.instantiate()
			print("\n  Loading: ", anim_name, " from ", path)
			print("  Instance type: ", instance.get_class())
			print("  Instance children: ", instance.get_child_count())
			
			var anim_player = _find_animation_player(instance)
			
			if anim_player:
				var anim_list = anim_player.get_animation_list()
				print("  Found AnimationPlayer with ", anim_list.size(), " animations:")
				for a in anim_list:
					print("    - ", a)
				
				# Try each animation name
				var loaded = false
				for a in anim_list:
					var animation = anim_player.get_animation(a)
					if animation:
						# Retarget animation to our skeleton
						var retargeted = _retarget_animation(animation)
						animation_library.add_animation(anim_name, retargeted)
						print("  ✓ Loaded: ", anim_name, " (from '", a, "')")
						loaded = true
						break
				
				if not loaded:
					print("  ✗ Failed to load any animation from: ", anim_name)
			else:
				print("  ✗ No AnimationPlayer found in: ", anim_name)
			
			instance.queue_free()
		else:
			print("  ✗ Failed to load scene: ", path)
	
	# Add library to player
	if animation_player:
		animation_player.add_animation_library("", animation_library)
		var loaded_anims = animation_library.get_animation_list()
		print("\n=== Animation library ready with ", loaded_anims.size(), " animations:")
		for a in loaded_anims:
			print("  - ", a)
		print("===")


func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Recursively find AnimationPlayer in scene"""
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	return null


func _retarget_animation(animation: Animation) -> Animation:
	"""Retarget animation paths to match our knight's skeleton"""
	var retargeted = animation.duplicate()
	
	# Get our skeleton path
	var our_skeleton_path = skeleton.get_path() if skeleton else NodePath()
	
	# Retarget all tracks
	for track_idx in range(retargeted.get_track_count()):
		var track_path = retargeted.track_get_path(track_idx)
		var path_string = str(track_path)
		
		# Replace skeleton paths to match ours
		# Common patterns: "Armature/Skeleton3D:bone_name" or "skeleton:bone_name"
		if "Skeleton3D:" in path_string or "skeleton:" in path_string:
			# Extract bone name
			var parts = path_string.split(":")
			if parts.size() >= 2:
				var bone_property = parts[1]
				# Create new path targeting our skeleton
				var new_path = String(our_skeleton_path) + ":" + bone_property
				retargeted.track_set_path(track_idx, NodePath(new_path))
				
	return retargeted


func play_animation(anim_name: String, loop: bool = false):
	"""Play animation by name"""
	if not animation_player or not animation_library:
		print("KnightCharacterSkin: Can't play - no player or library")
		return
	
	if animation_library.has_animation(anim_name):
		current_animation = anim_name
		
		# Set looping first
		var animation = animation_library.get_animation(anim_name)
		if animation:
			animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
		
		# Play animation
		animation_player.play(anim_name)
		print("KnightCharacterSkin: Playing animation: ", anim_name, " (loop: ", loop, ")")
	else:
		print("KnightCharacterSkin: Animation not found: ", anim_name)
		print("  Available: ", animation_library.get_animation_list())


func _process(_delta):
	"""Handle animation blending based on movement"""
	if not animation_player or current_state != CombatState.IDLE:
		return
	
	# Blend between idle, walk, and run based on move_speed
	if moving and move_speed > 0.01:
		if move_speed < 0.5:
			# Walking
			if current_animation != "walk":
				play_animation("walk", true)
		else:
			# Running
			if current_animation != "run":
				play_animation("run", true)
	else:
		# Idle
		if current_animation != "idle":
			play_animation("idle", true)


# ============================================
# MOVEMENT
# ============================================
func set_moving(value: bool):
	moving = value

func set_moving_speed(value: float):
	move_speed = clamp(value, 0.0, 1.0)


# ============================================
# COMBAT STATE TRANSITIONS
# ============================================
func light_attack() -> bool:
	if current_state == CombatState.IDLE or current_state == CombatState.BLOCKING:
		current_state = CombatState.LIGHT_ATTACK
		# TODO: Add attack animation
		return true
	return false

func heavy_attack() -> bool:
	if current_state == CombatState.IDLE or current_state == CombatState.BLOCKING:
		current_state = CombatState.HEAVY_ATTACK
		# TODO: Add attack animation
		return true
	return false

func start_block():
	if current_state == CombatState.IDLE:
		current_state = CombatState.BLOCKING
		is_blocking = true
		# TODO: Add block animation

func stop_block():
	if current_state == CombatState.BLOCKING:
		current_state = CombatState.IDLE
		is_blocking = false
		play_animation("idle", true)

func attempt_parry() -> bool:
	if is_blocking and can_parry:
		current_state = CombatState.PARRYING
		can_parry = false
		# TODO: Add parry animation
		return true
	return false

func return_to_idle():
	current_state = CombatState.IDLE
	is_blocking = false
	play_animation("idle", true)


# ============================================
# ANIMATION CALLBACKS (Called from AnimationPlayer)
# ============================================
func consume_stamina(amount: float):
	"""Called at start of attack animations"""
	current_stamina -= amount

func hitbox_on():
	"""Enable melee hitbox during active attack frames"""
	if melee_hitbox:
		is_hitbox_active = true
		melee_hitbox.monitoring = true
		hit_entities.clear()

func hitbox_off():
	"""Disable melee hitbox after attack frames"""
	if melee_hitbox:
		is_hitbox_active = false
		melee_hitbox.monitoring = false
		hit_entities.clear()

func set_guard_breaking(value: bool):
	"""Heavy attacks can break guard"""
	pass

func enable_parry_window():
	"""Enable parry window during block start"""
	can_parry = true
	await get_tree().create_timer(0.15).timeout
	can_parry = false

func on_perfect_parry():
	"""Called when parry succeeds"""
	parry_success.emit()
	current_stamina = min(current_stamina + 20.0, 100.0)

func stun(duration: float):
	"""Stun character (guard broken)"""
	current_state = CombatState.STUNNED
	await get_tree().create_timer(duration).timeout
	return_to_idle()


# ============================================
# HIT DETECTION
# ============================================
func _on_hitbox_body_entered(body: Node3D):
	if not is_hitbox_active:
		return
	
	if body in hit_entities:
		return
	
	hit_entities.append(body)
	
	var damage: float = 0.0
	var breaks_guard: bool = false
	
	match current_state:
		CombatState.LIGHT_ATTACK:
			damage = 20.0
			breaks_guard = false
		CombatState.HEAVY_ATTACK:
			damage = 40.0
			breaks_guard = (current_power >= 50.0)
	
	hit_landed.emit(damage, breaks_guard)
	
	if body.has_method("take_damage"):
		body.take_damage(damage, breaks_guard)


# ============================================
# UTILITY
# ============================================
func jump():
	pass

func fall():
	pass

func _step():
	stepped.emit()
