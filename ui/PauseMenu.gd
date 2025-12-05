extends Control

signal resume_pressed
signal disconnect_pressed

@onready var resume_button = $Panel/VBox/ResumeButton
@onready var settings_button = $Panel/VBox/SettingsButton
@onready var disconnect_button = $Panel/VBox/DisconnectButton
@onready var quit_button = $Panel/VBox/QuitButton

@onready var settings_panel = $SettingsPanel

# Audio Settings references
@onready var master_volume_slider = $SettingsPanel/Panel/VBox/TabContainer/Audio/AudioVBox/MasterVolumeSlider
@onready var master_volume_label = $SettingsPanel/Panel/VBox/TabContainer/Audio/AudioVBox/MasterVolumeLabel
@onready var voice_volume_slider = $SettingsPanel/Panel/VBox/TabContainer/Audio/AudioVBox/VoiceVolumeSlider
@onready var voice_volume_label = $SettingsPanel/Panel/VBox/TabContainer/Audio/AudioVBox/VoiceVolumeLabel
@onready var voice_range_slider = $SettingsPanel/Panel/VBox/TabContainer/Audio/AudioVBox/VoiceRangeSlider
@onready var voice_range_label = $SettingsPanel/Panel/VBox/TabContainer/Audio/AudioVBox/VoiceRangeLabel
@onready var mic_gain_slider = $SettingsPanel/Panel/VBox/TabContainer/Audio/AudioVBox/MicGainSlider
@onready var mic_gain_label = $SettingsPanel/Panel/VBox/TabContainer/Audio/AudioVBox/MicGainLabel
@onready var input_device_option = $SettingsPanel/Panel/VBox/TabContainer/Audio/AudioVBox/InputDeviceOption
@onready var output_device_option = $SettingsPanel/Panel/VBox/TabContainer/Audio/AudioVBox/OutputDeviceOption
@onready var audio_reset_button = $SettingsPanel/Panel/VBox/TabContainer/Audio/AudioVBox/AudioResetButton
@onready var settings_back_button = $SettingsPanel/Panel/VBox/BackButton

# Graphics Settings references
@onready var preset_option = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/PresetOption
@onready var msaa_option = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/MSAAContainer/MSAAOption
@onready var taa_check = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/TAAContainer/TAACheck
@onready var fxaa_check = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/FXAAContainer/FXAACheck
@onready var scaling_mode_option = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/ScalingModeContainer/ScalingModeOption
@onready var render_scale_slider = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/RenderScaleSlider
@onready var render_scale_label = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/RenderScaleLabel
@onready var shadow_option = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/ShadowContainer/ShadowOption
@onready var sdfgi_check = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/SDFGIContainer/SDFGICheck
@onready var ssil_check = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/SSILContainer/SSILCheck
@onready var ssao_check = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/SSAOContainer/SSAOCheck
@onready var ssr_check = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/SSRContainer/SSRCheck
@onready var tonemap_option = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/TonemapContainer/TonemapOption
@onready var bloom_check = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/BloomContainer/BloomCheck
@onready var bloom_intensity_slider = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/BloomIntensitySlider
@onready var bloom_intensity_label = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/BloomIntensityLabel
@onready var volumetric_fog_check = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/VolumetricFogContainer/VolumetricFogCheck
@onready var fps_counter_check = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/FPSCounterContainer/FPSCounterCheck
@onready var vsync_check = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/VSyncContainer/VSyncCheck
@onready var fps_limit_slider = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/FPSLimitSlider
@onready var fps_limit_label = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/FPSLimitLabel
@onready var reset_button = $SettingsPanel/Panel/VBox/TabContainer/Graphics/GraphicsVBox/ResetButton

# Controls references
@onready var controls_list = $SettingsPanel/Panel/VBox/TabContainer/Controls/ControlsList

var is_paused = false
var awaiting_input = false
var current_action = ""
var is_updating_ui = false

