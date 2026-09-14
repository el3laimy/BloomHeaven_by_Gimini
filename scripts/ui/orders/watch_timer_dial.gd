class_name WatchTimerDial
extends Control

## Visual antique pocket-watch dial for Customer Orders Board.
## Renders a clean cream face with an antialiased radial pie wedge.

@export var progress_ratio: float = 0.25 # 0.0 to 1.0 (wedge size)
@export var is_completed: bool = false
@export var pie_color: Color = Color(0.85, 0.28, 0.28, 1.0)


func set_timer(ratio: float, completed: bool, color: Color) -> void:
	progress_ratio = ratio
	is_completed = completed
	pie_color = color
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5
	if radius <= 1.0:
		return

	# 1. Warm antique cream dial background
	draw_circle(center, radius, Color(0.97, 0.94, 0.88, 1.0))

	if is_completed:
		# Completed state: warm green fill with clean checkmark (matching reference)
		draw_circle(center, radius - 1.0, Color(0.32, 0.65, 0.38, 1.0))
		var p1 := center + Vector2(-radius * 0.38, -radius * 0.05)
		var p2 := center + Vector2(-radius * 0.08, radius * 0.32)
		var p3 := center + Vector2(radius * 0.42, -radius * 0.35)
		draw_polyline(PackedVector2Array([p1, p2, p3]), Color(1.0, 1.0, 1.0, 0.98), 2.5, true)
		draw_circle(center, 2.0, Color(0.2, 0.45, 0.25, 1.0))
	elif progress_ratio > 0.02:
		# Radial pie wedge from 12 o'clock clockwise
		var start_angle: float = -PI * 0.5
		var end_angle: float = start_angle + (progress_ratio * TAU)
		var points: PackedVector2Array = PackedVector2Array([center])
		var segments: int = 32
		for i in range(segments + 1):
			var a: float = lerp(start_angle, end_angle, float(i) / float(segments))
			points.append(center + Vector2(cos(a), sin(a)) * radius)
		draw_colored_polygon(points, pie_color)

		# Crisp dark hand at leading edge
		var hand_tip: Vector2 = center + Vector2(cos(end_angle), sin(end_angle)) * (radius - 1.0)
		draw_line(center, hand_tip, Color(0.25, 0.18, 0.12, 0.95), 1.5, true)
		draw_circle(center, 2.0, Color(0.25, 0.18, 0.12, 1.0))
	else:
		# Empty / full time: hand at 12 o'clock
		var hand_tip: Vector2 = center + Vector2(0.0, -radius * 0.75)
		draw_line(center, hand_tip, Color(0.3, 0.22, 0.15, 0.85), 1.5, true)
		draw_circle(center, 2.0, Color(0.3, 0.22, 0.15, 0.9))
