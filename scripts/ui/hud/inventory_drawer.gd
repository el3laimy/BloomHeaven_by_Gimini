class_name InventoryDrawer
extends Control

## Handcrafted Storybook Flower Stand (Quick Sell) UI
## High-aesthetic market stall with wooden crates, chalkboard price tags,
## and instant commercial selling capabilities.

signal quick_sell_requested(flower_id: String, count: int)
signal sell_all_requested()

@onready var backdrop: ColorRect = $Backdrop
@onready var stand_container: Control = $StandContainer
@onready var crate_scroll: ScrollContainer = $StandContainer/CrateScroll
@onready var crate_grid: GridContainer = $StandContainer/CrateScroll/CrateGrid
@onready var close_btn: Button = $StandContainer/Awning/CloseBtn
@onready var sign_title: Label = $StandContainer/Awning/SignTitle
@onready var sell_all_btn: TextureButton = $StandContainer/FooterArea/SellAllHarvestBtn
@onready var sell_all_label: Label = $StandContainer/FooterArea/SellAllHarvestBtn/SellAllHarvestLabel
@onready var empty_label: Label = $StandContainer/FooterArea/EmptyLabel
@onready var coin_drawer_icon: TextureRect = $StandContainer/FooterArea/CoinDrawerIcon

const CRATE_TEX: Texture2D = preload("res://assets/ui/flower_stand/ui_wooden_crate_slot.png")
const TAG_TEX: Texture2D = preload("res://assets/ui/flower_stand/ui_chalk_price_tag.png")
const BTN_WOOD_NORM: Texture2D = preload("res://assets/ui/flower_stand/ui_btn_sell_wood_normal.png")
const BTN_WOOD_PRESS: Texture2D = preload("res://assets/ui/flower_stand/ui_btn_sell_wood_pressed.png")
const BTN_BRASS_TEX: Texture2D = preload("res://assets/ui/flower_stand/ui_btn_sell_all_brass.png")


func _ready() -> void:
	hide()
	if close_btn:
		close_btn.pressed.connect(func():
			hide()
			_play_click()
		)
	if sell_all_btn:
		sell_all_btn.pressed.connect(func():
			_play_click()
			sell_all_requested.emit()
		)
	if backdrop:
		backdrop.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed:
				hide()
				_play_click()
		)

	visibility_changed.connect(func():
		if visible:
			move_to_front()
	)

	# Style ScrollContainer VScrollBar for warm wooden aesthetic
	if crate_scroll:
		var v_bar := crate_scroll.get_v_scroll_bar()
		if v_bar:
			var grabber_style := StyleBoxFlat.new()
			grabber_style.bg_color = Color(0.65, 0.50, 0.28, 0.85)
			grabber_style.set_corner_radius_all(4)
			var track_style := StyleBoxFlat.new()
			track_style.bg_color = Color(0.15, 0.10, 0.06, 0.4)
			track_style.set_corner_radius_all(4)
			v_bar.add_theme_stylebox_override("grabber", grabber_style)
			v_bar.add_theme_stylebox_override("scroll", track_style)
			v_bar.custom_minimum_size = Vector2(8, 0)


func toggle() -> void:
	if visible:
		hide()
	else:
		show()
		move_to_front()
		_play_click()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		_play_click()
		get_viewport().set_input_as_handled()


func update_inventory(inventory: Dictionary, bouquet_inventory: Dictionary) -> void:
	if crate_grid == null:
		return

	for child in crate_grid.get_children():
		child.queue_free()

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
			var crate := _create_flower_crate(f_id, f_data.get("display_name", f_id.capitalize()), count, _get_flower_icon(f_id), base_val)
			crate_grid.add_child(crate)

	# 2. Display Bouquets
	for b_id in bouquet_inventory:
		var b_count: int = int(bouquet_inventory[b_id])
		if b_count > 0:
			var b_data := BouquetData.get_bouquet(b_id)
			var b_crate := _create_bouquet_crate(b_data.get("display_name", b_id), b_count)
			crate_grid.add_child(b_crate)

	# 3. Update Footer
	if total_flowers_to_sell > 0:
		if sell_all_btn:
			sell_all_btn.visible = true
		if empty_label:
			empty_label.visible = false
		if sell_all_label:
			sell_all_label.text = "💰 Quick Sell All Harvested  •  %d Blooms ➔ +%d Coins" % [total_flowers_to_sell, total_coin_value]
	else:
		if sell_all_btn:
			sell_all_btn.visible = false
		if empty_label:
			empty_label.visible = true


