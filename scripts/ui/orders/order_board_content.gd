class_name OrderBoardContent
extends Control

## BloomHaven - Customer Orders Board (Reconstructed to match media_1789073940834.jpg)
## Displays 3 simultaneous stacked cards + compact header + bottom carousel tray.

signal fulfill_requested(order_id: String)
signal order_selected(order_id: String)
signal closed()

# --- Preloaded Textures ---
const SHELL_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_orders_board_shell.png")
const CARD_BG_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_order_card_bg_large.png")
const PROG_BG_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_orders_header_progress_bar_bg.png")
const PROG_FILL_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_orders_header_progress_fill.png")
const SATCHEL_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_orders_header_satchel.png")

const HEART_FULL_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_heart_filled.png")
const HEART_EMPTY_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_heart_empty.png")
const SLOT_CARD_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_order_slot_card.png")
const SLOT_EMPTY_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_order_slot_empty_dashed.png")
const PIN_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_golden_pin_clean.png")

const BTN_GREEN_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_order_action_btn_green.png")
const BTN_NEUTRAL_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_order_action_btn_neutral.png")
const COINS_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_reward_coin_stack_small.png")
const STAMP_CHECK_TEX: Texture2D = preload("res://assets/ui/customer_orders/ui_status_check_stamp_green.png")
const WatchTimerDialScript := preload("res://scripts/ui/orders/watch_timer_dial.gd")

# Flower Icon Mapping
const FLOWER_ICON_MAP := {
	"rose": "res://assets/ui/customer_orders/flowers/flower_icon_rosebud_red.png",
	"crimson_rose": "res://assets/ui/customer_orders/flowers/flower_icon_rosebud_red.png",
	"lavender": "res://assets/ui/customer_orders/flowers/flower_icon_hybrid_purple.png",
	"english_lavender": "res://assets/ui/customer_orders/flowers/flower_icon_hybrid_purple.png",
	"sunflower": "res://assets/ui/customer_orders/flowers/flower_icon_marigold_yellow.png",
	"golden_rose": "res://assets/ui/customer_orders/flowers/flower_icon_marigold_yellow.png",
	"sunburst_daisy": "res://assets/ui/customer_orders/flowers/flower_icon_marigold_yellow.png",
	"tulip": "res://assets/ui/customer_orders/flowers/flower_icon_tulip_pink.png",
	"pastel_tulip": "res://assets/ui/customer_orders/flowers/flower_icon_tulip_pink.png",
	"roselight": "res://assets/ui/customer_orders/flowers/flower_icon_tulip_pink.png",
	"daisy": "res://assets/ui/customer_orders/flowers/flower_icon_daisy_white.png",
	"sunny_daisy": "res://assets/ui/customer_orders/flowers/flower_icon_daisy_white.png",
	"meadow_mist": "res://assets/ui/customer_orders/flowers/flower_icon_daisy_white.png",
	"bellflower": "res://assets/ui/customer_orders/flowers/flower_icon_bellflower_blue.png",
	"hydrangea": "res://assets/ui/customer_orders/flowers/flower_icon_bellflower_blue.png",
	"twilight_bell": "res://assets/ui/customer_orders/flowers/flower_icon_bellflower_blue.png",
	"garden_harmony": "res://assets/ui/customer_orders/flowers/flower_icon_rosebud_red.png",
	"crimson_romance": "res://assets/ui/customer_orders/flowers/flower_icon_rosebud_red.png",
	"ethereal_lumina": "res://assets/ui/customer_orders/flowers/flower_icon_tulip_pink.png",
	"solar_grandeur": "res://assets/ui/customer_orders/flowers/flower_icon_marigold_yellow.png",
	"spring_meadow": "res://assets/ui/customer_orders/flowers/flower_icon_daisy_white.png",
	"pure_elegance": "res://assets/ui/customer_orders/flowers/flower_icon_tulip_pink.png"
}

