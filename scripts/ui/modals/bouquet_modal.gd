class_name BouquetModal
extends Control

## Standalone UI Modal for the Bouquet Workshop.

signal bouquet_crafted(bouquet_id: String)
signal closed()

const BOUQUET_RECIPES: Dictionary = {
	"garden_harmony": {
		"name": "Garden Harmony Bouquet",
		"icon": "💐",
		"requirements": {"rose": 2, "lavender": 2},
		"description": "A classic blend of fragrant crimson roses and soothing lavender."
	},
	"crimson_romance": {
		"name": "Crimson Romance",
		"icon": "🌹",
		"requirements": {"rose": 3, "tulip": 1},
		"description": "Passionate crimson blooms with radiant golden-orange tulip accents."
	},
	"ethereal_lumina": {
		"name": "Ethereal Lumina",
		"icon": "✨",
		"requirements": {"roselight": 1, "lavender": 2},
		"description": "A mystical arrangement featuring translucent glowing Roselight petals."
	},
	"solar_grandeur": {
		"name": "Solar Grandeur",
		"icon": "🌻",
		"requirements": {"sunflower": 2, "golden_rose": 1},
		"description": "Magnificent giant sunflowers anchored by an opulent Golden Rose."
	}
}

@onready var _card_container: VBoxContainer = $CenterContainer/Panel/Margin/VBox/Scroll/CardsVBox
@onready var _close_btn: Button = $CenterContainer/Panel/Margin/VBox/HeaderHBox/CloseBtn

var flower_inventory: Dictionary = {}


func _ready() -> void:
	if _close_btn != null:
		_close_btn.pressed.connect(func():
			_play_click()
			hide()
			closed.emit()
		)


func open_workshop(inventory: Dictionary) -> void:
	flower_inventory = inventory
	_populate_recipes()
	show()


func _populate_recipes() -> void:
	if _card_container == null:
		return

	for child in _card_container.get_children():
		child.queue_free()

	for b_id in BOUQUET_RECIPES:
		var card := _create_recipe_card(b_id, BOUQUET_RECIPES[b_id])
		_card_container.add_child(card)


func _create_recipe_card(b_id: String, r_data: Dictionary) -> PanelContainer:
	var reqs: Dictionary = r_data.get("requirements", {})
	var can_craft := true
	var req_strings: Array[String] = []

	for f_id in reqs:
		var have: int = flower_inventory.get(f_id, 0)
		var need: int = int(reqs[f_id])
		if have < need:
			can_craft = false
		req_strings.append("%s: %d/%d" % [f_id.capitalize(), have, need])

	var card := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = r_data.get("icon", "💐")
	icon_lbl.add_theme_font_size_override("font_size", 22)
	hbox.add_child(icon_lbl)

	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var name_lbl := Label.new()
	name_lbl.text = r_data.get("name", "Bouquet")
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70))
	text_vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = r_data.get("description", "")
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.75))
	text_vbox.add_child(desc_lbl)

	var req_lbl := Label.new()
	req_lbl.text = "Requires: " + ", ".join(req_strings)
	req_lbl.add_theme_font_size_override("font_size", 11)
	req_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6) if can_craft else Color(0.75, 0.6, 0.6))
	text_vbox.add_child(req_lbl)

	var craft_btn := Button.new()
	craft_btn.text = "Craft"
	craft_btn.disabled = not can_craft
	craft_btn.custom_minimum_size = Vector2(90, 30)
	craft_btn.pressed.connect(func():
		_play_click()
		bouquet_crafted.emit(b_id)
		hide()
		closed.emit()
	)
	hbox.add_child(craft_btn)

	return card


func _play_click() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		get_tree().root.get_node("AudioManager").play_sfx("click")
