class_name SideOrderRail
extends Control

## Handcrafted Storybook Customer Orders Board for BloomHaven.
## Pinned wooden corkboard with vintage postcard tickets, wax seals,
## antique pocket watch timers, and emerald checkmark fulfillment stamps.

signal fulfill_requested(order_id: String)
signal order_details_requested(order_id: String)

@onready var tickets_container: VBoxContainer = $Corkboard/Scroll/TicketsVBox
@onready var close_btn: Button = $Corkboard/CloseBtn

const POSTCARD_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_order_postcard_bg.png")
const WAX_SEAL_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_order_wax_seal.png")
const WATCH_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_pocket_watch_timer.png")
const SLOT_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_slot_flower_req.png")
const STAMP_CHECK_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_stamp_checkmark.png")
const RIBBON_BTN_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_btn_deliver_ribbon.png")

var _active_orders: Array[String] = []
var _ticket_cards: Dictionary = {}
var _inventory: Dictionary = {}
var _bouquet_inventory: Dictionary = {}
var _patience_data: Dictionary = {}
var _completed_requests: Dictionary = {}
var _is_refreshing: bool = false


func _ready() -> void:
	if close_btn != null:
		close_btn.pressed.connect(func():
			hide()
			_play_click_sfx()
		)
	_refresh_tickets()


func update_state(inventory: Dictionary, bouquet_inv: Dictionary, patience: Dictionary, completed: Dictionary) -> void:
	_inventory = inventory
	_bouquet_inventory = bouquet_inv
	_patience_data = patience
	_completed_requests = completed

	var has_uncompleted := false
	for o_id in FloristRequestData.get_all_request_ids():
		if not _completed_requests.get(o_id, false):
			has_uncompleted = true
			break

	var needs_refresh := false
	if has_uncompleted:
		for o_id in _active_orders:
			if _completed_requests.get(o_id, false):
				needs_refresh = true
				break

	if needs_refresh or _ticket_cards.is_empty():
		_refresh_tickets()
	else:
		_update_ticket_contents()


func _process(_delta: float) -> void:
	for o_id in _ticket_cards:
		var card: Control = _ticket_cards[o_id]
		if not is_instance_valid(card):
			continue
		var req := FloristRequestData.get_request(o_id)
		var max_pat: float = float(req.get("patience_max_seconds", 75.0))
		var cur_pat: float = float(_patience_data.get(o_id, max_pat))
		var ratio: float = clamp(cur_pat / max_pat, 0.0, 1.0)

		var bar: ProgressBar = card.get_node_or_null("BottomRow/PatienceBar")
		if bar != null:
			bar.value = ratio * 100.0
			var fill_style: StyleBoxFlat = bar.get_theme_stylebox("fill")
			if fill_style:
				if ratio > 0.5:
					fill_style.bg_color = Color(0.35, 0.75, 0.40)
				elif ratio > 0.25:
					fill_style.bg_color = Color(0.92, 0.75, 0.25)
				else:
					fill_style.bg_color = Color(0.85, 0.35, 0.25)

		var time_lbl: Label = card.get_node_or_null("BottomRow/TimeLabel")
		if time_lbl != null:
			var mins := int(cur_pat / 60.0)
			var secs := int(fmod(cur_pat, 60.0))
			time_lbl.text = "%dm %ds" % [mins, secs]


func _get_tickets_container() -> VBoxContainer:
	if not is_instance_valid(tickets_container):
		tickets_container = get_node_or_null("Corkboard/Scroll/TicketsVBox") as VBoxContainer
	return tickets_container


func _refresh_tickets() -> void:
	if _is_refreshing:
		return
	_is_refreshing = true

	var cont := _get_tickets_container()
	if cont == null:
		_is_refreshing = false
		return

	for child in cont.get_children():
		child.queue_free()
	_ticket_cards.clear()

	var all_ids := FloristRequestData.get_all_request_ids()
	_active_orders.clear()
	for o_id in all_ids:
		if not _completed_requests.get(o_id, false):
			_active_orders.append(o_id)
			if _active_orders.size() >= 2:
				break

	if _active_orders.is_empty():
		for o_id in all_ids:
			_active_orders.append(o_id)
			if _active_orders.size() >= 2:
				break

	for o_id in _active_orders:
		var card := _create_customer_ticket(o_id)
		cont.add_child(card)
		_ticket_cards[o_id] = card

	_update_ticket_contents()
	_is_refreshing = false