func _ready():
	hide()
	set_process_input(true)
	
	# Connect main buttons
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect audio settings
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	voice_volume_slider.value_changed.connect(_on_voice_volume_changed)
	voice_range_slider.value_changed.connect(_on_voice_range_changed)
	mic_gain_slider.value_changed.connect(_on_mic_gain_changed)
	audio_reset_button.pressed.connect(_on_audio_reset_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)
	
	# Connect graphics settings
	_setup_graphics_options()
	_connect_graphics_signals()
	
	# Listen for external graphics settings changes
	GraphicsSettings.settings_changed.connect(_load_graphics_values)
	
	# Initialize settings
	_init_settings()
	_populate_controls()

func _input(event):
	if event.is_action_pressed("ui_cancel") and not awaiting_input:
		if is_paused:
			_on_resume_pressed()
		else:
			show_pause_menu()
	
	# Handle key rebinding
	if awaiting_input and event is InputEventKey and event.pressed:
		_assign_key_to_action(current_action, event)
		awaiting_input = false

func show_pause_menu():
	is_paused = true
	show()
	settings_panel.hide()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func hide_pause_menu():
	is_paused = false
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed():
	hide_pause_menu()
	resume_pressed.emit()

func _on_settings_pressed():
	settings_panel.show()

func _on_disconnect_pressed():
	hide_pause_menu()
	disconnect_pressed.emit()
	# Also go to main menu
	var tree = get_tree()
	if tree:
		tree.paused = false
		tree.change_scene_to_file("res://ui/MultiplayerMenu.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_settings_back_pressed():
	settings_panel.hide()

# Settings functions
func _init_settings():
	# Load saved audio settings or use defaults
	_load_audio_settings()
	
	# Populate audio devices
	_populate_audio_devices()
	
	_update_audio_labels()

func _load_audio_settings():
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	
	if err == OK:
		master_volume_slider.value = config.get_value("audio", "master_volume", 100.0)
		voice_volume_slider.value = config.get_value("audio", "voice_volume", 100.0)
		voice_range_slider.value = config.get_value("audio", "voice_range", 20.0)
		mic_gain_slider.value = config.get_value("audio", "mic_gain", 100.0)
	else:
		# Defaults
		master_volume_slider.value = 100.0
		voice_volume_slider.value = 100.0
		voice_range_slider.value = 20.0
		mic_gain_slider.value = 100.0
	
	_apply_audio_settings()

func _save_audio_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume_slider.value)
	config.set_value("audio", "voice_volume", voice_volume_slider.value)
	config.set_value("audio", "voice_range", voice_range_slider.value)
	config.set_value("audio", "mic_gain", mic_gain_slider.value)
	config.save("user://audio_settings.cfg")

func _apply_audio_settings():
	# Master volume (affects Master bus)
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume_slider.value / 100.0))
	
	# Voice chat volume
	VoiceChat.voice_volume = voice_volume_slider.value / 100.0
	
	# Voice range
	VoiceChat.voice_range = voice_range_slider.value
	
	# Mic gain
	VoiceChat.mic_gain = mic_gain_slider.value / 100.0

func _on_master_volume_changed(value: float):
	_apply_audio_settings()
	_update_audio_labels()
	_save_audio_settings()

func _on_voice_volume_changed(value: float):
	_apply_audio_settings()
	_update_audio_labels()
	_save_audio_settings()

func _on_voice_range_changed(value: float):
	_apply_audio_settings()
	_update_audio_labels()
	_save_audio_settings()

func _on_mic_gain_changed(value: float):
	_apply_audio_settings()
	_update_audio_labels()
	_save_audio_settings()

func _on_audio_reset_pressed():
	master_volume_slider.value = 100.0
	voice_volume_slider.value = 100.0
	voice_range_slider.value = 20.0
	mic_gain_slider.value = 100.0
	_apply_audio_settings()
	_update_audio_labels()
	_save_audio_settings()
	print("Audio settings reset to defaults")

