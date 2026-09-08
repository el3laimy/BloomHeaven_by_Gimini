class_name SideOrderRail
extends Control

## Pinned Parchment Customer Orders Board for BloomHaven.
## Displays customer portraits, story dialogue, required item counters,
## antique pocket watch patience gauges, and gift delivery buttons.

signal fulfill_requested(order_id: String)
signal order_details_requested(order_id: String)

@onready var tickets_container: VBoxContainer = $ParchmentBoard/Margin/Scroll/TicketsVBox
@onready var close_btn: Button = $ParchmentBoard/CloseBtn

var _active_orders: Array[String] = []
var _ticket_cards: Dictionary = {}
var _inventory: Dictionary = {}
var _bouquet_inventory: Dictionary = {}
var _patience_data: Dictionary = {}
var _completed_requests: Dictionary = {}
var _is_refreshing: bool = false


func _ready() -> void:
	if close_btn != null:
		close_btn.pressed.connect(func(): hide())
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
		var card: PanelContainer = _ticket_cards[o_id]
		if not is_instance_valid(card):
			continue
		var req := FloristRequestData.get_request(o_id)
		var max_pat: float = float(req.get("patience_max_seconds", 75.0))
		var cur_pat: float = float(_patience_data.get(o_id, max_pat))
		var ratio: float = clamp(cur_pat / max_pat, 0.0, 1.0)

		var bar: ProgressBar = card.get_node_or_null("Margin/VBox/BottomRow/PatienceHBox/PatienceBar")
		if bar != null:
			bar.value = ratio * 100.0
			if ratio > 0.5:
				bar.modulate = Color(0.35, 0.85, 0.45)
			elif ratio > 0.25:
				bar.modulate = Color(1.0, 0.85, 0.3)
			else:
				bar.modulate = Color(1.0, 0.4, 0.3)

		var time_lbl: Label = card.get_node_or_null("Margin/VBox/BottomRow/PatienceHBox/TimeLabel")
		if time_lbl != null:
			var mins := int(cur_pat / 60.0)
			var secs := int(fmod(cur_pat, 60.0))
			time_lbl.text = "%dm %ds" % [mins, secs]


func _get_tickets_container() -> VBoxContainer:
	if not is_instance_valid(tickets_container):
		tickets_container = get_node_or_null("ParchmentBoard/Margin/Scroll/TicketsVBox") as VBoxContainer
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


