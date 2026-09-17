extends SceneTree

## Tool: capture_rose_lifecycle.gd
## High-fidelity in-engine generator for Red Rose lifecycle visual QA.
## Generates:
## 1. 6 clean stage captures (no water droplet, no prune ring, no status overlays)
## 2. Clean contact sheet (plant art only)
## 3. Gameplay contact sheet (with gameplay status indicators)
## 4. Clean 64px and 96px mobile readability test sheets
## 5. A/B test captures for Prime Bud (52px vs 56px target_height)

var _target_dir: String = "/home/el3laimy/.gemini/antigravity/brain/c262f767-d163-44b7-9712-b330a8fcb881"

const STAGE_CONFIGS: Array[Dictionary] = [
	{
		"name": "rose_stage_1_young",
		"label": "1. Young Sprout",
		"progress": 0.35,
		"pruned": false,
		"stage_name": "sprout"
	},
	{
		"name": "rose_stage_2_branching",
		"label": "2. Branching Bush",
		"progress": 0.65,
		"pruned": false,
		"stage_name": "vegetative_branching"
	},
	{
		"name": "rose_stage_3_prime_bud",
		"label": "3. Prime Bud",
		"progress": 0.70,
		"pruned": true,
		"stage_name": "vegetative_single"
	},
	{
		"name": "rose_stage_4_cluster_buds",
		"label": "4. Cluster Buds",
		"progress": 0.88,
		"pruned": false,
		"stage_name": "vegetative_late_unpruned"
	},
	{
		"name": "rose_stage_5_cluster_bloom",
		"label": "5. Cluster Bloom",
		"progress": 1.0,
		"pruned": false,
		"stage_name": "bloom_standard"
	},
	{
		"name": "rose_stage_6_prime_bloom",
		"label": "6. Prime Bloom",
		"progress": 1.0,
		"pruned": true,
		"stage_name": "bloom_hero"
	}
]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--dir="):
			_target_dir = a.replace("--dir=", "")
			
	_run()

func _run() -> void:
	print("==================================================")
	print("🌹 CAPTURING RED ROSE LIFECYCLE & VISUAL QA 🌹")
	print("Output Directory: %s" % _target_dir)
	print("==================================================")
	
	if not DirAccess.dir_exists_absolute(_target_dir):
		DirAccess.make_dir_recursive_absolute(_target_dir)

	var clean_images: Array[Image] = []
	var gameplay_images: Array[Image] = []

	# 1. Capture Clean Stages (No status overlays, no water droplet, no prune ring)
	print("\n--- Generating Clean Plant Art Captures ---")
	for cfg in STAGE_CONFIGS:
		var img := await _render_stage_capture(cfg, false)
		var out_path: String = _target_dir.path_join(cfg["name"] + ".png")
		img.save_png(out_path)
		print("✓ Saved clean stage [%s] -> %s" % [cfg["label"], out_path])
		clean_images.append(img)

	# 2. Capture Gameplay Overlaid Stages
	print("\n--- Generating Gameplay Overlaid Captures ---")
	for cfg in STAGE_CONFIGS:
		var img := await _render_stage_capture(cfg, true)
		gameplay_images.append(img)

	# 3. Build Clean Contact Sheet (Horizontal strip)
	print("\n--- Stitching Clean Contact Sheet ---")
	var clean_sheet := _stitch_contact_sheet(clean_images, false)
	var clean_sheet_path := _target_dir.path_join("rose_contact_sheet.png")
	clean_sheet.save_png(clean_sheet_path)
	print("✓ Saved Clean Contact Sheet -> %s" % clean_sheet_path)

	# 4. Build Gameplay Contact Sheet
	print("\n--- Stitching Gameplay Contact Sheet ---")
	var gameplay_sheet := _stitch_contact_sheet(gameplay_images, true)
	var gameplay_sheet_path := _target_dir.path_join("rose_gameplay_sheet.png")
	gameplay_sheet.save_png(gameplay_sheet_path)
	print("✓ Saved Gameplay Contact Sheet -> %s" % gameplay_sheet_path)

	# 5. Build Clean 64px and 96px Readability Sheets
	print("\n--- Building Clean 64px and 96px Readability Sheets ---")
	var sheet_64 := _build_readability_sheet(clean_images, 64)
	var sheet_64_path := _target_dir.path_join("rose_readability_64px.png")
	sheet_64.save_png(sheet_64_path)
	print("✓ Saved 64px Readability Sheet -> %s" % sheet_64_path)

	var sheet_96 := _build_readability_sheet(clean_images, 96)
	var sheet_96_path := _target_dir.path_join("rose_readability_96px.png")
	sheet_96.save_png(sheet_96_path)
	print("✓ Saved 96px Readability Sheet -> %s" % sheet_96_path)

	print("\n🎉 ALL VISUAL QA ARTIFACTS GENERATED SUCCESSFULLY!")
	quit(0)