# Customer Portrait Mapping
const CUSTOMER_PORTRAIT_MAP := {
	"Maya": "res://assets/ui/orders/customers/circular/circ_customer_01_florist.png",
	"Florist": "res://assets/ui/orders/customers/circular/circ_customer_01_florist.png",
	"Young Florist": "res://assets/ui/orders/customers/circular/circ_customer_01_florist.png",
	"Lucian": "res://assets/ui/orders/customers/circular/circ_customer_02_gardener.png",
	"Gardener": "res://assets/ui/orders/customers/circular/circ_customer_02_gardener.png",
	"Kindly Gardener": "res://assets/ui/orders/customers/circular/circ_customer_02_gardener.png",
	"Clara": "res://assets/ui/orders/customers/circular/circ_customer_03_elf_florist.png",
	"Elf Florist": "res://assets/ui/orders/customers/circular/circ_customer_03_elf_florist.png",
	"Floral Elf Florist": "res://assets/ui/orders/customers/circular/circ_customer_03_elf_florist.png",
	"Baker": "res://assets/ui/orders/customers/circular/circ_customer_04_baker.png",
	"Young Baker": "res://assets/ui/orders/customers/circular/circ_customer_04_baker.png",
	"Teahouse": "res://assets/ui/orders/customers/circular/circ_customer_05_teahouse.png",
	"Botanist": "res://assets/ui/orders/customers/circular/circ_customer_06_botanist.png",
	"Madame Aurelia": "res://assets/ui/orders/customers/circular/circ_customer_07_seamstress.png",
	"Seamstress": "res://assets/ui/orders/customers/circular/circ_customer_07_seamstress.png",
	"Cat Courier": "res://assets/ui/orders/customers/circular/circ_customer_08_cat_courier.png",
	"Beekeeper": "res://assets/ui/orders/customers/circular/circ_customer_09_beekeeper.png",
	"Apprentice": "res://assets/ui/orders/customers/circular/circ_customer_10_garden_apprentice.png"
}

# Customer Hearts Default
const CUSTOMER_HEARTS_MAP := {
	"Maya": 3,
	"Florist": 3,
	"Young Florist": 3,
	"Lucian": 2,
	"Gardener": 2,
	"Kindly Gardener": 2,
	"Clara": 5,
	"Elf Florist": 5,
	"Floral Elf Florist": 5,
	"Madame Aurelia": 4,
	"Seamstress": 4,
	"Baker": 3,
	"Cat Courier": 4,
	"Apprentice": 2
}

# Node References
@onready var close_btn: Button = get_node_or_null("HeaderArea/CloseBtn")
@onready var progress_bar: Range = find_child("ProgressBar", true, false) as Range
@onready var progress_label: Label = find_child("ProgressLabel", true, false) as Label

@onready var card_01: Control = get_node_or_null("CardsVBox/OrderCard_01")
@onready var card_02: Control = get_node_or_null("CardsVBox/OrderCard_02")
@onready var card_03: Control = get_node_or_null("CardsVBox/OrderCard_03")

@onready var arrow_left_btn: TextureButton = get_node_or_null("BottomCarousel/ArrowLeft")
@onready var arrow_right_btn: TextureButton = get_node_or_null("BottomCarousel/ArrowRight")
@onready var mini_cards_row: HBoxContainer = get_node_or_null("BottomCarousel/MiniCardsRow")

# State
var _active_orders: Array[String] = []
var _ticket_cards: Dictionary = {}  # Maintained for smoke_test & external compatibility
var _selected_order_id: String = ""
var _carousel_offset: int = 0
var _inventory: Dictionary = {}
var _bouquet_inventory: Dictionary = {}
var _patience_data: Dictionary = {}
var _completed_requests: Dictionary = {}
var _daily_goal: int = 6

var _cards: Array[Control] = []


func _ready() -> void:
	_cards = [card_01, card_02, card_03]
	
	if close_btn != null:
		close_btn.pressed.connect(func(): closed.emit())
	if arrow_left_btn != null:
		arrow_left_btn.pressed.connect(func(): _prev_carousel())
	if arrow_right_btn != null:
		arrow_right_btn.pressed.connect(func(): _next_carousel())
		
	# Wire action buttons
	for i in range(_cards.size()):
		var card := _cards[i]
		if is_instance_valid(card):
			var btn: TextureButton = card.find_child("ActionBtn", true, false) as TextureButton
			if btn != null:
				var idx := i
				btn.pressed.connect(func(): _on_card_action_pressed(idx))

	_refresh_tickets()
	_update_ui()


func _process(_delta: float) -> void:
	if not visible:
		return
	_update_live_timers()


func update_state(inventory: Dictionary, bouquet_inv: Dictionary, patience: Dictionary, completed: Dictionary) -> void:
	_inventory = inventory
	_bouquet_inventory = bouquet_inv
	_patience_data = patience
	_completed_requests = completed
	_refresh_tickets()
	_update_ui()


