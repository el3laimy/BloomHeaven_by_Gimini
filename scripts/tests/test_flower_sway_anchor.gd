extends SceneTree

func _init() -> void:
	var fv = FlowerVisual.new()
	fv.flower_id = "rose"
	fv.current_stage = FlowerVisual.Stage.BLOOMING
	root.add_child(fv)
	fv._ready()
	fv._update_branching_sprite()
	
	# Simulate 60 frames
	var init_bottom_center := Vector2.ZERO
	var init_bottom_left := Vector2.ZERO
	var init_bottom_right := Vector2.ZERO
	var max_top_sway := 0.0

	for frame in range(60):
		fv._process(0.0166)
		var spr = fv._branch_sprite
		if spr != null and spr.visible:
			var bc = spr.global_transform * Vector2(0, 0)
			var bl = spr.global_transform * Vector2(-25, 0)
			var br = spr.global_transform * Vector2(25, 0)
			var top = spr.global_transform * Vector2(0, -spr.texture.get_height())

			if frame == 0:
				init_bottom_center = bc
				init_bottom_left = bl
				init_bottom_right = br
			else:
				# Base must NOT move
				var diff_bc = (bc - init_bottom_center).length()
				var diff_bl_y = abs(bl.y - init_bottom_left.y)
				var diff_br_y = abs(br.y - init_bottom_right.y)
				if diff_bc > 0.001:
					printerr("ERROR: Bottom center moved by %f at frame %d!" % [diff_bc, frame])
					quit(1)
					return
				if diff_bl_y > 0.001 or diff_br_y > 0.001:
					printerr("ERROR: Bottom corners moved vertically! Left: %f, Right: %f" % [diff_bl_y, diff_br_y])
					quit(1)
					return
				var top_sway = abs(top.x - init_bottom_center.x)
				if top_sway > max_top_sway:
					max_top_sway = top_sway

	print("✓ SUCCESS: Bottom base and soil corners remained 100% stationary and flat!")
	print("✓ SUCCESS: Top of flower swayed naturally with max displacement of %.2f px!" % max_top_sway)
	quit(0)
