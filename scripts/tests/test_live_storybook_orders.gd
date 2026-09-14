extends SceneTree

## Visual Test for Customer Orders Board matching user reference exactly

func _init() -> void:
	print("--- Building Exact Reference Customer Orders Board ---")
	var root_ctrl = Control.new()
	root_ctrl.name = "OrdersTestRoot"
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.size = Vector2(1280, 720)
	root.add_child(root_ctrl)

	# 1. Subtle garden backdrop
	var bg_dim = ColorRect.new()
	bg_dim.color = Color(0.12, 0.16, 0.11, 0.96)
	bg_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.add_child(bg_dim)

	# 2. Corkboard Container
	# Board texture is 973 x 1456 (aspect ratio 0.668)
	var board_w := 340.0
	var board_h := 508.0
	var board_box := Control.new()
	board_box.name = "CorkboardRail"
	board_box.size = Vector2(board_w, board_h)
	board_box.position = Vector2(1280.0 - board_w - 12.0, 32.0)
	root_ctrl.add_child(board_box)

	# 3. Corkboard Texture
	var board_bg := TextureRect.new()
	board_bg.texture = load("res://assets/ui/customer_orders/ui_orders_corkboard_rail.png")
	board_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	board_bg.size = Vector2(board_w, board_h)
	board_box.add_child(board_bg)

	# 4. Close Button at Top Right finial
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(24, 24)
	close_btn.position = Vector2(board_w - 38.0, 16.0)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.22, 0.13, 0.07, 0.92)
	close_style.border_color = Color(0.85, 0.72, 0.35, 0.95)
	close_style.set_border_width_all(1)
	close_style.set_corner_radius_all(12)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_style)
	close_btn.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	close_btn.add_theme_font_size_override("font_size", 11)
	board_box.add_child(close_btn)

	# 5. Preload all textures
	var postcard_tex := load("res://assets/ui/customer_orders/ui_order_postcard_bg.png") as Texture2D
	var wax_seal_tex := load("res://assets/ui/customer_orders/ui_order_wax_seal.png") as Texture2D
	var watch_tex := load("res://assets/ui/customer_orders/ui_pocket_watch_timer.png") as Texture2D
	var slot_tex := load("res://assets/ui/customer_orders/ui_slot_flower_req.png") as Texture2D
	var stamp_check_tex := load("res://assets/ui/customer_orders/ui_stamp_checkmark.png") as Texture2D
	var ribbon_btn_tex := load("res://assets/ui/customer_orders/ui_btn_deliver_ribbon.png") as Texture2D
	var pin_tex := load("res://assets/ui/customer_orders/ui_golden_pin.png") as Texture2D

	# 4 Orders matching user reference
	var orders = [
		{
			"id": "order_1",
			"name": "Lucian",
			"has_wax": true,
			"slots": [
				{"icon": "🌼", "count": "2/2", "ready": true},
				{"icon": "🌷", "count": "1/1", "ready": true}
			],
			"time": "1m 45s",
			"can_deliver": true,
			"angle_deg": -3.2,
			"y_offset": 62.0
		},
		{
			"id": "order_2",
			"name": "Madame Aurelia",
			"has_wax": false,
			"slots": [
				{"icon": "🪻", "count": "1/1", "ready": true},
				{"icon": "", "count": "", "ready": false}
			],
			"time": "1m 20s",
			"can_deliver": false,
			"angle_deg": 2.5,
			"y_offset": 158.0
		},
		{
			"id": "order_3",
			"name": "Barnaby",
			"has_wax": false,
			"slots": [
				{"icon": "🌻", "count": "3/3", "ready": true},
				{"icon": "💐", "count": "1/1", "ready": true}
			],
			"time": "2m 10s",
			"can_deliver": true,
			"angle_deg": -2.0,
			"y_offset": 254.0
		},
		{
			"id": "order_4",
			"name": "Emma",
			"has_wax": false,
			"slots": [
				{"icon": "🌹", "count": "1/2", "ready": false},
				{"icon": "", "count": "", "ready": false}
			],
			"time": "0m 52s",
			"can_deliver": false,
			"angle_deg": 2.8,
			"y_offset": 350.0
		}
	]

	# Postcard Dimensions:
	# Scaled relative to board_w = 340
	# In 973 board, card is 630x252 -> in 340 board, card is 220 x 88
	var card_w := 226.0
	var card_h := 92.0
	var cork_center_x := board_w * 0.5

	for ord in orders:
		var card_pivot := Control.new()
		card_pivot.name = "Pivot_" + ord.id
		card_pivot.size = Vector2(card_w, card_h)
		card_pivot.pivot_offset = Vector2(card_w * 0.5, card_h * 0.5)
		card_pivot.rotation_degrees = ord.angle_deg
		card_pivot.position = Vector2(cork_center_x - card_w * 0.5 + (3.0 if ord.angle_deg > 0 else -3.0), ord.y_offset)
		board_box.add_child(card_pivot)

		# 1. Postcard Texture Background
		var p_bg := TextureRect.new()
		p_bg.texture = postcard_tex
		p_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p_bg.size = Vector2(card_w, card_h)
		card_pivot.add_child(p_bg)

		# 2. Golden Pushpin at Top Center
		var pin := TextureRect.new()
		pin.texture = pin_tex
		pin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pin.size = Vector2(10, 10)
		pin.position = Vector2(card_w * 0.5 - 5, 2)
		card_pivot.add_child(pin)

		# 3. Wax Seal on Top-Left (if high priority)
		if ord.has_wax:
			var wax := TextureRect.new()
			wax.texture = wax_seal_tex
			wax.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			wax.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			wax.size = Vector2(28, 28)
			wax.position = Vector2(6, 4)
			card_pivot.add_child(wax)

		# 4. Customer Name (above slots)
		var name_lbl := Label.new()
		name_lbl.text = ord.name
		name_lbl.position = Vector2(34 if ord.has_wax else 24, 8)
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", Color(0.26, 0.16, 0.08, 1))
		name_lbl.add_theme_color_override("font_shadow_color", Color(1, 0.96, 0.88, 0.8))
		name_lbl.add_theme_constant_override("shadow_offset_x", 1)
		name_lbl.add_theme_constant_override("shadow_offset_y", 1)
		card_pivot.add_child(name_lbl)

		# 5. Flower Request Slots (2 slots)
		var slot_size := 26.0
		var slot_xs = [26.0, 56.0]
		for s_idx in range(ord.slots.size()):
			var s_data = ord.slots[s_idx]
			var slot_ctrl := Control.new()
			slot_ctrl.size = Vector2(slot_size, slot_size)
			slot_ctrl.position = Vector2(slot_xs[s_idx], 24.0)
			card_pivot.add_child(slot_ctrl)

			var s_frame := TextureRect.new()
			s_frame.texture = slot_tex
			s_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			s_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			s_frame.size = Vector2(slot_size, slot_size)
			slot_ctrl.add_child(s_frame)

			if s_data.icon != "":
				var f_icon := Label.new()
				f_icon.text = s_data.icon
				f_icon.add_theme_font_size_override("font_size", 12)
				f_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				f_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				f_icon.size = Vector2(slot_size, slot_size)
				slot_ctrl.add_child(f_icon)

				# Count Pill
				var count_lbl := Label.new()
				count_lbl.text = s_data.count
				count_lbl.position = Vector2(1, 14)
				count_lbl.size = Vector2(slot_size - 2, 10)
				count_lbl.add_theme_font_size_override("font_size", 7)
				count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				count_lbl.add_theme_color_override("font_color", Color(0.98, 0.96, 0.90) if s_data.ready else Color(0.95, 0.45, 0.35))
				count_lbl.add_theme_color_override("font_shadow_color", Color(0.1, 0.05, 0.02, 0.95))
				count_lbl.add_theme_constant_override("shadow_offset_x", 1)
				count_lbl.add_theme_constant_override("shadow_offset_y", 1)
				slot_ctrl.add_child(count_lbl)

				# Checkmark Stamp if ready
				if s_data.ready:
					var stamp := TextureRect.new()
					stamp.texture = stamp_check_tex
					stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					stamp.size = Vector2(16, 16)
					stamp.position = Vector2(12, -2)
					slot_ctrl.add_child(stamp)

		# 6. Pocket Watch Timer (right of divider)
		var watch := TextureRect.new()
		watch.texture = watch_tex
		watch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		watch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		watch.size = Vector2(25, 25)
		watch.position = Vector2(142.0, 20.0)
		card_pivot.add_child(watch)

		var time_lbl := Label.new()
		time_lbl.text = ord.time
		time_lbl.position = Vector2(168.0, 26.0)
		time_lbl.add_theme_font_size_override("font_size", 8)
		time_lbl.add_theme_color_override("font_color", Color(0.38, 0.28, 0.18, 1))
		time_lbl.add_theme_color_override("font_shadow_color", Color(1, 0.98, 0.92, 0.7))
		time_lbl.add_theme_constant_override("shadow_offset_x", 1)
		time_lbl.add_theme_constant_override("shadow_offset_y", 1)
		card_pivot.add_child(time_lbl)

		# 7. Deliver Ribbon Button (Across Bottom Center)
		var ribbon_btn := TextureButton.new()
		ribbon_btn.texture_normal = ribbon_btn_tex
		ribbon_btn.ignore_texture_size = true
		ribbon_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		var r_w := 105.0
		var r_h := 24.0
		ribbon_btn.size = Vector2(r_w, r_h)
		ribbon_btn.position = Vector2(card_w * 0.5 - r_w * 0.5, 60.0)
		if not ord.can_deliver:
			ribbon_btn.modulate = Color(0.70, 0.65, 0.60, 0.65)
		card_pivot.add_child(ribbon_btn)

		var deliv_lbl := Label.new()
		deliv_lbl.text = "Deliver"
		deliv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		deliv_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		deliv_lbl.size = Vector2(r_w, r_h)
		deliv_lbl.add_theme_font_size_override("font_size", 9)
		deliv_lbl.add_theme_color_override("font_color", Color(1.0, 0.97, 0.90))
		deliv_lbl.add_theme_color_override("font_shadow_color", Color(0.22, 0.05, 0.05, 0.95))
		deliv_lbl.add_theme_constant_override("shadow_offset_x", 1)
		deliv_lbl.add_theme_constant_override("shadow_offset_y", 1)
		ribbon_btn.add_child(deliv_lbl)

	for i in range(10):
		await process_frame

	var vp = root.get_viewport()
	if vp != null and vp.get_texture() != null:
		var img = vp.get_texture().get_image()
		if img != null:
			var dest_path = "/home/el3laimy/.gemini/antigravity/brain/c18f39df-35cc-4bc9-9225-9e72dac391af/exact_reference_orders_render.png"
			img.save_png(dest_path)
			print("✓ Exact reference render saved to: " + dest_path)

	quit(0)