func _refresh_tickets() -> void:
	_ticket_cards.clear()
	_active_orders.clear()
	
	var all_ids := FloristRequestData.get_all_request_ids()
	for o_id in all_ids:
		var req := FloristRequestData.get_request(o_id)
		var is_done: bool = _completed_requests.get(o_id, false)
		_ticket_cards[o_id] = {
			"request": req,
			"is_completed": is_done,
			"dialogue": req.get("dialogue", ""),
			"patience": _patience_data.get(o_id, req.get("patience_sec", 60.0))
		}
		_active_orders.append(o_id)
		
	if _selected_order_id.is_empty() and not _active_orders.is_empty():
		_selected_order_id = _active_orders[0]


func select_order(order_id: String) -> void:
	_selected_order_id = order_id
	order_selected.emit(order_id)
	_update_ui()


func _on_card_action_pressed(card_index: int) -> void:
	if card_index >= _active_orders.size():
		return
	var order_id: String = _active_orders[card_index]
	if _can_fulfill_order(order_id):
		_play_sfx("sfx_coin")
		fulfill_requested.emit(order_id)
	else:
		_play_sfx("sfx_click")
		select_order(order_id)


func _prev_carousel() -> void:
	_play_sfx("sfx_click")
	_carousel_offset = max(0, _carousel_offset - 1)
	_update_bottom_carousel()


func _next_carousel() -> void:
	_play_sfx("sfx_click")
	if _carousel_offset + 4 < _active_orders.size():
		_carousel_offset += 1
	_update_bottom_carousel()


func _can_fulfill_order(order_id: String) -> bool:
	if _completed_requests.get(order_id, false):
		return false
	var req := FloristRequestData.get_request(order_id)
	if req.is_empty():
		return false
	var req_items: Dictionary = req.get("required_items", {})
	for item_id in req_items.keys():
		var needed: int = int(req_items[item_id])
		var have: int = int(_inventory.get(item_id, 0)) + int(_bouquet_inventory.get(item_id, 0))
		if have < needed:
			return false
	return true


func _update_ui() -> void:
	_update_header()
	for i in range(3):
		if i < _cards.size():
			var card_node := _cards[i]
			if i < _active_orders.size():
				card_node.visible = true
				_update_card(card_node, _active_orders[i], i)
			else:
				card_node.visible = false
	_update_bottom_carousel()


func _update_header() -> void:
	var completed_count: int = 0
	for o_id in _completed_requests.keys():
		if _completed_requests[o_id]:
			completed_count += 1
	var total: int = max(1, _daily_goal)
	if progress_bar != null:
		progress_bar.value = float(completed_count) / float(total) * 100.0
	if progress_label != null:
		progress_label.text = "%d / %d Orders" % [completed_count, total]


