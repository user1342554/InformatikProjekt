extends Control

# Audio settings
@onready var master_volume_slider = $Panel/MainVBox/TabContainer/Audio/AudioVBox/MasterVolumeSlider
@onready var master_volume_label = $Panel/MainVBox/TabContainer/Audio/AudioVBox/MasterVolumeLabel
@onready var voice_volume_slider = $Panel/MainVBox/TabContainer/Audio/AudioVBox/VoiceVolumeSlider
@onready var voice_volume_label = $Panel/MainVBox/TabContainer/Audio/AudioVBox/VoiceVolumeLabel
@onready var voice_range_slider = $Panel/MainVBox/TabContainer/Audio/AudioVBox/VoiceRangeSlider
@onready var voice_range_label = $Panel/MainVBox/TabContainer/Audio/AudioVBox/VoiceRangeLabel
@onready var mic_gain_slider = $Panel/MainVBox/TabContainer/Audio/AudioVBox/MicGainSlider
@onready var mic_gain_label = $Panel/MainVBox/TabContainer/Audio/AudioVBox/MicGainLabel
@onready var audio_reset_button = $Panel/MainVBox/TabContainer/Audio/AudioVBox/AudioResetButton

# Graphics settings - Preset
@onready var preset_option = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/PresetOption

# Graphics settings - Anti-Aliasing
@onready var msaa_option = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/MSAAContainer/MSAAOption
@onready var taa_check = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/TAAContainer/TAACheck
@onready var fxaa_check = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/FXAAContainer/FXAACheck

# Graphics settings - Scaling
@onready var scaling_mode_option = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/ScalingModeContainer/ScalingModeOption
@onready var render_scale_slider = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/RenderScaleSlider
@onready var render_scale_label = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/RenderScaleLabel

# Graphics settings - Shadows
@onready var shadow_option = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/ShadowContainer/ShadowOption

# Graphics settings - GI
@onready var sdfgi_check = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/SDFGIContainer/SDFGICheck
@onready var ssil_check = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/SSILContainer/SSILCheck

# Graphics settings - Screen-Space Effects
@onready var ssao_check = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/SSAOContainer/SSAOCheck
@onready var ssr_check = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/SSRContainer/SSRCheck

# Graphics settings - Post-Processing
@onready var tonemap_option = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/TonemapContainer/TonemapOption
@onready var bloom_check = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/BloomContainer/BloomCheck
@onready var bloom_intensity_slider = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/BloomIntensitySlider
@onready var bloom_intensity_label = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/BloomIntensityLabel
@onready var volumetric_fog_check = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/VolumetricFogContainer/VolumetricFogCheck

# Graphics settings - Performance
@onready var fps_counter_check = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/FPSCounterContainer/FPSCounterCheck
@onready var vsync_check = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/VSyncContainer/VSyncCheck
@onready var fps_limit_slider = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/FPSLimitSlider
@onready var fps_limit_label = $Panel/MainVBox/TabContainer/Graphics/GraphicsVBox/FPSLimitLabel

# Buttons
@onready var back_button = $Panel/MainVBox/ButtonsHBox/BackButton
@onready var reset_button = $Panel/MainVBox/ButtonsHBox/ResetButton

var is_updating_ui := false  # Prevent recursive updates

func _ready():
	_setup_options()
	_connect_signals()
	_load_current_values()
	
	# Listen for external settings changes
	GraphicsSettings.settings_changed.connect(_load_current_values)

func _setup_options():
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

