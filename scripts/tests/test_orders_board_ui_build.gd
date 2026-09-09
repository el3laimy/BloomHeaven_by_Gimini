extends SceneTree

## Standalone Visual Test for Batch 2 Customer Orders - Postcard Layout v3

func _init() -> void:
	print("--- Composing Postcard Layout v3 ---")
	var root_ctrl = Control.new()
	root_ctrl.name = "OrdersTestRoot"
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.size = Vector2(1280, 720)
	root.add_child(root_ctrl)

	# 1. Darkened garden ambience
	var bg_dim = ColorRect.new()
	bg_dim.color = Color(0.08, 0.12, 0.09, 0.95)
	bg_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.add_child(bg_dim)

	# 2. Main Corkboard Container on the Right Rail
	var board_box = Control.new()
	board_box.name = "OrdersCorkboard"
	var board_w = 304.0
	var board_h = 440.0
	board_box.size = Vector2(board_w, board_h)
	board_box.position = Vector2(1280.0 - board_w - 14.0, 14.0)
	root_ctrl.add_child(board_box)

	# 3. Corkboard Frame Texture
	var board_bg = TextureRect.new()
	board_bg.name = "BoardBg"
	board_bg.texture = load("res://assets/ui/customer_orders/ui_orders_corkboard_rail.png")
	board_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	board_bg.size = Vector2(board_w, board_h)
	board_box.add_child(board_bg)

	# 4. Header Title on Top Carved Wood Beam
	var header_lbl = Label.new()
	header_lbl.text = "Customer Orders"
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_lbl.add_theme_font_size_override("font_size", 12)
	header_lbl.add_theme_color_override("font_color", Color(0.96, 0.90, 0.78))
	header_lbl.add_theme_color_override("font_shadow_color", Color(0.18, 0.12, 0.06, 0.95))
	header_lbl.add_theme_constant_override("shadow_offset_x", 1)
	header_lbl.add_theme_constant_override("shadow_offset_y", 1)
	header_lbl.size = Vector2(board_w, 32)
	header_lbl.position = Vector2(0, 14)
	board_box.add_child(header_lbl)

	# 5. Close Button at Top Right Corner
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(22, 22)
	close_btn.position = Vector2(board_w - 36.0, 16.0)
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.25, 0.15, 0.08, 0.9)
	close_style.border_color = Color(0.85, 0.72, 0.35, 0.95)
	close_style.set_border_width_all(1)
	close_style.set_corner_radius_all(11)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_style)
	close_btn.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	close_btn.add_theme_font_size_override("font_size", 10)
	board_box.add_child(close_btn)

	# 6. Scroll Area for Postcard Tickets
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20.0, 52.0)
	scroll.size = Vector2(264.0, 368.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var v_bar = scroll.get_v_scroll_bar()
	if v_bar:
		var grabber_style = StyleBoxFlat.new()
		grabber_style.bg_color = Color(0.65, 0.50, 0.28, 0.8)
		grabber_style.set_corner_radius_all(3)
		v_bar.add_theme_stylebox_override("grabber", grabber_style)
		v_bar.custom_minimum_size = Vector2(4, 0)
	board_box.add_child(scroll)

	var tickets_vbox = VBoxContainer.new()
	tickets_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tickets_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(tickets_vbox)

	# Load Textures
	var postcard_tex = load("res://assets/ui/customer_orders/ui_order_postcard_bg.png")
	var wax_seal_tex = load("res://assets/ui/customer_orders/ui_order_wax_seal.png")
	var watch_tex = load("res://assets/ui/customer_orders/ui_pocket_watch_timer.png")
	var slot_tex = load("res://assets/ui/customer_orders/ui_slot_flower_req.png")
	var stamp_check_tex = load("res://assets/ui/customer_orders/ui_stamp_checkmark.png")
	var ribbon_btn_tex = load("res://assets/ui/customer_orders/ui_btn_deliver_ribbon.png")

	var sample_orders = [
		{
			"id": "order_1",
			"name": "Lucian",
			"dialogue": "Fresh velvety crimson roses for my upcoming perfume.",
			"portrait": "res://assets/ui/orders/portrait_harris.png",
			"reqs": [{"icon": "🌹", "count": 2, "have": 2, "ready": true}],
			"time": "1m 18s",
			"patience_pct": 75.0,
			"can_deliver": true
		},
		{
			"id": "order_2",
			"name": "Madame Aurelia",
			"dialogue": "Bring 1 glowing Ethereal Lumina bouquet!",
			"portrait": "res://assets/ui/orders/portrait_emma.png",
			"reqs": [{"icon": "💐", "count": 1, "have": 0, "ready": false}],
			"time": "1m 28s",
			"patience_pct": 90.0,
			"can_deliver": false
		}
	]

	var pcard_w = 258.0
	var pcard_h = 164.0

	for ord in sample_orders:
		var card = Control.new()
		card.custom_minimum_size = Vector2(pcard_w, pcard_h)

		# 1. Postcard Parchment Background
		var p_bg = TextureRect.new()
		p_bg.texture = postcard_tex
		p_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p_bg.size = Vector2(pcard_w, pcard_h)
		card.add_child(p_bg)

		# 2. Wax Seal (Priority stamp at top-right over stamp mark)
		var wax_seal = TextureRect.new()
		wax_seal.texture = wax_seal_tex
		wax_seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wax_seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		wax_seal.size = Vector2(28, 28)
		wax_seal.position = Vector2(pcard_w - 40, 10)
		card.add_child(wax_seal)

		# 3. Portrait in Wooden Frame Slot (top left)
		var port_slot = TextureRect.new()
		port_slot.texture = slot_tex
		port_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		port_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		port_slot.size = Vector2(38, 38)
		port_slot.position = Vector2(12, 12)
		card.add_child(port_slot)

		if ResourceLoader.exists(ord.portrait):
			var port_img = TextureRect.new()
			port_img.texture = load(ord.portrait)
			port_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			port_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			port_img.size = Vector2(28, 28)
			port_img.position = Vector2(5, 5)
			port_slot.add_child(port_img)

		# 4. Customer Name & Dialogue
		var name_lbl = Label.new()
		name_lbl.text = ord.name
		name_lbl.position = Vector2(54, 12)
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color(0.24, 0.15, 0.08, 1))
		name_lbl.add_theme_color_override("font_shadow_color", Color(1, 0.95, 0.85, 0.8))
		name_lbl.add_theme_constant_override("shadow_offset_x", 1)
		name_lbl.add_theme_constant_override("shadow_offset_y", 1)
		card.add_child(name_lbl)

		var quote_lbl = Label.new()
		quote_lbl.text = "\"%s\"" % ord.dialogue
		quote_lbl.position = Vector2(54, 28)
		quote_lbl.size = Vector2(pcard_w - 100, 32)
		quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		quote_lbl.add_theme_font_size_override("font_size", 8)
		quote_lbl.add_theme_color_override("font_color", Color(0.42, 0.32, 0.22, 1))
		card.add_child(quote_lbl)

		# 5. Required Items (Left Side of Card)
		var reqs_box = HBoxContainer.new()
		reqs_box.position = Vector2(14, 62)
		reqs_box.size = Vector2(120, 48)
		reqs_box.add_theme_constant_override("separation", 6)
		card.add_child(reqs_box)

		for req in ord.reqs:
			var req_frame = Control.new()
			req_frame.custom_minimum_size = Vector2(44, 44)

			var r_slot = TextureRect.new()
			r_slot.texture = slot_tex
			r_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			r_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			r_slot.size = Vector2(44, 44)
			req_frame.add_child(r_slot)

			var r_icon = Label.new()
			r_icon.text = req.icon
			r_icon.add_theme_font_size_override("font_size", 18)
			r_icon.position = Vector2(4, 7)
			req_frame.add_child(r_icon)

			var r_count = Label.new()
			r_count.text = "%d/%d" % [req.have, req.count]
			r_count.position = Vector2(16, 23)
			r_count.add_theme_font_size_override("font_size", 9)
			r_count.add_theme_color_override("font_color", Color(0.98, 0.95, 0.85) if req.ready else Color(0.9, 0.4, 0.3))
			r_count.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 0.95))
			r_count.add_theme_constant_override("shadow_offset_x", 1)
			r_count.add_theme_constant_override("shadow_offset_y", 1)
			req_frame.add_child(r_count)

			if req.ready:
				var check_stamp = TextureRect.new()
				check_stamp.texture = stamp_check_tex
				check_stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				check_stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				check_stamp.size = Vector2(28, 28)
				check_stamp.position = Vector2(20, -6)
				req_frame.add_child(check_stamp)

			reqs_box.add_child(req_frame)

		# 6. Deliver Ribbon Button (Right Side, on the postcard address lines)
		var deliver_btn = TextureButton.new()
		deliver_btn.texture_normal = ribbon_btn_tex
		deliver_btn.ignore_texture_size = true
		deliver_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		deliver_btn.size = Vector2(104, 30)
		deliver_btn.position = Vector2(pcard_w - 116, 68)
		if not ord.can_deliver:
			deliver_btn.modulate = Color(0.65, 0.65, 0.65, 0.65)
		card.add_child(deliver_btn)

		var deliv_lbl = Label.new()
		deliv_lbl.text = "Deliver"
		deliv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		deliv_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		deliv_lbl.size = Vector2(104, 30)
		deliv_lbl.add_theme_font_size_override("font_size", 10)
		deliv_lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
		deliv_lbl.add_theme_color_override("font_shadow_color", Color(0.2, 0.05, 0.05, 0.95))
		deliv_lbl.add_theme_constant_override("shadow_offset_x", 1)
		deliv_lbl.add_theme_constant_override("shadow_offset_y", 1)
		deliver_btn.add_child(deliv_lbl)

		# 7. Bottom Row: Pocket Watch Timer + Patience Gauge
		var bot_row = HBoxContainer.new()
		bot_row.position = Vector2(14, 122)
		bot_row.size = Vector2(pcard_w - 28, 24)
		bot_row.add_theme_constant_override("separation", 6)
		card.add_child(bot_row)

		var watch = TextureRect.new()
		watch.texture = watch_tex
		watch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		watch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		watch.custom_minimum_size = Vector2(22, 22)
		bot_row.add_child(watch)

		var time_lbl = Label.new()
		time_lbl.text = ord.time
		time_lbl.add_theme_font_size_override("font_size", 9)
		time_lbl.add_theme_color_override("font_color", Color(0.35, 0.25, 0.15, 1))
		bot_row.add_child(time_lbl)

		var p_bar = ProgressBar.new()
		p_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p_bar.custom_minimum_size = Vector2(0, 6)
		p_bar.show_percentage = false
		p_bar.value = ord.patience_pct
		var bar_fill = StyleBoxFlat.new()
		bar_fill.bg_color = Color(0.35, 0.75, 0.40) if ord.patience_pct > 50 else Color(0.9, 0.7, 0.2)
		bar_fill.set_corner_radius_all(3)
		p_bar.add_theme_stylebox_override("fill", bar_fill)
		bot_row.add_child(p_bar)

		tickets_vbox.add_child(card)

	for i in range(10):
		await process_frame

	var vp = root.get_viewport()
	if vp != null and vp.get_texture() != null:
		var img = vp.get_texture().get_image()
		if img != null:
			var dest_path = "/home/el3laimy/.gemini/antigravity/brain/c18f39df-35cc-4bc9-9225-9e72dac391af/customer_orders_v3_render.png"
			img.save_png(dest_path)
			print("✓ Orders v3 render saved to: " + dest_path)

	quit(0)
