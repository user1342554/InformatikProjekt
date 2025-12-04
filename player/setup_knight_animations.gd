@tool
extends EditorScript

## Auto-setup script for Knight combat animations
## Run this from Godot Editor: Script > Run Script
## This will add call method tracks to all combat animations

const ANIMATION_CLIPS = {
	"light_attack": "sword and shield attack",
	"heavy_attack": "sword and shield attack (4)",
	"block_loop": "sword and shield block idle",
	"parry": "sword and shield impact"
}

func _run():
	print("=== Knight Animation Setup Script ===")
	
	var scene_path = "res://player/knight_character_skin.tscn"
	var scene = load(scene_path)
	
	if not scene:
		print("ERROR: Could not load knight_character_skin.tscn")
		return
	
	var instance = scene.instantiate()
	var animation_player = find_animation_player(instance)
	
	if not animation_player:
		print("ERROR: Could not find AnimationPlayer in scene")
		instance.queue_free()
		return
	
	print("Found AnimationPlayer: ", animation_player.name)
	
	# Setup each combat animation
	setup_light_attack(animation_player)
	setup_heavy_attack(animation_player)
	setup_block_loop(animation_player)
	setup_parry(animation_player)
	
	# Save the modified scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(instance)
	var save_result = ResourceSaver.save(packed_scene, scene_path)
	
	if save_result == OK:
		print("✓ Successfully saved updated scene!")
	else:
		print("ERROR: Failed to save scene")
	
	instance.queue_free()
	print("=== Setup Complete ===")


func find_animation_player(node: Node) -> AnimationPlayer:
	"""Recursively find AnimationPlayer in scene"""
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = find_animation_player(child)
		if result:
			return result
	
	return null


func setup_light_attack(anim_player: AnimationPlayer):
	"""Setup Light Attack animation with call method tracks"""
	var anim_name = ANIMATION_CLIPS.get("light_attack", "")
	
	if not anim_player.has_animation(anim_name):
		print("WARNING: Animation '", anim_name, "' not found. Skipping.")
		return
	
	var animation: Animation = anim_player.get_animation(anim_name)
	var root_path = NodePath("../../..")
	
	# Check if track already exists
	var track_idx = -1
	for i in animation.get_track_count():
		if animation.track_get_type(i) == Animation.TYPE_METHOD:
			track_idx = i
			break
	
	# Create new track if needed
	if track_idx == -1:
		track_idx = animation.add_track(Animation.TYPE_METHOD)
		animation.track_set_path(track_idx, root_path)
	
	# Clear existing keys
	while animation.track_get_key_count(track_idx) > 0:
		animation.track_remove_key(track_idx, 0)
	
	# Add keys
	animation.track_insert_key(track_idx, 0.0, {
		"method": "consume_stamina",
		"args": [15.0]
	})
	
	animation.track_insert_key(track_idx, 0.15, {
		"method": "hitbox_on",
		"args": []
	})
	
	animation.track_insert_key(track_idx, 0.35, {
		"method": "hitbox_off",
		"args": []
	})
	
	print("✓ Setup Light Attack animation")


func setup_heavy_attack(anim_player: AnimationPlayer):
	"""Setup Heavy Attack animation with call method tracks"""
	var anim_name = ANIMATION_CLIPS.get("heavy_attack", "")
	
	if not anim_player.has_animation(anim_name):
		print("WARNING: Animation '", anim_name, "' not found. Skipping.")
		return
	
	var animation: Animation = anim_player.get_animation(anim_name)
	var root_path = NodePath("../../..")
	
	# Check if track already exists
	var track_idx = -1
	for i in animation.get_track_count():
		if animation.track_get_type(i) == Animation.TYPE_METHOD:
			track_idx = i
			break
	
	# Create new track if needed
	if track_idx == -1:
		track_idx = animation.add_track(Animation.TYPE_METHOD)
		animation.track_set_path(track_idx, root_path)
	
	# Clear existing keys
	while animation.track_get_key_count(track_idx) > 0:
		animation.track_remove_key(track_idx, 0)
	
	# Add keys
	animation.track_insert_key(track_idx, 0.0, {
		"method": "consume_stamina",
		"args": [35.0]
	})
	
	animation.track_insert_key(track_idx, 0.0, {
		"method": "set_guard_breaking",
		"args": [true]
	})
	
	animation.track_insert_key(track_idx, 0.2, {
		"method": "hitbox_on",
		"args": []
	})
	
	animation.track_insert_key(track_idx, 0.5, {
		"method": "hitbox_off",
		"args": []
	})
	
	print("✓ Setup Heavy Attack animation")


func setup_block_loop(anim_player: AnimationPlayer):
	"""Setup Block Loop animation with call method tracks"""
	var anim_name = ANIMATION_CLIPS.get("block_loop", "")
	
	if not anim_player.has_animation(anim_name):
		print("WARNING: Animation '", anim_name, "' not found. Skipping.")
		return
	
	var animation: Animation = anim_player.get_animation(anim_name)
	var root_path = NodePath("../../..")
	
	# Check if track already exists
	var track_idx = -1
	for i in animation.get_track_count():
		if animation.track_get_type(i) == Animation.TYPE_METHOD:
			track_idx = i
			break
	
	# Create new track if needed
	if track_idx == -1:
		track_idx = animation.add_track(Animation.TYPE_METHOD)
		animation.track_set_path(track_idx, root_path)
	
	# Clear existing keys
	while animation.track_get_key_count(track_idx) > 0:
		animation.track_remove_key(track_idx, 0)
	
	# Add keys
	animation.track_insert_key(track_idx, 0.0, {
		"method": "enable_parry_window",
		"args": []
	})
	
	print("✓ Setup Block Loop animation")


func setup_parry(anim_player: AnimationPlayer):
	"""Setup Parry animation with call method tracks"""
	var anim_name = ANIMATION_CLIPS.get("parry", "")
	
	if not anim_player.has_animation(anim_name):
		print("WARNING: Animation '", anim_name, "' not found. Skipping.")
		return
	
	var animation: Animation = anim_player.get_animation(anim_name)
	var root_path = NodePath("../../..")
	
	# Check if track already exists
	var track_idx = -1
	for i in animation.get_track_count():
		if animation.track_get_type(i) == Animation.TYPE_METHOD:
			track_idx = i
			break
	
	# Create new track if needed
	if track_idx == -1:
		track_idx = animation.add_track(Animation.TYPE_METHOD)
		animation.track_set_path(track_idx, root_path)
	
	# Clear existing keys
	while animation.track_get_key_count(track_idx) > 0:
		animation.track_remove_key(track_idx, 0)
	
	# Add keys
	animation.track_insert_key(track_idx, 0.1, {
		"method": "on_perfect_parry",
		"args": []
	})
	
	print("✓ Setup Parry animation")

