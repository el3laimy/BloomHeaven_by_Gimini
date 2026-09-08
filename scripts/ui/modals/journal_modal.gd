class_name JournalModal
extends Control

## Standalone UI Modal for the Botanical Discovery Journal.

signal closed()

@onready var _card_container: VBoxContainer = $CenterContainer/Panel/Margin/VBox/Scroll/CardsVBox
@onready var _close_btn: Button = $CenterContainer/Panel/Margin/VBox/HeaderHBox/CloseBtn
@onready var _progress_lbl: Label = $CenterContainer/Panel/Margin/VBox/HeaderHBox/ProgressLabel

var discovered_flowers: Dictionary = {}


func _ready() -> void:
	if _close_btn != null:
		_close_btn.pressed.connect(func():
			_play_click()
			hide()
			closed.emit()
		)


func open_journal(discoveries: Dictionary) -> void:
	discovered_flowers = discoveries
	_populate_entries()
	show()


func _populate_entries() -> void:
	if _card_container == null:
		return

	for child in _card_container.get_children():
		child.queue_free()

	var all_flower_ids: Array[String] = FlowerData.get_all_flower_ids()
	var discovered_count: int = 0

	for f_id in all_flower_ids:
		var is_discovered: bool = discovered_flowers.get(f_id, false)
		if is_discovered:
			discovered_count += 1
		var f_data: Dictionary = FlowerData.get_flower(f_id)
		var card := _create_entry_card(f_id, f_data, is_discovered)
		_card_container.add_child(card)

	if _progress_lbl != null:
		_progress_lbl.text = "Discovered: %d/%d" % [discovered_count, all_flower_ids.size()]


func _create_entry_card(f_id: String, f_data: Dictionary, is_discovered: bool) -> PanelContainer:
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
	icon_lbl.text = f_data.get("icon", "🌸") if is_discovered else "❓"
	icon_lbl.add_theme_font_size_override("font_size", 22)
	hbox.add_child(icon_lbl)

	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var name_lbl := Label.new()
	name_lbl.text = f_data.get("display_name", f_id) if is_discovered else "Undiscovered Botanical"
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70) if is_discovered else Color(0.6, 0.6, 0.6))
	text_vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = f_data.get("description", "") if is_discovered else "Cross-pollinate parent varieties in the Breeding Lab to unlock."
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.75) if is_discovered else Color(0.5, 0.5, 0.5))
	text_vbox.add_child(desc_lbl)

	var tier_lbl := Label.new()
	var tier_name: String = f_data.get("rarity", "Common").capitalize()
	tier_lbl.text = tier_name if is_discovered else "Locked"
	tier_lbl.add_theme_font_size_override("font_size", 11)
	tier_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.35) if is_discovered else Color(0.4, 0.4, 0.4))
	hbox.add_child(tier_lbl)

	return card


func _play_click() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		get_tree().root.get_node("AudioManager").play_sfx("click")