func _create_customer_ticket(order_id: String) -> Control:
	var req := FloristRequestData.get_request(order_id)
	var card := Control.new()
	card.name = "Ticket_" + order_id
	var pcard_w := 258.0
	var pcard_h := 164.0
	card.custom_minimum_size = Vector2(pcard_w, pcard_h)

	# 1. Postcard Parchment Background
	var p_bg := TextureRect.new()
	p_bg.name = "PostcardBg"
	p_bg.texture = POSTCARD_TEX
	p_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p_bg.size = Vector2(pcard_w, pcard_h)
	card.add_child(p_bg)

	# 2. Wax Seal (Priority stamp at top-right)
	var wax_seal := TextureRect.new()
	wax_seal.name = "WaxSeal"
	wax_seal.texture = WAX_SEAL_TEX
	wax_seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wax_seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wax_seal.size = Vector2(28, 28)
	wax_seal.position = Vector2(pcard_w - 40, 10)
	card.add_child(wax_seal)

	# 3. Portrait in Wooden Frame Slot (top left)
	var port_slot := TextureRect.new()
	port_slot.name = "PortraitSlot"
	port_slot.texture = SLOT_TEX
	port_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	port_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	port_slot.size = Vector2(38, 38)
	port_slot.position = Vector2(12, 12)
	card.add_child(port_slot)

	var p_tex := _get_customer_portrait(order_id)
	if p_tex != null:
		var port_img := TextureRect.new()
		port_img.name = "PortraitImg"
		port_img.texture = p_tex
		port_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		port_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		port_img.size = Vector2(28, 28)
		port_img.position = Vector2(5, 5)
		port_slot.add_child(port_img)

	# 4. Customer Name & Dialogue
	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = req.get("customer_name", "Customer")
	name_lbl.position = Vector2(54, 12)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.24, 0.15, 0.08, 1))
	name_lbl.add_theme_color_override("font_shadow_color", Color(1, 0.95, 0.85, 0.8))
	name_lbl.add_theme_constant_override("shadow_offset_x", 1)
	name_lbl.add_theme_constant_override("shadow_offset_y", 1)
	card.add_child(name_lbl)

	var quote_lbl := Label.new()
	quote_lbl.name = "DialogueLabel"
	quote_lbl.text = "\"%s\"" % req.get("dialogue", "Special order request")
	quote_lbl.position = Vector2(54, 28)
	quote_lbl.size = Vector2(pcard_w - 100, 32)
	quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote_lbl.add_theme_font_size_override("font_size", 8)
	quote_lbl.add_theme_color_override("font_color", Color(0.42, 0.32, 0.22, 1))
	card.add_child(quote_lbl)

	# 5. Required Items Row
	var reqs_box := HBoxContainer.new()
	reqs_box.name = "ItemsHBox"
	reqs_box.position = Vector2(14, 62)
	reqs_box.size = Vector2(120, 48)
	reqs_box.add_theme_constant_override("separation", 6)
	card.add_child(reqs_box)

	# 6. Deliver Ribbon Button
	var deliver_btn := TextureButton.new()
	deliver_btn.name = "DeliverBtn"
	deliver_btn.texture_normal = RIBBON_BTN_TEX
	deliver_btn.ignore_texture_size = true
	deliver_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	deliver_btn.size = Vector2(104, 30)
	deliver_btn.position = Vector2(pcard_w - 116, 68)
	deliver_btn.pressed.connect(func():
		fulfill_requested.emit(order_id)
		_play_click_sfx()
	)
	card.add_child(deliver_btn)

	var deliv_lbl := Label.new()
	deliv_lbl.name = "DeliverLabel"
	deliv_lbl.text = "Deliver"
	deliv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deliv_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deliv_lbl.size = Vector2(104, 30)
	deliv_lbl.add_theme_font_size_override("font_size", 10)
	deliv_lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
	deliv_lbl.add_theme_color_override("font_shadow_color", Color(0.2, 0.05, 0.05, 0.95))
	deliv_lbl.add_theme_constant_override("shadow_offset_x", 1)
	deliv_lbl.add_theme_constant_override("shadow_offset_y", 1)
	deliver_btn.add_child(deliv_lbl)

	# 7. Bottom Row: Pocket Watch Timer + Patience Gauge
	var bot_row := HBoxContainer.new()
	bot_row.name = "BottomRow"
	bot_row.position = Vector2(14, 122)
	bot_row.size = Vector2(pcard_w - 28, 24)
	bot_row.add_theme_constant_override("separation", 6)
	card.add_child(bot_row)

	var watch := TextureRect.new()
	watch.name = "PocketWatch"
	watch.texture = WATCH_TEX
	watch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	watch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	watch.custom_minimum_size = Vector2(22, 22)
	bot_row.add_child(watch)

	var time_lbl := Label.new()
	time_lbl.name = "TimeLabel"
	time_lbl.text = "1m 15s"
	time_lbl.add_theme_font_size_override("font_size", 9)
	time_lbl.add_theme_color_override("font_color", Color(0.35, 0.25, 0.15, 1))
	bot_row.add_child(time_lbl)

	var p_bar := ProgressBar.new()
	p_bar.name = "PatienceBar"
	p_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p_bar.custom_minimum_size = Vector2(0, 6)
	p_bar.show_percentage = false
	p_bar.value = 100.0

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.35, 0.75, 0.40)
	bar_fill.set_corner_radius_all(3)
	p_bar.add_theme_stylebox_override("fill", bar_fill)

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.20, 0.15, 0.10, 0.35)
	bar_bg.set_corner_radius_all(3)
	p_bar.add_theme_stylebox_override("background", bar_bg)

	bot_row.add_child(p_bar)

	return card


