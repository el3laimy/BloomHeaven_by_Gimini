extends Control
class_name TopLeftCluster

## Top-Left Branding, Coins, Satchel, and Settings Cluster

signal settings_requested
signal satchel_toggle_requested
signal coins_plus_requested

@onready var coins_label: Label = $VBox/CoinsPill/Margin/HBox/CoinsVal
@onready var satchel_label: Label = $VBox/SatchelPill/Margin/HBox/SatchelVal
@onready var satchel_btn: TextureButton = $VBox/SatchelPill/Margin/HBox/PlusBtn
@onready var pill_click_btn: Button = $VBox/SatchelPill/PillClickBtn
@onready var coins_btn: TextureButton = $VBox/CoinsPill/Margin/HBox/PlusBtn
@onready var settings_btn: TextureButton = $VBox/SettingsBtn


func _ready() -> void:
	if satchel_btn != null:
		satchel_btn.pressed.connect(func(): satchel_toggle_requested.emit())
	if pill_click_btn != null:
		pill_click_btn.pressed.connect(func(): satchel_toggle_requested.emit())
	if coins_btn != null:
		coins_btn.pressed.connect(func(): coins_plus_requested.emit())
	if settings_btn != null:
		settings_btn.pressed.connect(func(): settings_requested.emit())


func update_values(coins: int, total_flowers: int) -> void:
	if coins_label != null:
		coins_label.text = "%s" % _format_number(coins)
	if satchel_label != null:
		if total_flowers > 0:
			satchel_label.text = "Stand: %d" % total_flowers
			satchel_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.65, 1.0))
		else:
			satchel_label.text = "Stand [S]"
			satchel_label.add_theme_color_override("font_color", Color(0.85, 0.98, 0.8, 1.0))


func _format_number(n: int) -> String:
	var s := str(n)
	var res := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			res = "," + res
	return res