func _update_card(card: Control, order_id: String, _card_index: int) -> void:
	var req := FloristRequestData.get_request(order_id)
	if req.is_empty():
		return
		
	var is_completed: bool = _completed_requests.get(order_id, false)
	var can_fulfill := _can_fulfill_order(order_id)
	
	# 1. Customer Portrait
	var cust_name: String = req.get("customer_name", "Maya")
	var portrait_node: TextureRect = card.get_node_or_null("Portrait")
	if portrait_node != null:
		var p_path: String = CUSTOMER_PORTRAIT_MAP.get(cust_name, "res://assets/ui/orders/customers/circular/circ_customer_01_florist.png")
		portrait_node.texture = load(p_path)
		
	# 2. Customer Hearts
	var hearts_row: HBoxContainer = card.get_node_or_null("HeartsRow")
	if hearts_row != null:
		var heart_count: int = CUSTOMER_HEARTS_MAP.get(cust_name, 3)
		var hearts_nodes := hearts_row.get_children()
		for h_idx in range(hearts_nodes.size()):
			var h_rect: TextureRect = hearts_nodes[h_idx]
			if h_idx < heart_count:
				h_rect.texture = HEART_FULL_TEX
			else:
				h_rect.texture = HEART_EMPTY_TEX

	# 3. Requirement Slots (Parse required_items dictionary)
	var req_items: Dictionary = req.get("required_items", {})
	var item_keys := req_items.keys()
	var req_row: HBoxContainer = card.get_node_or_null("RequirementsRow")
	if req_row != null:
		for slot_idx in range(3):
			var slot_node: Control = req_row.get_node_or_null("Slot" + str(slot_idx))
			if slot_node == null:
				continue
			var empty_dashed: TextureRect = slot_node.get_node_or_null("EmptyDashed")
			var pin_node: TextureRect = slot_node.get_node_or_null("Pin")
			var flower_icon: TextureRect = slot_node.get_node_or_null("FlowerIcon")
			var badge_panel: PanelContainer = slot_node.get_node_or_null("Badge")
			var badge_label: Label = slot_node.get_node_or_null("Badge/Label")
			
			if slot_idx < item_keys.size():
				var it_id: String = item_keys[slot_idx]
				var needed_qty: int = int(req_items[it_id])
				var have_qty: int = int(_inventory.get(it_id, 0)) + int(_bouquet_inventory.get(it_id, 0))
				
				if empty_dashed != null:
					empty_dashed.visible = false
				if pin_node != null:
					pin_node.visible = true
				
				# Flower icon
				if flower_icon != null:
					var icon_path: String = FLOWER_ICON_MAP.get(it_id, "res://assets/ui/customer_orders/flowers/flower_icon_hybrid_purple.png")
					flower_icon.texture = load(icon_path)
					flower_icon.visible = true
					
				# Count badge
				if badge_panel != null:
					badge_panel.visible = true
					var style: StyleBoxFlat = badge_panel.get_theme_stylebox("panel").duplicate()
					if have_qty >= needed_qty:
						style.bg_color = Color(0.18, 0.46, 0.18, 0.95) # Green
					else:
						style.bg_color = Color(0.55, 0.22, 0.18, 0.95) # Soft reddish brown
					badge_panel.add_theme_stylebox_override("panel", style)
					
				if badge_label != null:
					badge_label.text = "%d/%d" % [have_qty, needed_qty]
			else:
				# 3rd slot empty: show dashed outline with floral silhouette
				if empty_dashed != null:
					empty_dashed.visible = true
				if pin_node != null:
					pin_node.visible = false
				if flower_icon != null:
					flower_icon.visible = false
				if badge_panel != null:
					badge_panel.visible = false

	# 4. Action Button (Identical footprint across all states)
	var action_btn: TextureButton = card.find_child("ActionBtn", true, false) as TextureButton
	var btn_label: Label = card.find_child("BtnLabel", true, false) as Label
	var stamp_node: TextureRect = card.find_child("StatusStamp", true, false) as TextureRect
	
	if is_completed:
		if action_btn != null:
			action_btn.visible = true
			action_btn.disabled = true
			action_btn.texture_normal = BTN_GREEN_TEX
			if btn_label != null:
				btn_label.visible = false
				btn_label.text = ""
		if stamp_node != null:
			stamp_node.texture = STAMP_CHECK_TEX
			stamp_node.visible = true # Single completion seal
	else:
		if stamp_node != null:
			stamp_node.visible = false
		if action_btn != null:
			action_btn.visible = true
			action_btn.disabled = not can_fulfill
			if can_fulfill:
				action_btn.texture_normal = BTN_GREEN_TEX
			else:
				action_btn.texture_normal = BTN_NEUTRAL_TEX
			if btn_label != null:
				btn_label.visible = false
				btn_label.text = ""

	# 5. Visual Pocket-Watch Radial Timer
	var watch_dial: Control = card.find_child("WatchDial", true, false) as Control
	if watch_dial != null:
		if is_completed:
			watch_dial.call("set_timer", 0.0, true, Color(0.35, 0.62, 0.35, 1.0))
		else:
			var max_pat: float = float(req.get("patience_max_seconds", req.get("patience_sec", 60.0)))
			var pat: float = float(_patience_data.get(order_id, max_pat))
			var ratio: float = clampf(pat / max(1.0, max_pat), 0.0, 1.0)
			var timer_color: Color
			var wedge_ratio: float = 0.25
			if ratio > 0.6:
				timer_color = Color(0.92, 0.72, 0.25, 1) # Honey
				wedge_ratio = 0.25
			elif ratio > 0.3:
				timer_color = Color(0.92, 0.54, 0.16, 1) # Orange
				wedge_ratio = 0.50
			else:
				timer_color = Color(0.85, 0.28, 0.28, 1) # Coral Red
				wedge_ratio = 0.75
			watch_dial.call("set_timer", wedge_ratio, false, timer_color)
			
	# 6. Aligned Readable Reward Cluster
	var coins_label: Label = card.find_child("CoinsLabel", true, false) as Label
	if coins_label != null:
		coins_label.text = "+%dg" % int(req.get("coin_reward", 25))


