class_name CustomerOrdersMobile
extends Control

## BloomHaven - Fullscreen Customer Orders Modal (Mobile & Desktop).
## Reuses the single-source-of-truth OrderBoardContent component.

signal fulfill_requested(order_id: String)
signal order_selected(order_id: String)
signal closed()

@onready var dimmer_rect: ColorRect = $DimmerOverlay
@onready var board_container: Control = $BoardContainer
const OrderBoardContentScript := preload("res://scripts/ui/orders/order_board_content.gd")
@onready var order_board: Control = $BoardContainer/OrderBoard

const TARGET_BOARD_SCALE := Vector2(1.16, 1.16)
var _is_animating: bool = false


func _ready() -> void:
	if dimmer_rect != null:
		dimmer_rect.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				close()
		)
	if order_board != null:
		order_board.fulfill_requested.connect(func(o_id: String): fulfill_requested.emit(o_id))
		order_board.order_selected.connect(func(o_id: String): order_selected.emit(o_id))
		order_board.closed.connect(func(): close())


func update_state(inventory: Dictionary, bouquet_inv: Dictionary, patience: Dictionary, completed: Dictionary) -> void:
	if is_instance_valid(order_board):
		order_board.update_state(inventory, bouquet_inv, patience, completed)


func select_order(order_id: String) -> void:
	if is_instance_valid(order_board):
		order_board.select_order(order_id)


func open() -> void:
	if _is_animating:
		return
	_is_animating = true
	visible = true
	modulate.a = 0.0
	if board_container != null:
		board_container.pivot_offset = Vector2(205, 330)
		board_container.scale = TARGET_BOARD_SCALE * 0.85
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	if board_container != null:
		tw.tween_property(board_container, "scale", TARGET_BOARD_SCALE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func():
		_is_animating = false
	)


func close() -> void:
	if _is_animating:
		return
	_is_animating = true
	closed.emit()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	if board_container != null:
		tw.tween_property(board_container, "scale", TARGET_BOARD_SCALE * 0.9, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		visible = false
		_is_animating = false
	)