func _update_ticket_contents() -> void:
	for o_id in _ticket_cards:
		var card: Control = _ticket_cards[o_id]
		if not is_instance_valid(card):
			continue

		var check := FloristRequestData.check_fulfillment(o_id, _inventory, _bouquet_inventory)
		var can_fulfill: bool = check.get("can_fulfill", false)

		var items_hbox: HBoxContainer = card.get_node_or_null("ItemsHBox")
		if items_hbox != null:
			for child in items_hbox.get_children():
				child.queue_free()

			var req := FloristRequestData.get_request(o_id)
			var req_type: String = req.get("type", "flowers")
			var items: Dictionary = req.get("required_items", {})

			for item_id in items:
				var needed: int = int(items[item_id])
				var have: int = int(_inventory.get(item_id, 0)) if req_type == "flowers" else int(_bouquet_inventory.get(item_id, 0))
				var is_ready := have >= needed

				var req_frame := Control.new()
				req_frame.custom_minimum_size = Vector2(44, 44)

				var r_slot := TextureRect.new()
				r_slot.texture = SLOT_TEX
				r_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				r_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				r_slot.size = Vector2(44, 44)
				req_frame.add_child(r_slot)

				var icon := "🌸"
				match item_id:
					"rose", "rose_cream", "rose_velvet", "crimson_rose":
						icon = "🌹"
					"lavender", "english_lavender":
						icon = "🪻"
					"sunflower":
						icon = "🌻"
					"tulip", "pastel_tulip":
						icon = "🌷"
					"daisy", "sunny_daisy":
						icon = "🌼"
					_:
						if req_type == "bouquet" or item_id.begins_with("bouquet_"):
							icon = "💐"
						else:
							icon = "🌸"

				var r_icon := Label.new()
				r_icon.text = icon
				r_icon.add_theme_font_size_override("font_size", 18)
				r_icon.position = Vector2(5, 7)
				req_frame.add_child(r_icon)

				var r_count := Label.new()
				r_count.text = "%d/%d" % [have, needed]
				r_count.position = Vector2(18, 23)
				r_count.add_theme_font_size_override("font_size", 9)
				r_count.add_theme_color_override("font_color", Color(0.98, 0.95, 0.85) if is_ready else Color(0.9, 0.4, 0.3))
				r_count.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 0.95))
				r_count.add_theme_constant_override("shadow_offset_x", 1)
				r_count.add_theme_constant_override("shadow_offset_y", 1)
				req_frame.add_child(r_count)

				if is_ready:
					var check_stamp := TextureRect.new()
					check_stamp.texture = STAMP_CHECK_TEX
					check_stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					check_stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					check_stamp.size = Vector2(28, 28)
					check_stamp.position = Vector2(20, -6)
					req_frame.add_child(check_stamp)

				items_hbox.add_child(req_frame)

		var deliver_btn: TextureButton = card.get_node_or_null("DeliverBtn")
		if deliver_btn != null:
			deliver_btn.disabled = not can_fulfill
			deliver_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_fulfill else Color(0.65, 0.65, 0.65, 0.65)


func _get_customer_portrait(order_id: String) -> Texture2D:
	var path := ""
	match order_id:
		"order_1": path = "res://assets/ui/orders/portrait_emma.png"
		"order_2": path = "res://assets/ui/orders/portrait_harris.png"
		"order_3": path = "res://assets/ui/orders/portrait_nora.png"
		"order_4": path = "res://assets/ui/orders/portrait_laila.png"
		"order_5": path = "res://assets/ui/orders/portrait_sara.png"
		"order_6": path = "res://assets/ui/orders/portrait_thomas.png"
		_: path = "res://assets/ui/orders/portrait_emma.png"
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _play_click_sfx() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		var am = get_tree().root.get_node("AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.play_sfx("click")
