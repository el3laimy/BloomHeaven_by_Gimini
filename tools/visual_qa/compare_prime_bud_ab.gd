extends SceneTree

## Tool: compare_prime_bud_ab.gd
## Renders side-by-side visual A/B comparison for Prime Bud target_height:
## Panel 1: Branching Bush (target_height = 52.0px) - Baseline
## Panel 2: Prime Bud A   (target_height = 52.0px) - Current baseline (feels smaller)
## Panel 3: Prime Bud B   (target_height = 56.0px) - Proposed candidate (compensates for vertical silhouette)

var _out_path: String = "/home/el3laimy/.gemini/antigravity/brain/c262f767-d163-44b7-9712-b330a8fcb881/rose_prime_bud_ab_comparison.png"

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--out="):
			_out_path = a.replace("--out=", "")
	_run()

func _run() -> void:
	print("==================================================")
	print("🔍 GENERATING PRIME BUD A/B COMPARISON (52px vs 56px) 🔍")
	print("==================================================")

	var vp := SubViewport.new()
	vp.size = Vector2i(768, 256)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	root.add_child(vp)

	var bg := ColorRect.new()
	bg.size = Vector2(768, 256)
	bg.color = Color(0.07, 0.12, 0.08, 1.0)
	vp.add_child(bg)

	# 1. Branching Bush (x = 128)
	var p_branching := GardenPlot.new()
	p_branching.position = Vector2(128, 150)
	p_branching.is_watered = true
	vp.add_child(p_branching)
	p_branching.plant("rose")
	p_branching.growth_progress = 0.65
	p_branching.is_pruned = false
	p_branching._update_growth_stage()

	# 2. Prime Bud Condition A: 52px (x = 384)
	var p_bud_a := GardenPlot.new()
	p_bud_a.position = Vector2(384, 150)
	p_bud_a.is_watered = true
	vp.add_child(p_bud_a)
	p_bud_a.plant("rose")
	p_bud_a.growth_progress = 0.70
	p_bud_a.is_pruned = true
	var fv_a: FlowerVisual = p_bud_a.find_child("FlowerVisual") as FlowerVisual
	if fv_a:
		fv_a.is_pruned = true
	p_bud_a._update_growth_stage()

	# 3. Prime Bud Condition B: 56px (x = 640)
	var p_bud_b := GardenPlot.new()
	p_bud_b.position = Vector2(640, 150)
	p_bud_b.is_watered = true
	vp.add_child(p_bud_b)
	p_bud_b.plant("rose")
	p_bud_b.growth_progress = 0.70
	p_bud_b.is_pruned = true
	var fv_b: FlowerVisual = p_bud_b.find_child("FlowerVisual") as FlowerVisual
	if fv_b:
		fv_b.is_pruned = true
	p_bud_b._update_growth_stage()

	for i in range(4):
		await process_frame

	if fv_b:
		var spr: Sprite2D = fv_b.find_child("BranchSprite", true, false) as Sprite2D
		if spr:
			spr.scale = spr.scale * (56.0 / 52.0)

	# Add descriptive labels for each panel
	var ui_layer := Node2D.new()
	vp.add_child(ui_layer)

	var panel_labels := [
		{"text": "Branching Bush (52px)", "pos": Vector2(128, 20)},
		{"text": "Condition A: Prime Bud (52px)", "pos": Vector2(384, 20)},
		{"text": "Condition B: Prime Bud (56px)", "pos": Vector2(640, 20)}
	]

	for item in panel_labels:
		var lbl := Label.new()
		lbl.text = item["text"]
		lbl.position = item["pos"] - Vector2(120, 0)
		lbl.size = Vector2(240, 30)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82))
		ui_layer.add_child(lbl)

	for i in range(4):
		await process_frame

	var post_draw_fired := false
	var cb := func(): post_draw_fired = true
	RenderingServer.frame_post_draw.connect(cb, CONNECT_ONE_SHOT)
	for i in range(4):
		await process_frame
		if post_draw_fired:
			break

	var tex := vp.get_texture()
	var img := tex.get_image()

	var err := img.save_png(_out_path)
	if err == OK:
		print("🎉 Saved Prime Bud A/B Comparison to: %s" % _out_path)
		quit(0)
	else:
		printerr("❌ ERROR: Failed to save A/B comparison (code %d)" % err)
		quit(1)
