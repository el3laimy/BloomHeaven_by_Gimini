class_name FlowerStandV2
extends Control

## BloomHaven Cottage Flower Stand V2
## Handcrafted storybook market stall with 2x2 product cards and harvest footer.

signal quick_sell_requested(flower_id: String, count: int)
signal sell_all_requested()
signal closed()

@onready var backdrop: ColorRect = $BackdropDim
@onready var stand_root: Control = $StandRoot
@onready var close_button: BaseButton = $CloseButton
@onready var title_label: Label = $StandRoot/Header/TitleLabel
@onready var products_area: GridContainer = $StandRoot/ProductsArea
@onready var harvest_footer: Control = $StandRoot/HarvestFooter

var _is_animating: bool = false


func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if backdrop:
		backdrop.gui_input.connect(_on_backdrop_gui_input)

	if stand_root:
		stand_root.pivot_offset = stand_root.size * 0.5


func open() -> void:
	if _is_animating:
		return
	show()
	_is_animating = true

	modulate.a = 0.0
	if stand_root:
		stand_root.pivot_offset = stand_root.size * 0.5
		stand_root.scale = Vector2(0.96, 0.96)

	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.22)
	if stand_root:
		tween.tween_property(stand_root, "scale", Vector2.ONE, 0.22)
	tween.chain().tween_callback(func(): _is_animating = false)

	_play_click()


func close() -> void:
	if _is_animating:
		return
	_is_animating = true

	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	if stand_root:
		tween.tween_property(stand_root, "scale", Vector2(0.96, 0.96), 0.18)
	tween.chain().tween_callback(func():
		hide()
		_is_animating = false
		closed.emit()
	)

	_play_click()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_close_pressed() -> void:
	close()


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()


func _play_click() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("button_click")


func update_inventory(inventory: Dictionary, bouquet_inventory: Dictionary) -> void:
	pass
