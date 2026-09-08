class_name GardenCamera
extends Camera2D

## Smooth 2D Camera with drag-to-pan, mouse-wheel zoom, boundary clamping, and reset.

@export var pan_speed: float = 1.0
@export var min_zoom: float = 0.65
@export var max_zoom: float = 2.0
@export var zoom_step: float = 0.15
@export var smooth_speed: float = 12.0
@export var boundary_limit: Rect2 = Rect2(-650, -450, 1300, 900)

var _target_position: Vector2 = Vector2.ZERO
var _target_zoom: Vector2 = Vector2.ONE
var _is_dragging: bool = false
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_pos: Vector2 = Vector2.ZERO

var _touch_points: Dictionary = {}
var _last_pinch_distance: float = 0.0


func _ready() -> void:
	_target_position = position
	_target_zoom = zoom


func _process(delta: float) -> void:
	position = position.lerp(_target_position, delta * smooth_speed)
	zoom = zoom.lerp(_target_zoom, delta * smooth_speed)


func _unhandled_input(event: InputEvent) -> void:
	# Screen Touch (Mobile Touch Drag and Pinch Zoom)
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch_points[touch.index] = touch.position
			if _touch_points.size() == 2:
				var pts: Array = _touch_points.values()
				_last_pinch_distance = (pts[0] as Vector2).distance_to(pts[1] as Vector2)
		else:
			_touch_points.erase(touch.index)
			if _touch_points.size() < 2:
				_last_pinch_distance = 0.0

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_touch_points[drag.index] = drag.position

		if _touch_points.size() >= 2:
			var pts: Array = _touch_points.values()
			var current_dist: float = (pts[0] as Vector2).distance_to(pts[1] as Vector2)
			if _last_pinch_distance > 0.0:
				var zoom_factor: float = current_dist / _last_pinch_distance
				var next_zoom: float = clampf(_target_zoom.x * zoom_factor, min_zoom, max_zoom)
				_target_zoom = Vector2(next_zoom, next_zoom)
			_last_pinch_distance = current_dist
			get_viewport().set_input_as_handled()
		elif _touch_points.size() == 1:
			var world_delta: Vector2 = drag.relative / zoom.x
			_target_position = _clamp_position(_target_position - world_delta)
			get_viewport().set_input_as_handled()

	# Mouse Drag to Pan (Right click or Middle click)
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT or mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			if mouse_event.is_pressed():
				_start_drag(mouse_event.position)
			else:
				_end_drag()

		# Mouse Wheel Zoom
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.is_pressed():
			zoom_in()
			get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.is_pressed():
			zoom_out()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and _is_dragging:
		var motion_event := event as InputEventMouseMotion
		var delta_screen: Vector2 = motion_event.position - _drag_start_mouse
		var world_delta: Vector2 = delta_screen / zoom.x
		_target_position = _clamp_position(_drag_start_pos - world_delta)
		get_viewport().set_input_as_handled()


func _start_drag(screen_pos: Vector2) -> void:
	_is_dragging = true
	_drag_start_mouse = screen_pos
	_drag_start_pos = _target_position


func _end_drag() -> void:
	_is_dragging = false


func zoom_in() -> void:
	var next_val := clampf(_target_zoom.x + zoom_step, min_zoom, max_zoom)
	_target_zoom = Vector2(next_val, next_val)


func zoom_out() -> void:
	var next_val := clampf(_target_zoom.x - zoom_step, min_zoom, max_zoom)
	_target_zoom = Vector2(next_val, next_val)


func reset_view() -> void:
	_target_position = Vector2.ZERO
	_target_zoom = Vector2.ONE


func reset_camera() -> void:
	reset_view()



func _clamp_position(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, boundary_limit.position.x, boundary_limit.end.x),
		clampf(pos.y, boundary_limit.position.y, boundary_limit.end.y)
	)
