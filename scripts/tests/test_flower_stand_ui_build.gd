extends SceneTree

## Standalone Visual Test for Batch 1 Flower Stand UI - Iteration 2 (Refined Aesthetics)

func _init() -> void:
	print("--- Composing Refined Flower Stand UI ---")
	var root_ctrl = Control.new()
	root_ctrl.name = "FlowerStandTestRoot"
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.size = Vector2(1280, 720)
	root.add_child(root_ctrl)

	# 1. Background game view simulation (darkened garden ambience with vignette)
	var bg_dim = ColorRect.new()
	bg_dim.color = Color(0.06, 0.08, 0.06, 0.88)
	bg_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.add_child(bg_dim)

	# 2. Main Stand Container (centered)
	var stand_box = Control.new()
	stand_box.name = "StandBox"
	var stand_w = 780.0
	var stand_h = 620.0
	stand_box.size = Vector2(stand_w, stand_h)
	stand_box.position = Vector2((1280.0 - stand_w) / 2.0, (720.0 - stand_h) / 2.0 + 24.0)
	root_ctrl.add_child(stand_box)

	# 3. Wooden Stand Frame Background
	var stand_bg = TextureRect.new()
	stand_bg.name = "StandBg"
	stand_bg.texture = load("res://assets/ui/flower_stand/ui_flower_stand_bg.png")
	stand_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stand_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stand_bg.size = Vector2(stand_w, stand_h)
	stand_box.add_child(stand_bg)

	# 4. Awning Canopy (Overhanging Header)
	var awning = TextureRect.new()
	awning.name = "Awning"
	awning.texture = load("res://assets/ui/flower_stand/ui_awning_canopy.png")
	awning.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	awning.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var awning_w = 804.0
	var awning_h = awning_w * (654.0 / 2127.0)
	awning.size = Vector2(awning_w, awning_h)
	awning.position = Vector2(-12.0, -88.0)
	stand_box.add_child(awning)

	# 5. Dynamic Title on Hanging Wooden Signboard
	var title_lbl = Label.new()
	title_lbl.text = "The Cottage Flower Stand"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.98, 0.94, 0.82))
	title_lbl.add_theme_color_override("font_shadow_color", Color(0.16, 0.10, 0.04, 0.95))
	title_lbl.add_theme_constant_override("shadow_offset_x", 1)
	title_lbl.add_theme_constant_override("shadow_offset_y", 2)
	title_lbl.size = Vector2(awning_w * 0.35, awning_h * 0.26)
	title_lbl.position = Vector2(awning_w * 0.325, awning_h * 0.69)
	awning.add_child(title_lbl)

	# 6. Close Button (Styled as rustic brass/wood token)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.position = Vector2(stand_w - 38.0, -66.0)
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.24, 0.16, 0.10, 0.92)
	close_style.border_color = Color(0.85, 0.72, 0.35, 0.95)
	close_style.set_border_width_all(2)
	close_style.set_corner_radius_all(16)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_style)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	close_btn.add_theme_font_size_override("font_size", 14)
	stand_box.add_child(close_btn)

	# 7. Scroll Area for Flower Crates (On the shelves & counter)
	var scroll = ScrollContainer.new()
	scroll.name = "CrateScroll"
	scroll.position = Vector2(96.0, 126.0)
	scroll.size = Vector2(588.0, 278.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	# Clean rustic custom scrollbar styling
	var v_scroll = scroll.get_v_scroll_bar()
	if v_scroll:
		var grabber_style = StyleBoxFlat.new()
		grabber_style.bg_color = Color(0.65, 0.50, 0.28, 0.8)
		grabber_style.set_corner_radius_all(4)
		var track_style = StyleBoxFlat.new()
		track_style.bg_color = Color(0.15, 0.10, 0.06, 0.4)
		track_style.set_corner_radius_all(4)
		v_scroll.add_theme_stylebox_override("grabber", grabber_style)
		v_scroll.add_theme_stylebox_override("scroll", track_style)
		v_scroll.custom_minimum_size = Vector2(8, 0)
	stand_box.add_child(scroll)

	var grid = GridContainer.new()
	grid.name = "CrateGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	# Sample flowers to display in crates
	var sample_items = [
		{"id": "rose", "name": "Crimson Rose", "count": 5, "price": 10, "icon": "🌹"},
		{"id": "daisy", "name": "Sunny Daisy", "count": 8, "price": 8, "icon": "🌼"},
		{"id": "lavender", "name": "Lavender", "count": 3, "price": 12, "icon": "💜"},
		{"id": "tulip", "name": "Pastel Tulip", "count": 2, "price": 15, "icon": "🌷"},
		{"id": "blushbell", "name": "Blushbell", "count": 1, "price": 35, "icon": "🌸"},
		{"id": "sunburst_daisy", "name": "Sunburst Daisy", "count": 0, "price": 30, "icon": "🌻"},
	]

	var crate_tex = load("res://assets/ui/flower_stand/ui_wooden_crate_slot.png")
	var tag_tex = load("res://assets/ui/flower_stand/ui_chalk_price_tag.png")
	var btn_wood_norm = load("res://assets/ui/flower_stand/ui_btn_sell_wood_normal.png")
	var btn_wood_press = load("res://assets/ui/flower_stand/ui_btn_sell_wood_pressed.png")
	var btn_brass_tex = load("res://assets/ui/flower_stand/ui_btn_sell_all_brass.png")

	for item in sample_items:
		var crate = Control.new()
		crate.custom_minimum_size = Vector2(276, 122)

		# Crate Graphic
		var c_bg = TextureRect.new()
		c_bg.texture = crate_tex
		c_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		c_bg.size = Vector2(276, 122)
		if item.count == 0:
			c_bg.modulate = Color(0.55, 0.55, 0.55, 0.70)
		crate.add_child(c_bg)

		# Flower Icon (nestled on the straw bed)
		var f_lbl = Label.new()
		f_lbl.text = item.icon
		f_lbl.add_theme_font_size_override("font_size", 26)
		f_lbl.position = Vector2(24, 38)
		crate.add_child(f_lbl)

		# Flower Name with dark outline
		var name_lbl = Label.new()
		name_lbl.text = item.name
		name_lbl.position = Vector2(68, 30)
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88) if item.count > 0 else Color(0.65, 0.60, 0.55))
		name_lbl.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 1.0))
		name_lbl.add_theme_constant_override("shadow_offset_x", 1)
		name_lbl.add_theme_constant_override("shadow_offset_y", 1)
		name_lbl.add_theme_color_override("font_outline_color", Color(0.15, 0.10, 0.05, 0.9))
		name_lbl.add_theme_constant_override("outline_size", 2)
		crate.add_child(name_lbl)

		# Count Badge
		var count_lbl = Label.new()
		count_lbl.text = "In Stock: %d" % item.count if item.count > 0 else "Out of Stock"
		count_lbl.position = Vector2(68, 48)
		count_lbl.add_theme_font_size_override("font_size", 10)
		count_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40) if item.count > 0 else Color(0.55, 0.50, 0.45))
		count_lbl.add_theme_color_override("font_shadow_color", Color(0.10, 0.06, 0.02, 0.9))
		count_lbl.add_theme_constant_override("shadow_offset_x", 1)
		count_lbl.add_theme_constant_override("shadow_offset_y", 1)
		crate.add_child(count_lbl)

		# Chalk Price Tag
		var tag = TextureRect.new()
		tag.texture = tag_tex
		tag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tag.size = Vector2(68, 32)
		tag.position = Vector2(192, 24)
		crate.add_child(tag)

		var price_val = Label.new()
		price_val.text = "%d🪙" % item.price
		price_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price_val.size = Vector2(68, 32)
		price_val.add_theme_font_size_override("font_size", 11)
		price_val.add_theme_color_override("font_color", Color(1.0, 0.96, 0.70))
		price_val.add_theme_color_override("font_shadow_color", Color(0.08, 0.05, 0.02, 0.95))
		price_val.add_theme_constant_override("shadow_offset_x", 1)
		price_val.add_theme_constant_override("shadow_offset_y", 1)
		tag.add_child(price_val)

		# Buttons (on the front rail)
		if item.count > 0:
			# Sell 1 Button
			var s1_btn = TextureButton.new()
			s1_btn.texture_normal = btn_wood_norm
			s1_btn.texture_pressed = btn_wood_press
			s1_btn.ignore_texture_size = true
			s1_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			s1_btn.size = Vector2(68, 30)
			s1_btn.position = Vector2(128, 74)
			crate.add_child(s1_btn)

			var s1_lbl = Label.new()
			s1_lbl.text = "Sell 1"
			s1_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			s1_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			s1_lbl.size = Vector2(68, 30)
			s1_lbl.add_theme_font_size_override("font_size", 10)
			s1_lbl.add_theme_color_override("font_color", Color(0.98, 0.94, 0.85))
			s1_lbl.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 1.0))
			s1_lbl.add_theme_constant_override("shadow_offset_x", 1)
			s1_lbl.add_theme_constant_override("shadow_offset_y", 1)
			s1_btn.add_child(s1_lbl)

			if item.count > 1:
				# Sell All Button
				var sa_btn = TextureButton.new()
				sa_btn.texture_normal = btn_brass_tex
				sa_btn.ignore_texture_size = true
				sa_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
				sa_btn.size = Vector2(62, 30)
				sa_btn.position = Vector2(200, 74)
				crate.add_child(sa_btn)

				var sa_lbl = Label.new()
				sa_lbl.text = "All"
				sa_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				sa_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				sa_lbl.size = Vector2(62, 30)
				sa_lbl.add_theme_font_size_override("font_size", 10)
				sa_lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.55))
				sa_lbl.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 1.0))
				sa_lbl.add_theme_constant_override("shadow_offset_x", 1)
				sa_lbl.add_theme_constant_override("shadow_offset_y", 1)
				sa_btn.add_child(sa_lbl)

		grid.add_child(crate)

	# 8. Counter Base / Grand Footer
	var footer_box = Control.new()
	footer_box.position = Vector2(80, 436)
	footer_box.size = Vector2(620, 140)
	stand_box.add_child(footer_box)

	# Coin Drawer Graphic
	var coin_drawer = TextureRect.new()
	coin_drawer.texture = load("res://assets/ui/flower_stand/ui_coin_drawer_icon.png")
	coin_drawer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_drawer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_drawer.size = Vector2(98, 95)
	coin_drawer.position = Vector2(20, 16)
	footer_box.add_child(coin_drawer)

	# Grand Sell All Harvest Button
	var grand_btn = TextureButton.new()
	grand_btn.texture_normal = load("res://assets/ui/flower_stand/ui_btn_sell_entire_harvest.png")
	grand_btn.ignore_texture_size = true
	grand_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	grand_btn.size = Vector2(460, 64)
	grand_btn.position = Vector2(130, 32)
	footer_box.add_child(grand_btn)

	var grand_lbl = Label.new()
	grand_lbl.text = "💰 Quick Sell All Harvested  •  19 Flowers ➔ +205 Coins"
	grand_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grand_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grand_lbl.size = Vector2(460, 64)
	grand_lbl.add_theme_font_size_override("font_size", 12)
	grand_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.70))
	grand_lbl.add_theme_color_override("font_shadow_color", Color(0.18, 0.10, 0.04, 1.0))
	grand_lbl.add_theme_constant_override("shadow_offset_x", 1)
	grand_lbl.add_theme_constant_override("shadow_offset_y", 2)
	grand_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 0.8))
	grand_lbl.add_theme_constant_override("outline_size", 2)
	grand_btn.add_child(grand_lbl)

	for i in range(10):
		await process_frame

	var vp = root.get_viewport()
	if vp != null and vp.get_texture() != null:
		var img = vp.get_texture().get_image()
		if img != null:
			var dest_path = "/home/el3laimy/.gemini/antigravity/brain/c18f39df-35cc-4bc9-9225-9e72dac391af/flower_stand_refined_render.png"
			img.save_png(dest_path)
			print("✓ Refined render saved to: " + dest_path)

	quit(0)
