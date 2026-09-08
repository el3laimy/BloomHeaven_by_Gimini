class_name RequestsModal
extends Control

## Standalone UI Modal for Florist Customer Requests & Orders Board (Fiona Finch style).

signal fulfill_requested(order_id: String)
signal closed()

@onready var _card_container: VBoxContainer = $CenterContainer/Panel/Margin/VBox/Scroll/CardsVBox
@onready var _close_btn: Button = $CenterContainer/Panel/Margin/VBox/HeaderHBox/CloseBtn
@onready var _combo_label: Label = $CenterContainer/Panel/Margin/VBox/HeaderHBox/ComboLabel

var live_patience: Dictionary = {}
var completed_status: Dictionary = {}
var flower_inventory: Dictionary = {}
var bouquet_inventory: Dictionary = {}
var combo_count: int = 0


func _ready() -> void:
	if _close_btn != null:
		_close_btn.pressed.connect(func():
			_play_click()
			hide()
			closed.emit()
		)


func open_board(patience_dict: Dictionary, completed_dict: Dictionary, flowers: Dictionary, bouquets: Dictionary, combo: int) -> void:
	live_patience = patience_dict
	completed_status = completed_dict
	flower_inventory = flowers
	bouquet_inventory = bouquets
	combo_count = combo
	_update_header_combo()
	_populate_orders()
	show()


func _update_header_combo() -> void:
	if _combo_label != null:
		if combo_count > 1:
			_combo_label.text = "🔥 Combo Rush x%d (+%d%%)" % [combo_count, int((combo_count * 0.25) * 100)]
			_combo_label.visible = true
		else:
			_combo_label.visible = false


func _populate_orders() -> void:
	if _card_container == null:
		return

	for child in _card_container.get_children():
		child.queue_free()

	for o_id in FloristRequestData.get_all_request_ids():
		var card := _create_order_card(o_id)
		_card_container.add_child(card)


func _create_order_card(order_id: String) -> PanelContainer:
	var req: Dictionary = FloristRequestData.get_request(order_id)
	var is_done: bool = completed_status.get(order_id, false)
	var max_pat: float = float(req.get("patience_max_seconds", 75.0))
	var cur_pat: float = float(live_patience.get(order_id, max_pat))
	var pat_ratio: float = clamp(cur_pat / max_pat, 0.0, 1.0)

	var check: Dictionary = FloristRequestData.check_fulfillment(order_id, flower_inventory, bouquet_inventory)
	var can_fulfill: bool = check.get("can_fulfill", false)

	var card := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Row 1: Header with Customer Name, Reward, and Status
	var top_row := HBoxContainer.new()
	vbox.add_child(top_row)

	var name_lbl := Label.new()
	name_lbl.text = "%s — %s" % [req.get("customer_name", "Customer"), req.get("title", "Order")]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.70))
	top_row.add_child(name_lbl)

	var base_reward: int = int(req.get("coin_reward", req.get("base_reward_coins", 25)))
	var rew_lbl := Label.new()
	rew_lbl.text = "🪙 %d Coins" % base_reward
	rew_lbl.add_theme_font_size_override("font_size", 12)
	rew_lbl.add_theme_color_override("font_color", Color(0.98, 0.85, 0.35))
	top_row.add_child(rew_lbl)

	# Row 2: Requirements & Action Button
	var mid_row := HBoxContainer.new()
	vbox.add_child(mid_row)

	var req_lbl := Label.new()
	var items: Dictionary = req.get("required_items", {})
	var req_parts: Array[String] = []
	for it in items:
		var has_count: int = flower_inventory.get(it, bouquet_inventory.get(it, 0))
		var needed: int = int(items[it])
		req_parts.append("%s: %d/%d" % [it.capitalize(), has_count, needed])
	req_lbl.text = "Needed: " + ", ".join(req_parts)
	req_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	req_lbl.add_theme_font_size_override("font_size", 11)
	req_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	mid_row.add_child(req_lbl)

	var act_btn := Button.new()
	act_btn.custom_minimum_size = Vector2(105, 30)
	if is_done:
		act_btn.text = "✓ Completed"
		act_btn.disabled = true
	else:
		act_btn.text = "Deliver"
		act_btn.disabled = not can_fulfill
		act_btn.pressed.connect(func():
			_play_click()
			fulfill_requested.emit(order_id)
			hide()
			closed.emit()
		)
	mid_row.add_child(act_btn)

	# Row 3: Patience Bar
	if not is_done:
		var pat_hbox := HBoxContainer.new()
		pat_hbox.add_theme_constant_override("separation", 8)
		vbox.add_child(pat_hbox)

		var tier_str: String = "🥇 Gold (+50% Tip)" if pat_ratio > 0.65 else ("🥈 Silver (+25% Tip)" if pat_ratio > 0.30 else "🥉 Bronze")
		var tier_lbl := Label.new()
		tier_lbl.text = "Patience (%s):" % tier_str
		tier_lbl.add_theme_font_size_override("font_size", 10)
		pat_hbox.add_child(tier_lbl)

		var pbar := ProgressBar.new()
		pbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pbar.custom_minimum_size = Vector2(0, 12)
		pbar.show_percentage = false
		pbar.value = pat_ratio * 100.0
		pat_hbox.add_child(pbar)

	return card


func _play_click() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		get_tree().root.get_node("AudioManager").play_sfx("click")
