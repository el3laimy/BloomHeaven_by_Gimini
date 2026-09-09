class_name InventoryDrawer
extends Control

## Cozy Satchel & Flower Stand (Quick Sell) Drawer.
## Displays Lily's harvested flowers, crafted bouquets, and seeds
## with instant one-click Quick Sell capabilities.

signal quick_sell_requested(flower_id: String, count: int)
signal sell_all_requested()

@onready var panel: PanelContainer = $Panel
@onready var grid: GridContainer = $Panel/Margin/VBox/Grid
@onready var close_btn: Button = $Panel/Margin/VBox/HeaderHBox/CloseBtn
@onready var title_lbl: Label = $Panel/Margin/VBox/HeaderHBox/Title
@onready var vbox: VBoxContainer = $Panel/Margin/VBox

var _footer_container: VBoxContainer = null


func _ready() -> void:
	hide()
	if close_btn:
		close_btn.pressed.connect(func():
			hide()
			_play_click()
		)
	if title_lbl:
		title_lbl.text = "🌸 Flower Stand & Satchel"


func toggle() -> void:
	if visible:
		hide()
	else:
		show()
		_play_click()


func update_inventory(inventory: Dictionary, bouquet_inventory: Dictionary) -> void:
	if grid == null or vbox == null:
		return

	for child in grid.get_children():
		child.queue_free()

	if _footer_container != null:
		_footer_container.queue_free()
		_footer_container = null

	var total_flowers_to_sell: int = 0
	var total_coin_value: int = 0

	# 1. Flora catalog: Core 4 CVP Base + 6 Curated Hybrids + Legacy
	var catalog := [
		"rose", "daisy", "lavender", "tulip",
		"blushbell", "velvet_dusk", "twilight_bell", "sunburst_daisy", "crown_petal", "meadow_mist",
		"sunflower", "roselight", "golden_rose", "sunflare_spike"
	]

	for f_id in catalog:
		var count: int = int(inventory.get(f_id, 0))
		var f_data := FlowerData.get_flower(f_id)
		var base_val: int = int(f_data.get("base_value", 10))

		if count > 0:
			total_flowers_to_sell += count
			total_coin_value += (count * base_val)

		# Display if in inventory or if one of the 4 core starters
		if count > 0 or f_id in ["rose", "daisy", "lavender", "tulip"]:
			var pill := _create_flower_card(f_id, f_data.get("display_name", f_id.capitalize()), count, _get_flower_icon(f_id), base_val)
			grid.add_child(pill)

	# 2. Display Bouquets
	for b_id in bouquet_inventory:
		var b_count: int = int(bouquet_inventory[b_id])
		if b_count > 0:
			var b_data := BouquetData.get_bouquet(b_id)
			var b_card := _create_bouquet_card(b_data.get("display_name", b_id), b_count)
			grid.add_child(b_card)

	# 3. Quick Sell Footer
	_create_footer(total_flowers_to_sell, total_coin_value)


func _create_flower_card(flower_id: String, name_str: String, count: int, icon: String, base_val: int) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.12, 0.08, 0.94) if count > 0 else Color(0.12, 0.09, 0.06, 0.70)
	style.set_border_width_all(1)
	style.border_color = Color(0.65, 0.52, 0.28, 0.9) if count > 0 else Color(0.35, 0.28, 0.18, 0.4)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	card.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	card.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = name_str
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.80) if count > 0 else Color(0.55, 0.50, 0.45))
	hbox.add_child(name_lbl)

	var count_lbl := Label.new()
	count_lbl.text = "x%d" % count
	count_lbl.add_theme_font_size_override("font_size", 11)
	count_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35) if count > 0 else Color(0.40, 0.40, 0.40))
	hbox.add_child(count_lbl)

	if count > 0:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(spacer)

		var price_lbl := Label.new()
		price_lbl.text = "%d🪙" % base_val
		price_lbl.add_theme_font_size_override("font_size", 10)
		price_lbl.add_theme_color_override("font_color", Color(0.98, 0.85, 0.35))
		hbox.add_child(price_lbl)

		var sell_btn := Button.new()
		sell_btn.text = "Sell 1"
		sell_btn.custom_minimum_size = Vector2(44, 22)
		sell_btn.add_theme_font_size_override("font_size", 10)
		sell_btn.tooltip_text = "Sell 1 %s for +%d coins" % [name_str, base_val]
		sell_btn.pressed.connect(func():
			_play_click()
			quick_sell_requested.emit(flower_id, 1)
		)
		hbox.add_child(sell_btn)

		if count > 1:
			var sell_all_btn := Button.new()
			sell_all_btn.text = "All"
			sell_all_btn.custom_minimum_size = Vector2(32, 22)
			sell_all_btn.add_theme_font_size_override("font_size", 10)
			sell_all_btn.tooltip_text = "Sell all %d %s for +%d coins" % [count, name_str, count * base_val]
			sell_all_btn.pressed.connect(func():
				_play_click()
				quick_sell_requested.emit(flower_id, count)
			)
			hbox.add_child(sell_all_btn)

	return card


func _create_bouquet_card(name_str: String, count: int) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.10, 0.15, 0.90)
	style.set_border_width_all(1)
	style.border_color = Color(0.70, 0.40, 0.60, 0.8)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	card.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = "💐"
	icon_lbl.add_theme_font_size_override("font_size", 13)
	hbox.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = name_str
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.98, 0.85, 0.95))
	hbox.add_child(name_lbl)

	var count_lbl := Label.new()
	count_lbl.text = "x%d" % count
	count_lbl.add_theme_font_size_override("font_size", 11)
	count_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40))
	hbox.add_child(count_lbl)

	return card


func _create_footer(total_flowers: int, total_val: int) -> void:
	_footer_container = VBoxContainer.new()
	_footer_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_footer_container)

	var sep := HSeparator.new()
	_footer_container.add_child(sep)

	if total_flowers > 0:
		var sell_all_btn := Button.new()
		sell_all_btn.text = "💰 Quick Sell All Harvested (%d Flowers ➔ +%d Coins)" % [total_flowers, total_val]
		sell_all_btn.custom_minimum_size = Vector2(0, 30)
		sell_all_btn.add_theme_font_size_override("font_size", 11)
		sell_all_btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
		sell_all_btn.pressed.connect(func():
			_play_click()
			sell_all_requested.emit()
		)
		_footer_container.add_child(sell_all_btn)
	else:
		var empty_lbl := Label.new()
		empty_lbl.text = "🌱 Harvest flowers in the garden to sell them here!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 10)
		empty_lbl.add_theme_color_override("font_color", Color(0.70, 0.65, 0.55))
		_footer_container.add_child(empty_lbl)


func _get_flower_icon(f_id: String) -> String:
	match f_id:
		"rose", "crimson_rose": return "🌹"
		"daisy", "sunny_daisy": return "🌼"
		"lavender", "english_lavender": return "💜"
		"tulip", "pastel_tulip": return "🌷"
		"blushbell": return "🌸"
		"velvet_dusk": return "🪻"
		"twilight_bell": return "🔔"
		"sunburst_daisy": return "🌻"
		"crown_petal": return "👑"
		"meadow_mist": return "🌫️"
		"sunflower": return "☀️"
		"roselight": return "✨"
		"golden_rose": return "🏆"
		"sunflare_spike": return "🔥"
		_: return "🌸"


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide()


func _play_click() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		var am = get_tree().root.get_node("AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.play_sfx("click")