func _update_audio_labels():
	master_volume_label.text = "Master Volume: %d%%" % int(master_volume_slider.value)
	voice_volume_label.text = "Voice Chat Volume: %d%%" % int(voice_volume_slider.value)
	voice_range_label.text = "Voice Range: %d m" % int(voice_range_slider.value)
	mic_gain_label.text = "Microphone Gain: %d%%" % int(mic_gain_slider.value)

func _populate_audio_devices():
	# Get audio devices from AudioServer
	input_device_option.clear()
	output_device_option.clear()
	
	# Add input devices (microphones)
	var input_devices = AudioServer.get_input_device_list()
	for device in input_devices:
		input_device_option.add_item(device)
	
	# Set current input device
	var current_input = AudioServer.input_device
	for i in range(input_device_option.get_item_count()):
		if input_device_option.get_item_text(i) == current_input:
			input_device_option.selected = i
			break
	
	# Add output devices (speakers/headphones)
	var output_devices = AudioServer.get_output_device_list()
	for device in output_devices:
		output_device_option.add_item(device)
	
	# Set current output device
	var current_output = AudioServer.output_device
	for i in range(output_device_option.get_item_count()):
		if output_device_option.get_item_text(i) == current_output:
			output_device_option.selected = i
			break
	
	# Connect signals
	input_device_option.item_selected.connect(_on_input_device_selected)
	output_device_option.item_selected.connect(_on_output_device_selected)

func _on_input_device_selected(index: int):
	var device_name = input_device_option.get_item_text(index)
	AudioServer.input_device = device_name
	print("Input device changed to: ", device_name)

func _on_output_device_selected(index: int):
	var device_name = output_device_option.get_item_text(index)
	AudioServer.output_device = device_name
	print("Output device changed to: ", device_name)

# Controls remapping
func _populate_controls():
	# Clear existing controls
	for child in controls_list.get_children():
		child.queue_free()
	
	# Add all input actions (without talk - automatic voice)
	var actions = [
		"move_forward",
		"move_back", 
		"move_left",
		"move_right",
		"jump",
		"dodge",
		"sprint",
		"sneak"
	]
	
	for action in actions:
		if InputMap.has_action(action):
			_add_control_row(action)

func _add_control_row(action: String):
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(400, 40)
	
	# Action label
	var label = Label.new()
	label.text = action.capitalize()
	label.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(label)
	
	# Current key display
	var key_label = Label.new()
	key_label.name = "KeyLabel"
	key_label.text = _get_action_key_string(action)
	key_label.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(key_label)
	
	# Rebind button
	var button = Button.new()
	button.text = "Rebind"
	button.pressed.connect(_on_rebind_pressed.bind(action, key_label))
	hbox.add_child(button)
	
	controls_list.add_child(hbox)

func _get_action_key_string(action: String) -> String:
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		var event = events[0]
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode)
	return "None"

func _on_rebind_pressed(action: String, key_label: Label):
	awaiting_input = true
	current_action = action
	key_label.text = "Press key..."

func _assign_key_to_action(action: String, event: InputEventKey):
	# Clear existing keys for this action
	InputMap.action_erase_events(action)
	
	# Add new key
	InputMap.action_add_event(action, event)
	
	# Update display
	_populate_controls()
	print("Rebound ", action, " to ", OS.get_keycode_string(event.physical_keycode))

# ============================================
# Graphics Settings Functions
# ============================================

