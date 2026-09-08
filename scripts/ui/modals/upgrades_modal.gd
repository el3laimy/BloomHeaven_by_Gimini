class_name UpgradesModal
extends Control

## Standalone UI Modal for the Garden Shed Upgrades Shop (Fiona Finch style).

signal upgrade_purchased(upgrade_id: String)
signal closed()

@onready var _card_container: VBoxContainer = $CenterContainer/Panel/Margin/VBox/Scroll/CardsVBox
@onready var _close_btn: Button = $CenterContainer/Panel/Margin/VBox/HeaderHBox/CloseBtn

var active_upgrades: Dictionary = {}
var current_coins: int = 0


func _ready() -> void:
	if _close_btn != null:
		_close_btn.pressed.connect(func():
			_play_click()
			hide()
			closed.emit()
		)


func open_shop(upgrades_state: Dictionary, coins: int) -> void:
	active_upgrades = upgrades_state
	current_coins = coins
	_populate_upgrades()
	show()


func _populate_upgrades() -> void:
	if _card_container == null:
		return

	for child in _card_container.get_children():
		child.queue_free()

	var path := "res://data/upgrades.json"
	if not FileAccess.file_exists(path):
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not (json.data is Dictionary):
		return

	var list: Array = json.data.get("upgrades", [])
	for up in list:
		var card := _create_upgrade_card(up)
		_card_container.add_child(card)


func _create_upgrade_card(up_data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = up_data.get("icon", "🛠️")
	icon_lbl.add_theme_font_size_override("font_size", 20)
	hbox.add_child(icon_lbl)

	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var name_lbl := Label.new()
	name_lbl.text = up_data.get("name", "Upgrade")
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70))
	text_vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = up_data.get("description", "")
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.75))
	text_vbox.add_child(desc_lbl)

	var up_id: String = up_data.get("id", "")
	var is_owned: bool = active_upgrades.get(up_id, false)
	var cost: int = int(up_data.get("cost", 100))

	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(110, 32)
	if is_owned:
		buy_btn.text = "✓ Owned"
		buy_btn.disabled = true
	else:
		buy_btn.text = "💰 Buy (%d)" % cost
		buy_btn.disabled = (current_coins < cost)
		buy_btn.pressed.connect(func():
			_play_click()
			upgrade_purchased.emit(up_id)
			hide()
			closed.emit()
		)
	hbox.add_child(buy_btn)

	return card


func _play_click() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		get_tree().root.get_node("AudioManager").play_sfx("click")