func _create_flower_crate(flower_id: String, name_str: String, count: int, icon: String, base_val: int) -> Control:
	var crate := Control.new()
	crate.custom_minimum_size = Vector2(276, 122)

	# 1. Crate Graphic
	var c_bg := TextureRect.new()
	c_bg.texture = CRATE_TEX
	c_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	c_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	c_bg.size = Vector2(276, 122)
	if count == 0:
		c_bg.modulate = Color(0.55, 0.55, 0.55, 0.70)
	crate.add_child(c_bg)

	# 2. Flower Icon (nestled on straw bed)
	var f_lbl := Label.new()
	f_lbl.text = icon
	f_lbl.add_theme_font_size_override("font_size", 26)
	f_lbl.position = Vector2(24, 38)
	crate.add_child(f_lbl)

	# 3. Flower Name with dark outline
	var name_lbl := Label.new()
	name_lbl.text = name_str
	name_lbl.position = Vector2(68, 30)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88) if count > 0 else Color(0.65, 0.60, 0.55))
	name_lbl.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 1.0))
	name_lbl.add_theme_constant_override("shadow_offset_x", 1)
	name_lbl.add_theme_constant_override("shadow_offset_y", 1)
	name_lbl.add_theme_color_override("font_outline_color", Color(0.15, 0.10, 0.05, 0.9))
	name_lbl.add_theme_constant_override("outline_size", 2)
	crate.add_child(name_lbl)

	# 4. Count Badge
	var count_lbl := Label.new()
	count_lbl.text = "In Stock: %d" % count if count > 0 else "Out of Stock"
	count_lbl.position = Vector2(68, 48)
	count_lbl.add_theme_font_size_override("font_size", 10)
	count_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40) if count > 0 else Color(0.55, 0.50, 0.45))
	count_lbl.add_theme_color_override("font_shadow_color", Color(0.10, 0.06, 0.02, 0.9))
	count_lbl.add_theme_constant_override("shadow_offset_x", 1)
	count_lbl.add_theme_constant_override("shadow_offset_y", 1)
	crate.add_child(count_lbl)

	# 5. Chalk Price Tag
	var tag := TextureRect.new()
	tag.texture = TAG_TEX
	tag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tag.size = Vector2(68, 32)
	tag.position = Vector2(192, 24)
	crate.add_child(tag)

	var price_val := Label.new()
	price_val.text = "%d🪙" % base_val
	price_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_val.size = Vector2(68, 32)
	price_val.add_theme_font_size_override("font_size", 11)
	price_val.add_theme_color_override("font_color", Color(1.0, 0.96, 0.70))
	price_val.add_theme_color_override("font_shadow_color", Color(0.08, 0.05, 0.02, 0.95))
	price_val.add_theme_constant_override("shadow_offset_x", 1)
	price_val.add_theme_constant_override("shadow_offset_y", 1)
	tag.add_child(price_val)

	# 6. Action Buttons
	if count > 0:
		# Sell 1 Button
		var s1_btn := TextureButton.new()
		s1_btn.texture_normal = BTN_WOOD_NORM
		s1_btn.texture_pressed = BTN_WOOD_PRESS
		s1_btn.ignore_texture_size = true
		s1_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		s1_btn.size = Vector2(68, 30)
		s1_btn.position = Vector2(128, 74)
		s1_btn.pressed.connect(func():
			_play_click()
			quick_sell_requested.emit(flower_id, 1)
		)
		crate.add_child(s1_btn)

		var s1_lbl := Label.new()
		s1_lbl.text = "Sell 1"
		s1_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s1_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		s1_lbl.size = Vector2(68, 30)
		s1_lbl.add_theme_font_size_override("font_size", 10)
		s1_lbl.add_theme_color_override("font_color", Color(0.98, 0.94, 0.85))
		s1_lbl.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 1.0))
		s1_lbl.add_theme_constant_override("shadow_offset_x", 1)
		s1_lbl.add_theme_constant_override("shadow_offset_y", 1)
		s1_btn.add_child(s1_lbl)

		if count > 1:
			# Sell All Button
			var sa_btn := TextureButton.new()
			sa_btn.texture_normal = BTN_BRASS_TEX
			sa_btn.ignore_texture_size = true
			sa_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			sa_btn.size = Vector2(62, 30)
			sa_btn.position = Vector2(200, 74)
			sa_btn.pressed.connect(func():
				_play_click()
				quick_sell_requested.emit(flower_id, count)
			)
			crate.add_child(sa_btn)

			var sa_lbl := Label.new()
			sa_lbl.text = "All"
			sa_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sa_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sa_lbl.size = Vector2(62, 30)
			sa_lbl.add_theme_font_size_override("font_size", 10)
			sa_lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.55))
			sa_lbl.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 1.0))
			sa_lbl.add_theme_constant_override("shadow_offset_x", 1)
			sa_lbl.add_theme_constant_override("shadow_offset_y", 1)
			sa_btn.add_child(sa_lbl)

	return crate


func _create_bouquet_crate(name_str: String, count: int) -> Control:
	var crate := Control.new()
	crate.custom_minimum_size = Vector2(276, 122)

	var c_bg := TextureRect.new()
	c_bg.texture = CRATE_TEX
	c_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	c_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	c_bg.size = Vector2(276, 122)
	c_bg.modulate = Color(1.0, 0.90, 0.95, 0.95)
	crate.add_child(c_bg)

	var f_lbl := Label.new()
	f_lbl.text = "💐"
	f_lbl.add_theme_font_size_override("font_size", 24)
	f_lbl.position = Vector2(24, 38)
	crate.add_child(f_lbl)

	var name_lbl := Label.new()
	name_lbl.text = name_str
	name_lbl.position = Vector2(68, 32)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(0.98, 0.90, 0.95))
	name_lbl.add_theme_color_override("font_shadow_color", Color(0.15, 0.05, 0.12, 1.0))
	name_lbl.add_theme_constant_override("shadow_offset_x", 1)
	name_lbl.add_theme_constant_override("shadow_offset_y", 1)
	crate.add_child(name_lbl)

	var count_lbl := Label.new()
	count_lbl.text = "Bouquets: %d" % count
	count_lbl.position = Vector2(68, 50)
	count_lbl.add_theme_font_size_override("font_size", 10)
	count_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.92))
	count_lbl.add_theme_color_override("font_shadow_color", Color(0.12, 0.04, 0.08, 0.9))
	crate.add_child(count_lbl)

	return crate


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


func _play_click() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		var am = get_tree().root.get_node("AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.play_sfx("click")
