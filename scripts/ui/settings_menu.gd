class_name SettingsMenu
extends PanelContainer

## Settings Menu for Finest Garden.
## Controls Audio buses, visual effects, and camera preferences.

signal settings_closed()
signal reset_camera_requested()

@onready var master_slider: HSlider = $Margin/VBox/MasterHBox/MasterSlider
@onready var music_slider: HSlider = $Margin/VBox/MusicHBox/MusicSlider
@onready var sfx_slider: HSlider = $Margin/VBox/SfxHBox/SfxSlider
@onready var reset_cam_btn: Button = $Margin/VBox/ResetCamBtn
@onready var close_btn: Button = $Margin/VBox/CloseBtn


func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func():
			hide()
			settings_closed.emit()
		)
	if reset_cam_btn:
		reset_cam_btn.pressed.connect(func():
			reset_camera_requested.emit()
		)
	
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)


func _on_master_volume_changed(val: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val))


func _on_music_volume_changed(val: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val))


func _on_sfx_volume_changed(val: float) -> void:
	var bus_idx := AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val))
