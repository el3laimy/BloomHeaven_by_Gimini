class_name SideOrderRail
extends Control

## BloomHaven - Modular Customer Orders Organizer (Side Rail).
## Integrates the shared responsive OrderBoardContent component.

signal fulfill_requested(order_id: String)
signal order_details_requested(order_id: String)
signal opened()
signal closed()

@onready var board_panel: Control = $BoardPanel
@onready var pull_tab_btn: TextureButton = get_node_or_null("PullTab")
const OrderBoardContentScript := preload("res://scripts/ui/orders/order_board_content.gd")
@onready var order_board: Control = get_node_or_null("BoardPanel/OrderBoard")

var _ticket_cards: Dictionary = {}

var _is_open: bool = true
var _is_animating: bool = false


func _ready() -> void:
	if pull_tab_btn != null:
		pull_tab_btn.pressed.connect(func(): toggle())
	if order_board != null:
		order_board.fulfill_requested.connect(func(o_id: String): fulfill_requested.emit(o_id))
		order_board.closed.connect(func(): close())
	_refresh_tickets()


func update_state(inventory: Dictionary, bouquet_inv: Dictionary, patience: Dictionary, completed: Dictionary) -> void:
	var board := _get_order_board()
	if is_instance_valid(board):
		board.update_state(inventory, bouquet_inv, patience, completed)
		_ticket_cards = board._ticket_cards


func _refresh_tickets() -> void:
	var board := _get_order_board()
	if is_instance_valid(board):
		board._refresh_tickets()
		_ticket_cards = board._ticket_cards
	else:
		_ticket_cards.clear()
		for o_id in FloristRequestData.get_all_request_ids():
			var req := FloristRequestData.get_request(o_id)
			_ticket_cards[o_id] = {
				"request": req,
				"is_completed": false,
				"dialogue": req.get("dialogue", ""),
				"patience": req.get("patience_sec", 60.0)
			}


func select_order(order_id: String) -> void:
	var board := _get_order_board()
	if is_instance_valid(board):
		board.select_order(order_id)


func _get_order_board() -> Control:
	if is_instance_valid(order_board):
		return order_board
	return get_node_or_null("BoardPanel/OrderBoard")


func toggle() -> void:
	if _is_open:
		close()
	else:
		open()


func open() -> void:
	if _is_open or _is_animating:
		return
	_is_animating = true
	visible = true
	var tw := create_tween()
	tw.tween_property(self, "position:x", 1280 - size.x - 10, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		_is_open = true
		_is_animating = false
		opened.emit()
	)


func close() -> void:
	if not _is_open or _is_animating:
		return
	_is_animating = true
	closed.emit()
	var tw := create_tween()
	tw.tween_property(self, "position:x", 1280.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_is_open = false
		_is_animating = false
	)
