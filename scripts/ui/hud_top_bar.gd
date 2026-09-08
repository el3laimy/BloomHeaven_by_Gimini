class_name HudTopBar
extends PanelContainer

## Slim Storybook Top Bar Component for BloomHaven HUD.
## Displays cozy logo, coins purse, satchel inventory toggle, pacing speed, and settings.

signal satchel_toggled()
signal settings_requested()
signal speed_changed(multiplier: float)
signal zoom_in_requested()
signal zoom_out_requested()

# Backward compatible signals
signal open_breeding_lab()
signal open_bouquet_workshop()
signal open_journal()
signal open_requests()

@onready var coins_label: Label = $Margin/HBox/CoinsHBox/CoinsLabel
@onready var satchel_btn: Button = $Margin/HBox/SatchelBtn
@onready var speed_btn: Button = $Margin/HBox/SpeedBtn
@onready var settings_btn: Button = $Margin/HBox/SettingsBtn

var current_speed: float = 1.0


func _ready() -> void:
	if satchel_btn:
		satchel_btn.pressed.connect(func():
			satchel_toggled.emit()
			_play_click()
		)
	if speed_btn:
		speed_btn.pressed.connect(_on_speed_toggle)
	if settings_btn:
		settings_btn.pressed.connect(func():
			settings_requested.emit()
			_play_click()
		)


func set_coins(amount: int) -> void:
	if coins_label:
		coins_label.text = "%d" % amount


func _on_speed_toggle() -> void:
	if is_equal_approx(current_speed, 1.0):
		current_speed = 2.0
	elif is_equal_approx(current_speed, 2.0):
		current_speed = 5.0
	else:
		current_speed = 1.0

	if speed_btn:
		speed_btn.text = "⚡ %.0fx" % current_speed
	speed_changed.emit(current_speed)
	_play_click()


func _play_click() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		var am = get_tree().root.get_node("AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.play_sfx("click")