func _connect_signals():
	# Buttons
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	
	# Audio settings
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	voice_volume_slider.value_changed.connect(_on_voice_volume_changed)
	voice_range_slider.value_changed.connect(_on_voice_range_changed)
	mic_gain_slider.value_changed.connect(_on_mic_gain_changed)
	audio_reset_button.pressed.connect(_on_audio_reset_pressed)
	
	# Graphics - Preset
	preset_option.item_selected.connect(_on_preset_selected)
	
	# Graphics - AA
	msaa_option.item_selected.connect(_on_msaa_changed)
	taa_check.toggled.connect(_on_taa_toggled)
	fxaa_check.toggled.connect(_on_fxaa_toggled)
	
	# Graphics - Scaling
	scaling_mode_option.item_selected.connect(_on_scaling_mode_changed)
	render_scale_slider.value_changed.connect(_on_render_scale_changed)
	
	# Graphics - Shadows
	shadow_option.item_selected.connect(_on_shadow_changed)
	
	# Graphics - GI
	sdfgi_check.toggled.connect(_on_sdfgi_toggled)
	ssil_check.toggled.connect(_on_ssil_toggled)
	
	# Graphics - Screen-Space
	ssao_check.toggled.connect(_on_ssao_toggled)
	ssr_check.toggled.connect(_on_ssr_toggled)
	
	# Graphics - Post-Processing
	tonemap_option.item_selected.connect(_on_tonemap_changed)
	bloom_check.toggled.connect(_on_bloom_toggled)
	bloom_intensity_slider.value_changed.connect(_on_bloom_intensity_changed)
	volumetric_fog_check.toggled.connect(_on_volumetric_fog_toggled)
	
	# Graphics - Performance
	fps_counter_check.toggled.connect(_on_fps_counter_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	fps_limit_slider.value_changed.connect(_on_fps_limit_changed)

func _load_current_values():
	is_updating_ui = true
	
	# Load audio settings
	_load_audio_settings()
	
	# Graphics settings
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
	_update_audio_labels()

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
	if VoiceChat:
		VoiceChat.voice_volume = voice_volume_slider.value / 100.0
		VoiceChat.voice_range = voice_range_slider.value
		VoiceChat.mic_gain = mic_gain_slider.value / 100.0

func _update_audio_labels():
	master_volume_label.text = "Master Volume: %d%%" % int(master_volume_slider.value)
	voice_volume_label.text = "Voice Chat Volume: %d%%" % int(voice_volume_slider.value)
	voice_range_label.text = "Voice Range: %d m" % int(voice_range_slider.value)
	mic_gain_label.text = "Microphone Gain: %d%%" % int(mic_gain_slider.value)

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

# Button handlers
func _on_back_pressed():
	var multiplayer_menu = _get_multiplayer_menu()
	if multiplayer_menu:
		multiplayer_menu.show_main_menu()

func _on_reset_pressed():
	GraphicsSettings.reset_to_defaults()
	_load_current_values()
	print("Settings reset to defaults")

# Audio handlers
func _on_master_volume_changed(value: float):
	if is_updating_ui: return
	_apply_audio_settings()
	_update_audio_labels()
	_save_audio_settings()

func _on_voice_volume_changed(value: float):
	if is_updating_ui: return
	_apply_audio_settings()
	_update_audio_labels()
	_save_audio_settings()

func _on_voice_range_changed(value: float):
	if is_updating_ui: return
	_apply_audio_settings()
	_update_audio_labels()
	_save_audio_settings()

func _on_mic_gain_changed(value: float):
	if is_updating_ui: return
	_apply_audio_settings()
	_update_audio_labels()
	_save_audio_settings()

func _on_audio_reset_pressed():
	is_updating_ui = true
	master_volume_slider.value = 100.0
	voice_volume_slider.value = 100.0
	voice_range_slider.value = 20.0
	mic_gain_slider.value = 100.0
	is_updating_ui = false
	_apply_audio_settings()
	_update_audio_labels()
	_save_audio_settings()
	print("Audio settings reset to defaults")

# Graphics handlers
func _on_preset_selected(index: int):
	if is_updating_ui: return
	match index:
		0:
			GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.POTATO)
		1:
			GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.ULTRA_LOW)
		2:
			GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.LOW)
		3:
			GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.MEDIUM)
		4:
			GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.HIGH)
		5:
			GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.ULTRA)
		6:
			GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.PAID_FOR_WHOLE_PC)
	# Reload UI to show preset values
	_load_current_values()

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

func _mark_as_custom():
	if GraphicsSettings.current_preset != GraphicsSettings.QualityPreset.CUSTOM:
		is_updating_ui = true
		preset_option.select(7)  # Custom
		is_updating_ui = false

func _get_multiplayer_menu():
	var node = get_parent()
	while node:
		if node.has_method("show_main_menu"):
			return node
		node = node.get_parent() if node.get_parent() != node else null
	return null
