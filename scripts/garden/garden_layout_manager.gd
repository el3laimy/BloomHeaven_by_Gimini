class_name GardenLayoutManager
extends RefCounted

## Garden Layout Manager & Spatial Customization Engine for BloomHaven.
## Manages 4 Raised Wooden Garden Beds (2x3 grids) + 1 Center-Bottom Hero Showcase Plot (25 plots total).

enum LayoutPreset {
	BLOOMHAVEN_HERO = 0,
	PROMENADE = 1,
	SERPENTINE_OASIS = 2
}

const PRESET_NAMES: Dictionary = {
	LayoutPreset.BLOOMHAVEN_HERO: "BloomHaven Sanctuary (4 Raised Beds)",
	LayoutPreset.PROMENADE: "Classic Promenade",
	LayoutPreset.SERPENTINE_OASIS: "Serpentine Oasis"
}


static func get_layout_positions(preset: LayoutPreset = LayoutPreset.BLOOMHAVEN_HERO, count: int = 25, perspective_mode: int = 1) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var y_scale := 0.85 if perspective_mode == 1 else 1.0

	match preset:
		LayoutPreset.PROMENADE:
			# Classic Promenade: A wide central avenue flanked by two double-column flower borders
			# Left Border (12 plots: 2 columns x 6 rows)
			for row in range(6):
				var y_pos: float = (-140.0 + row * 56.0) * y_scale
				positions.append(Vector2(-240.0, y_pos))
				positions.append(Vector2(-160.0, y_pos))
			# Right Border (12 plots: 2 columns x 6 rows)
			for row in range(6):
				var y_pos: float = (-140.0 + row * 56.0) * y_scale
				positions.append(Vector2(160.0, y_pos))
				positions.append(Vector2(240.0, y_pos))
			# North Central Vista Hero Plot (1 plot)
			positions.append(Vector2(0.0, -165.0 * y_scale))

		LayoutPreset.SERPENTINE_OASIS:
			# Serpentine Oasis: Concentric floral rings radiating around the garden fountain
			# Inner Ring (8 plots)
			var inner_rx: float = 145.0
			var inner_ry: float = 90.0 * y_scale
			for i in range(8):
				var angle: float = (i / 8.0) * TAU - (PI * 0.5)
				positions.append(Vector2(cos(angle) * inner_rx, sin(angle) * inner_ry))
			# Outer Ring (16 plots)
			var outer_rx: float = 270.0
			var outer_ry: float = 160.0 * y_scale
			for i in range(16):
				var angle: float = (i / 16.0) * TAU - (PI * 0.5) + (PI / 16.0)
				positions.append(Vector2(cos(angle) * outer_rx, sin(angle) * outer_ry))
			# Center Oasis Focus Plot (1 plot)
			positions.append(Vector2(0.0, 60.0 * y_scale))

		_:
			# Default: BloomHaven Sanctuary (4 Raised 2x3 Beds + 1 Hero Plot)
			# Top-Left Bed (Plots 0-5)
			var tl := [
				Vector2(-255, -125 * y_scale), Vector2(-185, -125 * y_scale), Vector2(-115, -125 * y_scale),
				Vector2(-255, -65 * y_scale),  Vector2(-185, -65 * y_scale),  Vector2(-115, -65 * y_scale)
			]
			# Top-Right Bed (Plots 6-11)
			var tr := [
				Vector2(115, -125 * y_scale),  Vector2(185, -125 * y_scale),  Vector2(255, -125 * y_scale),
				Vector2(115, -65 * y_scale),   Vector2(185, -65 * y_scale),   Vector2(255, -65 * y_scale)
			]
			# Bottom-Left Bed (Plots 12-17)
			var bl := [
				Vector2(-255, 75 * y_scale),   Vector2(-185, 75 * y_scale),   Vector2(-115, 75 * y_scale),
				Vector2(-255, 135 * y_scale),  Vector2(-185, 135 * y_scale),  Vector2(-115, 135 * y_scale)
			]
			# Bottom-Right Bed (Plots 18-23)
			var br := [
				Vector2(115, 75 * y_scale),    Vector2(185, 75 * y_scale),    Vector2(255, 75 * y_scale),
				Vector2(115, 135 * y_scale),   Vector2(185, 135 * y_scale),   Vector2(255, 135 * y_scale)
			]
			# Center-Bottom Hero Showcase Plot (Plot 24)
			var hero_plot := Vector2(0, 140 * y_scale)

			for p in tl: positions.append(p)
			for p in tr: positions.append(p)
			for p in bl: positions.append(p)
			for p in br: positions.append(p)
			positions.append(hero_plot)

	# Pad or trim to count
	while positions.size() < count:
		var idx := positions.size()
		positions.append(Vector2((idx % 4 - 1.5) * 110.0, (int(idx / 4) - 1.0) * 80.0 * y_scale))

	return positions


static func apply_layout_to_grid(
	grid: GardenGrid,
	preset: LayoutPreset = LayoutPreset.BLOOMHAVEN_HERO,
	perspective_mode: int = 1,
	animate: bool = true
) -> void:
	if grid == null:
		return

	var target_positions := get_layout_positions(preset, grid.plots.size(), perspective_mode)

	for i in range(grid.plots.size()):
		var plot: GardenPlot = grid.plots[i]
		var target_pos: Vector2 = target_positions[i]

		if animate and plot.is_inside_tree():
			var tween := plot.create_tween()
			if tween != null:
				tween.tween_property(plot, "position", target_pos, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			plot.position = target_pos
