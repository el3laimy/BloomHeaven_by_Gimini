extends SceneTree

## Standalone Visual Test for Completely Redesigned Orders Rail & Postcards

func _init() -> void:
	print("--- Composing Completely Redesigned Orders Rail ---")
	var root_ctrl = Control.new()
	root_ctrl.name = "OrdersRedesignTestRoot"
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.size = Vector2(1280, 720)
	root.add_child(root_ctrl)

	# 1. Darkened garden ambience
	var bg_dim = ColorRect.new()
	bg_dim.color = Color(0.08, 0.12, 0.09, 0.95)
	bg_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.add_child(bg_dim)

	# 2. Main Corkboard Container
	var board_box = Control.new()
	board_box.name = "OrdersCorkboard"
	var board_w = 290.0
	var board_h = 430.0
	board_box.size = Vector2(board_w, board_h)
	board_box.position = Vector2(1280.0 - board_w - 18.0, 18.0)
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
	close_btn.position = Vector2(board_w - 34.0, 16.0)
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

	# 6. Scroll Area for Postcard Tickets (Strictly positioned over the cork texture)
	# Cork is between x=38 and x=252 in the 290px frame
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(36.0, 52.0)
	scroll.size = Vector2(218.0, 355.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var v_bar = scroll.get_v_scroll_bar()
	if v_bar:
		var grabber_style = StyleBoxFlat.new()
		grabber_style.bg_color = Color(0.65, 0.50, 0.28, 0.8)
		grabber_style.set_corner_radius_all(3)
		v_bar.add_theme_stylebox_override("grabber", grabber_style)
		v_bar.custom_minimum_size = Vector2(3, 0)
	board_box.add_child(scroll)

	var tickets_vbox = VBoxContainer.new()
	tickets_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tickets_vbox.add_theme_constant_override("separation", 12)
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
			"dialogue": "Fresh velvety roses for my perfume.",
			"portrait": "res://assets/ui/orders/portrait_harris.png",
			"reqs": [{"icon": "🌹", "count": 2, "have": 2, "ready": true}],
			"time": "1m 18s",
			"can_deliver": true
		},
		{
			"id": "order_2",
			"name": "Madame Aurelia",
			"dialogue": "Bring 1 Ethereal Lumina bouquet!",
			"portrait": "res://assets/ui/orders/portrait_emma.png",
			"reqs": [{"icon": "💐", "count": 1, "have": 0, "ready": false}],
			"time": "1m 28s",
			"can_deliver": false
		}
	]

	# Clean card container using MarginContainer and proper VBox layout!
	var card_w = 214.0
	var card_h = 166.0

	for ord in sample_orders:
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(card_w, card_h)

		# Stylebox with warm parchment background & soft border
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.97, 0.94, 0.86, 0.98)
		card_style.set_border_width_all(2)
		card_style.border_color = Color(0.76, 0.62, 0.44, 0.9)
		card_style.set_corner_radius_all(8)
		card_style.shadow_color = Color(0.12, 0.08, 0.04, 0.35)
		card_style.shadow_size = 4
		card_style.content_margin_left = 8
		card_style.content_margin_right = 8
		card_style.content_margin_top = 6
		card_style.content_margin_bottom = 6
		card.add_theme_stylebox_override("panel", card_style)

		var main_vbox = VBoxContainer.new()
		main_vbox.add_theme_constant_override("separation", 5)
		card.add_child(main_vbox)

		# Header Row: Portrait + Name + Wax Seal
		var top_hbox = HBoxContainer.new()
		top_hbox.add_theme_constant_override("separation", 6)
		main_vbox.add_child(top_hbox)

		# Portrait in slot frame
		var port_box = Control.new()
		port_box.custom_minimum_size = Vector2(34, 34)
		var p_slot = TextureRect.new()
		p_slot.texture = slot_tex
		p_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p_slot.size = Vector2(34, 34)
		port_box.add_child(p_slot)

		if ResourceLoader.exists(ord.portrait):
			var port_img = TextureRect.new()
			port_img.texture = load(ord.portrait)
			port_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			port_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			port_img.size = Vector2(24, 24)
			port_img.position = Vector2(5, 5)
			port_box.add_child(port_img)
		top_hbox.add_child(port_box)

		# Customer Name + Dialogue in VBox
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 1)
		top_hbox.add_child(text_vbox)

		var name_lbl = Label.new()
		name_lbl.text = ord.name
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color(0.25, 0.15, 0.08, 1))
		name_lbl.add_theme_color_override("font_shadow_color", Color(1, 0.95, 0.85, 0.8))
		name_lbl.add_theme_constant_override("shadow_offset_x", 1)
		name_lbl.add_theme_constant_override("shadow_offset_y", 1)
		text_vbox.add_child(name_lbl)

		var quote_lbl = Label.new()
		quote_lbl.text = "\"%s\"" % ord.dialogue
		quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		quote_lbl.add_theme_font_size_override("font_size", 8)
		quote_lbl.add_theme_color_override("font_color", Color(0.44, 0.34, 0.24, 1))
		text_vbox.add_child(quote_lbl)

		# Wax Seal on top right
		var wax = TextureRect.new()
		wax.texture = wax_seal_tex
		wax.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wax.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		wax.custom_minimum_size = Vector2(24, 24)
		top_hbox.add_child(wax)

		# Separator
		var sep = HSeparator.new()
		var sep_style = StyleBoxFlat.new()
		sep_style.bg_color = Color(0.75, 0.65, 0.50, 0.4)
		sep_style.content_margin_top = 1
		sep_style.content_margin_bottom = 1
		sep.add_theme_stylebox_override("separator", sep_style)
		main_vbox.add_child(sep)

		# Middle Row: Required Flowers & Deliver Ribbon Button
		var mid_hbox = HBoxContainer.new()
		mid_hbox.add_theme_constant_override("separation", 8)
		main_vbox.add_child(mid_hbox)

		var reqs_hbox = HBoxContainer.new()
		reqs_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reqs_hbox.add_theme_constant_override("separation", 6)
		mid_hbox.add_child(reqs_hbox)

		for req in ord.reqs:
			var req_box = Control.new()
			req_box.custom_minimum_size = Vector2(40, 40)

			var r_slot = TextureRect.new()
			r_slot.texture = slot_tex
			r_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			r_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			r_slot.size = Vector2(40, 40)
			req_box.add_child(r_slot)

			var r_icon = Label.new()
			r_icon.text = req.icon
			r_icon.add_theme_font_size_override("font_size", 16)
			r_icon.position = Vector2(4, 5)
			req_box.add_child(r_icon)

			var r_count = Label.new()
			r_count.text = "%d/%d" % [req.have, req.count]
			r_count.position = Vector2(14, 21)
			r_count.add_theme_font_size_override("font_size", 9)
			r_count.add_theme_color_override("font_color", Color(0.98, 0.95, 0.85) if req.ready else Color(0.92, 0.45, 0.35))
			r_count.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 0.95))
			r_count.add_theme_constant_override("shadow_offset_x", 1)
			r_count.add_theme_constant_override("shadow_offset_y", 1)
			req_box.add_child(r_count)

			# Emerald Stamp if fulfilled
			if req.ready:
				var check_stamp = TextureRect.new()
				check_stamp.texture = stamp_check_tex
				check_stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				check_stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				check_stamp.size = Vector2(24, 24)
				check_stamp.position = Vector2(18, -4)
				req_box.add_child(check_stamp)

			reqs_hbox.add_child(req_box)

		# Deliver Ribbon Button
		var deliv_box = Control.new()
		deliv_box.custom_minimum_size = Vector2(88, 30)
		var deliver_btn = TextureButton.new()
		deliver_btn.texture_normal = ribbon_btn_tex
		deliver_btn.ignore_texture_size = true
		deliver_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		deliver_btn.size = Vector2(88, 30)
		if not ord.can_deliver:
			deliver_btn.modulate = Color(0.65, 0.65, 0.65, 0.6)
		deliv_box.add_child(deliver_btn)

		var deliv_lbl = Label.new()
		deliv_lbl.text = "Deliver"
		deliv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		deliv_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		deliv_lbl.size = Vector2(88, 30)
		deliv_lbl.add_theme_font_size_override("font_size", 10)
		deliv_lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
		deliv_lbl.add_theme_color_override("font_shadow_color", Color(0.25, 0.05, 0.05, 0.95))
		deliv_lbl.add_theme_constant_override("shadow_offset_x", 1)
		deliv_lbl.add_theme_constant_override("shadow_offset_y", 1)
		deliver_btn.add_child(deliv_lbl)
		mid_hbox.add_child(deliv_box)

		# Bottom Row: Pocket Watch Timer + Patience (Clean, subtle, authentic!)
		var bot_hbox = HBoxContainer.new()
		bot_hbox.add_theme_constant_override("separation", 6)
		main_vbox.add_child(bot_hbox)

		var watch = TextureRect.new()
		watch.texture = watch_tex
		watch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		watch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		watch.custom_minimum_size = Vector2(18, 18)
		bot_hbox.add_child(watch)

		var time_lbl = Label.new()
		time_lbl.text = ord.time
		time_lbl.add_theme_font_size_override("font_size", 9)
		time_lbl.add_theme_color_override("font_color", Color(0.40, 0.30, 0.20, 1))
		bot_hbox.add_child(time_lbl)

		var p_bar = ProgressBar.new()
		p_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p_bar.custom_minimum_size = Vector2(0, 5)
		p_bar.show_percentage = false
		p_bar.value = 85.0
		var bar_fill = StyleBoxFlat.new()
		bar_fill.bg_color = Color(0.55, 0.70, 0.35, 0.9)
		bar_fill.set_corner_radius_all(2)
		p_bar.add_theme_stylebox_override("fill", bar_fill)
		var bar_bg = StyleBoxFlat.new()
		bar_bg.bg_color = Color(0.3, 0.25, 0.2, 0.25)
		bar_bg.set_corner_radius_all(2)
		p_bar.add_theme_stylebox_override("background", bar_bg)
		bot_hbox.add_child(p_bar)

		tickets_vbox.add_child(card)

	for i in range(10):
		await process_frame

	var vp = root.get_viewport()
	if vp != null and vp.get_texture() != null:
		var img = vp.get_texture().get_image()
		if img != null:
			var dest_path = "/home/el3laimy/.gemini/antigravity/brain/c18f39df-35cc-4bc9-9225-9e72dac391af/customer_orders_redesign_render.png"
			img.save_png(dest_path)
			print("✓ Redesign render saved to: " + dest_path)

	quit(0)