func _setup_graphics_options():
	# Preset options
	preset_option.clear()
	preset_option.add_item("Potato (Lowest)", 0)
	preset_option.add_item("Ultra Low", 1)
	preset_option.add_item("Low", 2)
	preset_option.add_item("Medium", 3)
	preset_option.add_item("High", 4)
	preset_option.add_item("Ultra", 5)
	preset_option.add_item("I Paid For The Whole PC", 6)
	preset_option.add_item("Custom", 7)
	
	# MSAA options
	msaa_option.clear()
	msaa_option.add_item("Off", 0)
	msaa_option.add_item("2x", 1)
	msaa_option.add_item("4x", 2)
	msaa_option.add_item("8x", 3)
	
	# Scaling mode options
	scaling_mode_option.clear()
	scaling_mode_option.add_item("Bilinear", 0)
	scaling_mode_option.add_item("FSR 1.0", 1)
	scaling_mode_option.add_item("FSR 2.0", 2)
	
	# Shadow quality options
	shadow_option.clear()
	shadow_option.add_item("Off", 0)
	shadow_option.add_item("Low", 1)
	shadow_option.add_item("Medium", 2)
	shadow_option.add_item("High", 3)
	
	# Tonemap options
	tonemap_option.clear()
	tonemap_option.add_item("Linear", 0)
	tonemap_option.add_item("Reinhard", 1)
	tonemap_option.add_item("Filmic", 2)
	tonemap_option.add_item("ACES", 3)
	
	# Load current values
	_load_graphics_values()

func _connect_graphics_signals():
	preset_option.item_selected.connect(_on_preset_selected)
	msaa_option.item_selected.connect(_on_msaa_changed)
	taa_check.toggled.connect(_on_taa_toggled)
	fxaa_check.toggled.connect(_on_fxaa_toggled)
	scaling_mode_option.item_selected.connect(_on_scaling_mode_changed)
	render_scale_slider.value_changed.connect(_on_render_scale_changed)
	shadow_option.item_selected.connect(_on_shadow_changed)
	sdfgi_check.toggled.connect(_on_sdfgi_toggled)
	ssil_check.toggled.connect(_on_ssil_toggled)
	ssao_check.toggled.connect(_on_ssao_toggled)
	ssr_check.toggled.connect(_on_ssr_toggled)
	tonemap_option.item_selected.connect(_on_tonemap_changed)
	bloom_check.toggled.connect(_on_bloom_toggled)
	bloom_intensity_slider.value_changed.connect(_on_bloom_intensity_changed)
	volumetric_fog_check.toggled.connect(_on_volumetric_fog_toggled)
	fps_counter_check.toggled.connect(_on_fps_counter_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	fps_limit_slider.value_changed.connect(_on_fps_limit_changed)
	reset_button.pressed.connect(_on_reset_pressed)

func _load_graphics_values():
	is_updating_ui = true
	
	preset_option.select(GraphicsSettings.current_preset)
	msaa_option.select(GraphicsSettings.msaa_quality)
	taa_check.button_pressed = GraphicsSettings.taa_enabled
	fxaa_check.button_pressed = GraphicsSettings.screen_space_aa > 0
	scaling_mode_option.select(GraphicsSettings.scaling_mode)
	render_scale_slider.value = GraphicsSettings.render_scale * 100
	_update_render_scale_label()
	shadow_option.select(GraphicsSettings.shadow_quality)
	sdfgi_check.button_pressed = GraphicsSettings.sdfgi_enabled
	ssil_check.button_pressed = GraphicsSettings.ssil_enabled
	ssao_check.button_pressed = GraphicsSettings.ssao_enabled
	ssr_check.button_pressed = GraphicsSettings.ssr_enabled
	tonemap_option.select(GraphicsSettings.tonemap_mode)
	bloom_check.button_pressed = GraphicsSettings.bloom_enabled
	bloom_intensity_slider.value = GraphicsSettings.bloom_intensity
	_update_bloom_intensity_label()
	volumetric_fog_check.button_pressed = GraphicsSettings.volumetric_fog_enabled
	fps_counter_check.button_pressed = GraphicsSettings.show_fps_counter
	vsync_check.button_pressed = GraphicsSettings.vsync_enabled
	fps_limit_slider.value = GraphicsSettings.target_fps
	_update_fps_limit_label()
	
	is_updating_ui = false

func _update_render_scale_label():
	render_scale_label.text = "Render Scale: %d%%" % int(render_scale_slider.value)

func _update_bloom_intensity_label():
	bloom_intensity_label.text = "Bloom Intensity: %.2f" % bloom_intensity_slider.value

func _update_fps_limit_label():
	var fps = int(fps_limit_slider.value)
	if fps == 0:
		fps_limit_label.text = "FPS Limit: Unlimited"
	else:
		fps_limit_label.text = "FPS Limit: %d" % fps

func _on_preset_selected(index: int):
	if is_updating_ui: return
	match index:
		0: GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.POTATO)
		1: GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.ULTRA_LOW)
		2: GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.LOW)
		3: GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.MEDIUM)
		4: GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.HIGH)
		5: GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.ULTRA)
		6: GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.PAID_FOR_WHOLE_PC)
	_load_graphics_values()

