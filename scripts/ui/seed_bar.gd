class_name SeedBar
extends Control

## Rustic 2-Tier Wooden Seed Box Cabinet for BloomHaven.
## Emits seed_changed(seed_id) when the user selects a botanical seed packet.

signal seed_changed(seed_id: String)

@onready var cabinet_frame: NinePatchRect = $CabinetFrame
@onready var cards_container: HBoxContainer = $CabinetFrame/Margin/Scroll/CardsHBox
@onready var title_label: Label = $CabinetFrame/HeaderLabel

var current_seed: String = "rose"
var seed_cards: Dictionary = {}
var _seed_inventory: Dictionary = {}


func _ready() -> void:
	refresh_seeds(["rose", "lavender", "sunflower", "mystery_seed", "tulip", "daisy"])


func toggle() -> void:
	visible = not visible
	if visible:
		_play_click()


func update_counts(inventory: Dictionary, mystery_count: int = 0) -> void:
	_seed_inventory = inventory
	for s_id in seed_cards:
		var card: Control = seed_cards[s_id]
		if not is_instance_valid(card):
			continue
		var count_lbl: Label = card.get_node_or_null("CountMargin/CountPill/CountLabel")
		if count_lbl != null:
			if s_id == "mystery_seed":
				count_lbl.text = "★ %d" % mystery_count
			else:
				var count: int = inventory.get(s_id, 10) # default starter stock
				count_lbl.text = "🍃 %d" % count


func refresh_seeds(available_seeds: Array[String]) -> void:
	if cards_container == null:
		return

	for child in cards_container.get_children():
		child.queue_free()
	seed_cards.clear()

	for seed_id in available_seeds:
		var card := _create_seed_packet_card(seed_id)
		cards_container.add_child(card)
		seed_cards[seed_id] = card

	# Add Locked Tier slot
	var locked_slot := _create_locked_slot()
	cards_container.add_child(locked_slot)

	_update_seed_selection_visual()


func _create_seed_packet_card(seed_id: String) -> Control:
	var root_card := Control.new()
	root_card.name = "SeedCard_" + seed_id
	root_card.custom_minimum_size = Vector2(64, 86)

	var bg_btn := TextureButton.new()
	bg_btn.name = "CardBtn"
	bg_btn.anchors_preset = Control.PRESET_FULL_RECT
	bg_btn.anchor_right = 1.0
	bg_btn.anchor_bottom = 1.0
	bg_btn.ignore_texture_size = true
	bg_btn.stretch_mode = TextureButton.STRETCH_SCALE

	var tex_path := ""
	match seed_id:
		"rose": tex_path = "res://assets/ui/seeds/seed_packet_rose.png"
		"lavender": tex_path = "res://assets/ui/seeds/seed_packet_lavender.png"
		"sunflower": tex_path = "res://assets/ui/seeds/seed_packet_sunflower.png"
		_: tex_path = "res://assets/ui/seeds/seed_card_blank.png"

	if ResourceLoader.exists(tex_path):
		bg_btn.texture_normal = load(tex_path)

	bg_btn.pressed.connect(func(): select_seed(seed_id))
	root_card.add_child(bg_btn)

	# Active Glow Border
	var active_border := ReferenceRect.new()
	active_border.name = "ActiveBorder"
	active_border.anchors_preset = Control.PRESET_FULL_RECT
	active_border.anchor_right = 1.0
	active_border.anchor_bottom = 1.0
	active_border.border_color = Color(1.0, 0.85, 0.3, 1.0)
	active_border.border_width = 2.5
	active_border.editor_only = false
	active_border.visible = (seed_id == current_seed)
	root_card.add_child(active_border)

	# Count Pill at bottom
	var count_margin := MarginContainer.new()
	count_margin.name = "CountMargin"
	count_margin.anchors_preset = Control.PRESET_BOTTOM_WIDE
	count_margin.anchor_top = 1.0
	count_margin.anchor_right = 1.0
	count_margin.anchor_bottom = 1.0
	count_margin.offset_top = -22.0
	count_margin.offset_left = 6.0
	count_margin.offset_right = -6.0
	count_margin.offset_bottom = -4.0
	count_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pill_panel := PanelContainer.new()
	pill_panel.name = "CountPill"
	pill_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.12, 0.22, 0.14, 0.88)
	p_style.set_corner_radius_all(6)
	pill_panel.add_theme_stylebox_override("panel", p_style)

	var count_lbl := Label.new()
	count_lbl.name = "CountLabel"
	count_lbl.text = "🍃 %d" % _seed_inventory.get(seed_id, 12)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 10)
	count_lbl.add_theme_color_override("font_color", Color(0.9, 0.98, 0.85))
	pill_panel.add_child(count_lbl)
	count_margin.add_child(pill_panel)
	root_card.add_child(count_margin)

	return root_card


func _create_locked_slot() -> Control:
	var root_slot := Control.new()
	root_slot.name = "LockedSlot"
	root_slot.custom_minimum_size = Vector2(58, 86)

	var locked_tex := TextureRect.new()
	locked_tex.anchors_preset = Control.PRESET_FULL_RECT
	locked_tex.anchor_right = 1.0
	locked_tex.anchor_bottom = 1.0
	locked_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	locked_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex_p := "res://assets/ui/seeds/slot_locked.png"
	if ResourceLoader.exists(tex_p):
		locked_tex.texture = load(tex_p)
	root_slot.add_child(locked_tex)
	return root_slot


func select_seed(seed_id: String) -> void:
	current_seed = seed_id
	_update_seed_selection_visual()
	seed_changed.emit(current_seed)
	_play_click()


func _update_seed_selection_visual() -> void:
	for s_id in seed_cards:
		var card: Control = seed_cards[s_id]
		if not is_instance_valid(card):
			continue
		var active_border := card.get_node_or_null("ActiveBorder")
		if active_border != null:
			active_border.visible = (s_id == current_seed)
		var btn: TextureButton = card.get_node_or_null("CardBtn")
		if btn != null:
			if s_id == current_seed:
				btn.modulate = Color(1.15, 1.15, 1.0)
			else:
				btn.modulate = Color(0.88, 0.88, 0.88)


func _play_click() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		var am = get_tree().root.get_node("AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.play_sfx("click")