func _update_live_timers() -> void:
	for i in range(min(3, _active_orders.size())):
		var card_node := _cards[i]
		if not is_instance_valid(card_node) or not card_node.visible:
			continue
		var o_id: String = _active_orders[i]
		if _completed_requests.get(o_id, false):
			continue
		var watch_dial: Control = card_node.find_child("WatchDial", true, false) as Control
		if watch_dial != null:
			var req := FloristRequestData.get_request(o_id)
			var max_pat: float = float(req.get("patience_max_seconds", req.get("patience_sec", 60.0)))
			var pat: float = float(_patience_data.get(o_id, max_pat))
			var ratio: float = clampf(pat / max(1.0, max_pat), 0.0, 1.0)
			var timer_color: Color
			var wedge_ratio: float = 0.25
			if ratio > 0.6:
				timer_color = Color(0.92, 0.72, 0.25, 1)
				wedge_ratio = 0.25
			elif ratio > 0.3:
				timer_color = Color(0.92, 0.54, 0.16, 1)
				wedge_ratio = 0.50
			else:
				timer_color = Color(0.85, 0.28, 0.28, 1)
				wedge_ratio = 0.75
			watch_dial.call("set_timer", wedge_ratio, false, timer_color)


func _update_bottom_carousel() -> void:
	if mini_cards_row == null:
		return
	var mini_cards := mini_cards_row.get_children()
	for i in range(mini_cards.size()):
		var m_card: Control = mini_cards[i]
		var order_idx := _carousel_offset + i
		if order_idx < _active_orders.size():
			m_card.visible = true
			var o_id: String = _active_orders[order_idx]
			var req := FloristRequestData.get_request(o_id)
			var cust_name: String = req.get("customer_name", "Maya")
			
			var port_node: TextureRect = m_card.find_child("Portrait", true, false) as TextureRect
			if port_node != null:
				var p_path: String = CUSTOMER_PORTRAIT_MAP.get(cust_name, "res://assets/ui/orders/customers/circular/circ_customer_01_florist.png")
				port_node.texture = load(p_path)
				
			var flower_node: TextureRect = m_card.find_child("Flower", true, false) as TextureRect
			if flower_node != null:
				var req_items: Dictionary = req.get("required_items", {})
				if not req_items.is_empty():
					var first_item: String = req_items.keys()[0]
					var f_path: String = FLOWER_ICON_MAP.get(first_item, "res://assets/ui/customer_orders/flowers/flower_icon_hybrid_purple.png")
					flower_node.texture = load(f_path)
			
			# Visual selected state on mini card
			var style := StyleBoxFlat.new()
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_right = 6
			style.corner_radius_bottom_left = 6
			if o_id == _selected_order_id:
				style.bg_color = Color(1.0, 0.98, 0.93, 0.98)
				style.border_width_left = 2
				style.border_width_top = 2
				style.border_width_right = 2
				style.border_width_bottom = 2
				style.border_color = Color(0.92, 0.76, 0.35, 1.0) # Golden active border
				style.shadow_color = Color(0.85, 0.65, 0.2, 0.35)
				style.shadow_size = 3
			else:
				style.bg_color = Color(0.99, 0.97, 0.92, 0.96)
				style.border_width_left = 1
				style.border_width_top = 1
				style.border_width_right = 1
				style.border_width_bottom = 1
				style.border_color = Color(0.85, 0.77, 0.65, 0.95)
				style.shadow_color = Color(0.15, 0.08, 0.03, 0.2)
				style.shadow_size = 2
			m_card.add_theme_stylebox_override("panel", style)
			
			# Wire touch click on mini card
			if not m_card.gui_input.is_connected(_on_mini_card_gui_input):
				m_card.gui_input.connect(_on_mini_card_gui_input.bind(o_id))
		else:
			m_card.visible = false


func _on_mini_card_gui_input(event: InputEvent, order_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_play_sfx("sfx_click")
		select_order(order_id)

func _play_sfx(sfx_name: String) -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		get_tree().root.get_node("AudioManager").play_sfx(sfx_name)