func _on_msaa_changed(index: int):
	if is_updating_ui: return
	GraphicsSettings.set_msaa_quality(index)
	_mark_as_custom()

func _on_taa_toggled(enabled: bool):
	if is_updating_ui: return
	GraphicsSettings.set_taa_enabled(enabled)
	_mark_as_custom()

func _on_fxaa_toggled(enabled: bool):
	if is_updating_ui: return
	GraphicsSettings.set_screen_space_aa(1 if enabled else 0)
	_mark_as_custom()

func _on_scaling_mode_changed(index: int):
	if is_updating_ui: return
	GraphicsSettings.set_scaling_mode(index)
	_mark_as_custom()

func _on_render_scale_changed(value: float):
	if is_updating_ui: return
	GraphicsSettings.set_render_scale(value / 100.0)
	_update_render_scale_label()
	_mark_as_custom()

func _on_shadow_changed(index: int):
	if is_updating_ui: return
	GraphicsSettings.set_shadow_quality(index)
	_mark_as_custom()

func _on_sdfgi_toggled(enabled: bool):
	if is_updating_ui: return
	GraphicsSettings.set_sdfgi_enabled(enabled)
	_mark_as_custom()

func _on_ssil_toggled(enabled: bool):
	if is_updating_ui: return
	GraphicsSettings.set_ssil_enabled(enabled)
	_mark_as_custom()

func _on_ssao_toggled(enabled: bool):
	if is_updating_ui: return
	GraphicsSettings.set_ssao_enabled(enabled)
	_mark_as_custom()

func _on_ssr_toggled(enabled: bool):
	if is_updating_ui: return
	GraphicsSettings.set_ssr_enabled(enabled)
	_mark_as_custom()

func _on_tonemap_changed(index: int):
	if is_updating_ui: return
	GraphicsSettings.set_tonemap_mode(index)
	_mark_as_custom()

func _on_bloom_toggled(enabled: bool):
	if is_updating_ui: return
	GraphicsSettings.set_bloom_enabled(enabled)
	_mark_as_custom()

func _on_bloom_intensity_changed(value: float):
	if is_updating_ui: return
	GraphicsSettings.set_bloom_intensity(value)
	_update_bloom_intensity_label()
	_mark_as_custom()

func _on_volumetric_fog_toggled(enabled: bool):
	if is_updating_ui: return
	GraphicsSettings.set_volumetric_fog_enabled(enabled)
	_mark_as_custom()

func _on_fps_counter_toggled(enabled: bool):
	if is_updating_ui: return
	GraphicsSettings.set_show_fps_counter(enabled)

func _on_vsync_toggled(enabled: bool):
	if is_updating_ui: return
	GraphicsSettings.set_vsync(enabled)

func _on_fps_limit_changed(value: float):
	if is_updating_ui: return
	GraphicsSettings.set_target_fps(int(value))
	_update_fps_limit_label()

func _on_reset_pressed():
	GraphicsSettings.reset_to_defaults()
	_load_graphics_values()

func _mark_as_custom():
	if GraphicsSettings.current_preset != GraphicsSettings.QualityPreset.CUSTOM:
		is_updating_ui = true
		preset_option.select(7)  # Custom
		is_updating_ui = false