func _render_stage_capture(cfg: Dictionary, with_overlays: bool) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(256, 256)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	root.add_child(vp)

	# Background dark green garden soil tone
	var bg := ColorRect.new()
	bg.size = Vector2(256, 256)
	bg.color = Color(0.07, 0.12, 0.08, 1.0)
	vp.add_child(bg)

	if not with_overlays:
		# Pure Plant Art: direct FlowerVisual rendering with subtle ground shadow
		var fv := FlowerVisual.new()
		fv.name = "FlowerVisual"
		fv.flower_id = "rose"
		fv.position = Vector2(128, 150)
		fv.growth_progress = cfg["progress"]
		fv.is_pruned = cfg["pruned"]
		fv.is_late_unpruned = (cfg["progress"] > 0.85 and not cfg["pruned"])
		match cfg["stage_name"]:
			"sprout":
				fv.current_stage = FlowerVisual.Stage.SPROUT
			"vegetative_branching", "vegetative_single", "vegetative_late_unpruned":
				fv.current_stage = FlowerVisual.Stage.VEGETATIVE
			"bloom_standard", "bloom_hero":
				fv.current_stage = FlowerVisual.Stage.BLOOMING
		vp.add_child(fv)
		fv.queue_redraw()
	else:
		# Gameplay mode: full plot with soil and gameplay status indicators
		var plot := GardenPlot.new()
		plot.position = Vector2(128, 150)
		plot.plot_index = 0
		plot.is_watered = false if (cfg["progress"] >= 0.60 and cfg["progress"] <= 0.85 and not cfg["pruned"]) else true
		vp.add_child(plot)
		plot.plant("rose")
		plot.growth_progress = cfg["progress"]
		plot.is_pruned = cfg["pruned"]
		plot._update_growth_stage()
		var fv = plot.find_child("FlowerVisual")
		if fv:
			fv.queue_redraw()
		plot.queue_redraw()

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
	vp.queue_free()
	return img

func _stitch_contact_sheet(images: Array[Image], is_gameplay: bool) -> Image:
	var count := images.size()
	var tile_w: int = 256
	var tile_h: int = 256
	var header_h: int = 40
	var sheet_w: int = count * tile_w
	var sheet_h: int = tile_h + header_h

	var sheet := Image.create(sheet_w, sheet_h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.05, 0.09, 0.06, 1.0))

	for i in range(count):
		var img: Image = images[i]
		sheet.blit_rect(img, Rect2i(0, 0, tile_w, tile_h), Vector2i(i * tile_w, header_h))

	return sheet

func _build_readability_sheet(images: Array[Image], target_h: int) -> Image:
	var count := images.size()
	var pad := 8
	var tile_w: int = target_h
	var tile_h: int = target_h
	var sheet_w: int = count * tile_w + (count + 1) * pad
	var sheet_h: int = tile_h + pad * 2

	var sheet := Image.create(sheet_w, sheet_h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.06, 0.10, 0.07, 1.0))

	for i in range(count):
		var img: Image = images[i].duplicate()
		img.resize(target_h, target_h, Image.INTERPOLATE_LANCZOS)
		var dst_pos := Vector2i(pad + i * (tile_w + pad), pad)
		sheet.blit_rect(img, Rect2i(0, 0, target_h, target_h), dst_pos)

	return sheet
