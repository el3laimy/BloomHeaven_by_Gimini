class_name InventoryDrawer
extends Control

## Cozy Satchel Inventory Drawer.
## Displays Lily's harvested flowers, crafted bouquets, and seeds
## in a compact wooden shelf when clicking the backpack button.

@onready var panel: PanelContainer = $Panel
@onready var grid: GridContainer = $Panel/Margin/VBox/Grid
@onready var close_btn: Button = $Panel/Margin/VBox/HeaderHBox/CloseBtn


func _ready() -> void:
	hide()
	if close_btn:
		close_btn.pressed.connect(func():
			hide()
			_play_click()
		)


func toggle() -> void:
	if visible:
		hide()
	else:
		show()
		_play_click()


func update_inventory(inventory: Dictionary, bouquet_inventory: Dictionary) -> void:
	if grid == null:
		return

	for child in grid.get_children():
		child.queue_free()

	# Display regular flowers
	var all_flowers := ["rose", "tulip", "daisy", "lavender", "sunflower", "roselight", "golden_rose", "sunflare_spike"]
	for f_id in all_flowers:
		var count: int = int(inventory.get(f_id, 0))
		var f_data := FlowerData.get_flower(f_id)
		var item_card := _create_item_pill(f_data.get("display_name", f_id.capitalize()), count, _get_flower_icon(f_id))
		grid.add_child(item_card)

	# Display bouquets
	for b_id in bouquet_inventory:
		var b_count: int = int(bouquet_inventory[b_id])
		if b_count > 0:
			var b_data := BouquetData.get_bouquet(b_id)
			var b_card := _create_item_pill(b_data.get("display_name", b_id), b_count, "💐")
			grid.add_child(b_card)


func _create_item_pill(name_str: String, count: int, icon: String) -> PanelContainer:
	var panel_item := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.10, 0.06, 0.90)
	style.set_border_width_all(1)
	style.border_color = Color(0.45, 0.35, 0.20, 0.8)
	style.set_corner_radius_all(6)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel_item.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	panel_item.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 12)
	hbox.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = name_str + ":"
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.72))
	hbox.add_child(name_lbl)

	var count_lbl := Label.new()
	count_lbl.text = str(count)
	count_lbl.add_theme_font_size_override("font_size", 11)
	count_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35) if count > 0 else Color(0.5, 0.5, 0.5))
	hbox.add_child(count_lbl)

	return panel_item


func _get_flower_icon(f_id: String) -> String:
	match f_id:
		"rose": return "🌹"
		"tulip": return "🌷"
		"daisy": return "🌼"
		"lavender": return "🪻"
		"sunflower": return "🌻"
		"roselight": return "✨"
		"golden_rose": return "👑"
		"sunflare_spike": return "☀️"
		_: return "🌸"


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide()


func _play_click() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		var am = get_tree().root.get_node("AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.play_sfx("click")