func _create_customer_ticket(order_id: String) -> PanelContainer:
	var req := FloristRequestData.get_request(order_id)
	var card := PanelContainer.new()
	card.name = "Ticket_" + order_id
	card.custom_minimum_size = Vector2(245, 125)

	# Warm Parchment Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.94, 0.85, 0.95)
	style.set_border_width_all(1)
	style.border_color = Color(0.72, 0.58, 0.42, 0.85)
	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Row 1: Portrait + Name & Dialogue
	var top_hbox := HBoxContainer.new()
	top_hbox.name = "TopRow"
	top_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(top_hbox)

	var portrait_tex := TextureRect.new()
	portrait_tex.name = "Portrait"
	portrait_tex.custom_minimum_size = Vector2(44, 56)
	portrait_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_tex.texture = _get_customer_portrait(order_id)
	top_hbox.add_child(portrait_tex)

	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 2)
	top_hbox.add_child(text_vbox)

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = req.get("customer_name", "Customer")
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(0.25, 0.16, 0.1, 1))
	text_vbox.add_child(name_lbl)

	var dialogue_lbl := Label.new()
	dialogue_lbl.name = "DialogueLabel"
	dialogue_lbl.text = "\"%s\"" % req.get("dialogue", "Special order request")
	dialogue_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_lbl.add_theme_font_size_override("font_size", 9)
	dialogue_lbl.add_theme_color_override("font_color", Color(0.45, 0.35, 0.25, 1))
	text_vbox.add_child(dialogue_lbl)

	# Row 2: Items Needed
	var items_hbox := HBoxContainer.new()
	items_hbox.name = "ItemsHBox"
	items_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(items_hbox)

	# Row 3: Pocket Watch + Patience Bar + Deliver Gift Button
	var bot_hbox := HBoxContainer.new()
	bot_hbox.name = "BottomRow"
	bot_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(bot_hbox)

	var watch_tex := TextureRect.new()
	watch_tex.custom_minimum_size = Vector2(16, 16)
	watch_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	watch_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	watch_tex.texture = preload("res://assets/ui/orders/pocket_watch.png")
	bot_hbox.add_child(watch_tex)

	var pat_hbox := HBoxContainer.new()
	pat_hbox.name = "PatienceHBox"
	pat_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pat_hbox.add_theme_constant_override("separation", 4)
	bot_hbox.add_child(pat_hbox)

	var time_lbl := Label.new()
	time_lbl.name = "TimeLabel"
	time_lbl.text = "45m"
	time_lbl.add_theme_font_size_override("font_size", 9)
	time_lbl.add_theme_color_override("font_color", Color(0.4, 0.3, 0.2, 1))
	pat_hbox.add_child(time_lbl)

	var p_bar := ProgressBar.new()
	p_bar.name = "PatienceBar"
	p_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p_bar.custom_minimum_size = Vector2(0, 7)
	p_bar.show_percentage = false
	p_bar.value = 100.0
	pat_hbox.add_child(p_bar)

	var deliver_btn := TextureButton.new()
	deliver_btn.name = "DeliverBtn"
	deliver_btn.custom_minimum_size = Vector2(26, 26)
	deliver_btn.texture_normal = preload("res://assets/ui/orders/gift_deliver_btn.png")
	deliver_btn.ignore_texture_size = true
	deliver_btn.stretch_mode = TextureButton.STRETCH_SCALE
	deliver_btn.pressed.connect(func():
		fulfill_requested.emit(order_id)
		_play_click_sfx()
	)
	bot_hbox.add_child(deliver_btn)

	return card


func _update_ticket_contents() -> void:
	for o_id in _ticket_cards:
		var card: PanelContainer = _ticket_cards[o_id]
		if not is_instance_valid(card):
			continue

		var check := FloristRequestData.check_fulfillment(o_id, _inventory, _bouquet_inventory)
		var can_fulfill: bool = check.get("can_fulfill", false)

		var items_hbox: HBoxContainer = card.get_node_or_null("Margin/VBox/ItemsHBox")
		if items_hbox != null:
			for child in items_hbox.get_children():
				child.queue_free()

			var req := FloristRequestData.get_request(o_id)
			var req_type: String = req.get("type", "flowers")
			var items: Dictionary = req.get("required_items", {})

			for item_id in items:
				var needed: int = int(items[item_id])
				var have: int = int(_inventory.get(item_id, 0)) if req_type == "flowers" else int(_bouquet_inventory.get(item_id, 0))
				var pill := Label.new()
				var icon := "🌸"
				match item_id:
					"rose", "rose_cream", "rose_velvet":
						icon = "🌹"
					"lavender":
						icon = "🪻"
					"sunflower":
						icon = "🌻"
					"tulip":
						icon = "🌷"
					"daisy":
						icon = "🌼"
					_:
						if req_type == "bouquet" or item_id.begins_with("bouquet_"):
							icon = "💐"
						else:
							icon = "🌸"
				pill.text = "%s %d/%d" % [icon, have, needed]
				pill.add_theme_font_size_override("font_size", 10)
				pill.add_theme_color_override("font_color", Color(0.15, 0.55, 0.25) if have >= needed else Color(0.7, 0.3, 0.2))
				items_hbox.add_child(pill)

		var deliver_btn: TextureButton = card.get_node_or_null("Margin/VBox/BottomRow/DeliverBtn")
		if deliver_btn != null:
			deliver_btn.disabled = not can_fulfill
			deliver_btn.modulate = Color(1.2, 1.2, 1.0) if can_fulfill else Color(0.6, 0.6, 0.6, 0.6)


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
