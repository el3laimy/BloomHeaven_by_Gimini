class_name TestFlowerVisualCharacterization
extends SceneTree

## BloomHaven - Characterization Tests for Flower Visual Resolution
## Establishes baseline contracts for all Active CVP flowers across growth stages and pruning states
## prior to Data-Driven Art Pipeline refactoring.

const FlowerVisualScript := preload("res://scripts/flowers/flower_visual.gd")
const FlowerVisualStateResolverScript := preload("res://scripts/flowers/flower_visual_state_resolver.gd")

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	print("==================================================")
	print("🌸 RUNNING FLOWER VISUAL CHARACTERIZATION TESTS 🌸")
	print("==================================================")
	_run_characterization_suite()
	
	if _failed == 0:
		print("\n🎉 ALL %d CHARACTERIZATION TESTS PASSED CLEANLY!" % _passed)
		quit(0)
	else:
		printerr("\n❌ %d TESTS FAILED!" % _failed)
		quit(1)

func _assert_eq(actual, expected, msg: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: %s | Expected: %s, Got: %s" % [msg, str(expected), str(actual)])

func _assert_true(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: %s" % msg)

func _run_characterization_suite() -> void:
	_test_visual_state_resolver()
	_test_asset_resolver_diagnostics()
	_test_base_species_growth_textures()
	_test_pruning_differentiation()
	_test_target_heights_contract()
	_test_red_rose_lifecycle_visuals()
	_test_procedural_fallback_hybrids()
	_test_legacy_flower_mappings()
	_test_seed_contract()
	_test_procedural_fallback_gate()
	_test_sprite_flower_null_presentation()
	_test_runtime_metadata_fixture()

func _test_visual_state_resolver() -> void:
	print(">>> [TEST] FlowerVisualStateResolver...")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.SEED, false), "seed", "Stage SEED maps to 'seed'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.SPROUT, false), "sprout", "Stage SPROUT maps to 'sprout'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.VEGETATIVE, false, "", 0.60), "vegetative_branching", "Veg unpruned in prune window maps to 'vegetative_branching'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.VEGETATIVE, false, "", 0.86), "vegetative_late_unpruned", "Veg unpruned after prune window maps to 'vegetative_late_unpruned'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.VEGETATIVE, true, "", 0.65), "vegetative_single", "Veg pruned in window maps to 'vegetative_single'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.VEGETATIVE, true, "", 0.90), "vegetative_single", "Veg pruned after window remains 'vegetative_single'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.BLOOMING, false), "bloom_standard", "Bloom unpruned standard maps to 'bloom_standard'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.BLOOMING, true), "bloom_hero", "Bloom pruned maps to 'bloom_hero'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.BLOOMING, false, "hero"), "bloom_hero", "Bloom unpruned with quality='hero' maps to 'bloom_hero'")

	# Boundary progression checks: 0.24, 0.25, 0.59, 0.60, 0.85, 0.86, 0.99, 1.0
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.SEED, false, "", 0.24), "seed", "Progress 0.24 maps to 'seed'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.SPROUT, false, "", 0.25), "sprout", "Progress 0.25 maps to 'sprout'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.VEGETATIVE, false, "", 0.59), "vegetative_branching", "Progress 0.59 unpruned maps to 'vegetative_branching'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.VEGETATIVE, false, "", 0.60), "vegetative_branching", "Progress 0.60 (prune start) unpruned maps to 'vegetative_branching'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.VEGETATIVE, false, "", 0.85), "vegetative_branching", "Progress 0.85 (prune end) unpruned maps to 'vegetative_branching'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.VEGETATIVE, false, "", 0.86), "vegetative_late_unpruned", "Progress 0.86 (late unpruned) maps to 'vegetative_late_unpruned'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.VEGETATIVE, false, "", 0.99), "vegetative_late_unpruned", "Progress 0.99 unpruned maps to 'vegetative_late_unpruned'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.BLOOMING, false, "", 1.0), "bloom_standard", "Progress 1.0 unpruned maps to 'bloom_standard'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.BLOOMING, true, "", 1.0), "bloom_hero", "Progress 1.0 pruned maps to 'bloom_hero'")

	# Pruning window contract with GardenPlot
	var garden_plot_script = load("res://scripts/garden/garden_plot.gd")
	if garden_plot_script != null:
		var prune_end: float = garden_plot_script.PRUNE_WINDOW_END
		_assert_eq(prune_end, 0.85, "GardenPlot.PRUNE_WINDOW_END is canonical 0.85")
		_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.VEGETATIVE, false, "", prune_end), "vegetative_branching", "At exact PRUNE_WINDOW_END, state is still vegetative_branching")
		_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.VEGETATIVE, false, "", prune_end + 0.01), "vegetative_late_unpruned", "Just past PRUNE_WINDOW_END, state becomes vegetative_late_unpruned")

func _test_asset_resolver_diagnostics() -> void:
	print(">>> [TEST] FlowerAssetResolver Safety & Diagnostics...")
	_assert_true(FlowerAssetResolver.resolve_visual_stage_asset("nonexistent_flower", "sprout").is_empty(), "Unknown flower returns empty dict")
	_assert_true(FlowerAssetResolver.resolve_visual_stage_asset("velvet_dusk", "sprout").is_empty(), "Procedural hybrid returns empty dict")
	_assert_true(FlowerAssetResolver.resolve_visual_stage_asset("rose", "").is_empty(), "Empty state key returns empty dict")

	# Active profile resolution test: Rose
	var rose_sprout: Dictionary = FlowerAssetResolver.resolve_visual_stage_asset("rose", "sprout")
	_assert_true(not rose_sprout.is_empty(), "Rose sprout asset resolved from profile")
	_assert_eq(rose_sprout.get("target_height"), 42.0, "Rose sprout target height is 42.0")
	_assert_true(rose_sprout.get("texture") != null and (rose_sprout.get("texture") as Texture2D).resource_path.ends_with("plant_rose_shared_young.png"), "Rose sprout texture is plant_rose_shared_young.png")

	var rose_prime_bud: Dictionary = FlowerAssetResolver.resolve_visual_stage_asset("rose", "vegetative_single")
	_assert_true(not rose_prime_bud.is_empty(), "Rose prime bud asset resolved from profile")
	_assert_eq(rose_prime_bud.get("target_height"), 56.0, "Rose prime bud target height is 56.0")
	_assert_true(rose_prime_bud.get("texture") != null and (rose_prime_bud.get("texture") as Texture2D).resource_path.ends_with("plant_rose_red_prime_bud.png"), "Rose prime bud texture is plant_rose_red_prime_bud.png")

	# Rose icon resolution
	var rose_icon: Texture2D = FlowerAssetResolver.resolve_flower_icon("rose")
	_assert_true(rose_icon != null and rose_icon.resource_path.ends_with("icon_rose_red.png"), "Rose icon resolved to icon_rose_red.png")
	var rose_tex: Texture2D = FlowerAssetResolver.resolve_flower_texture("rose")
	_assert_true(rose_tex != null and rose_tex.resource_path.ends_with("icon_rose_red.png"), "Rose flower texture prefers icon_rose_red.png")

	var daisy_hero: Dictionary = FlowerAssetResolver.resolve_visual_stage_asset("daisy", "bloom_hero")
	_assert_true(not daisy_hero.is_empty(), "Daisy bloom hero asset resolved from profile")
	_assert_eq(daisy_hero.get("target_height"), 80.0, "Daisy bloom hero target height is 80.0")
	_assert_true(daisy_hero.get("texture") != null and (daisy_hero.get("texture") as Texture2D).resource_path.ends_with("daisy_bloom_premium.png"), "Daisy bloom hero texture is daisy_bloom_premium.png")

func _test_base_species_growth_textures() -> void:
	print(">>> [TEST] Base CVP Species Growth Textures...")
	var species_list := ["rose", "lavender", "tulip", "daisy", "rose_cream"]
	
	for sp in species_list:
		var visual := FlowerVisualScript.new()
		visual.flower_id = sp
		
		# SPROUT
		visual.current_stage = FlowerVisual.Stage.SPROUT
		var has_sprite := visual._update_branching_sprite()
		_assert_true(has_sprite, "%s sprout has branching sprite" % sp)
		var tex: Texture2D = visual._branch_sprite.texture
		if sp == "rose":
			_assert_true(tex != null and tex.resource_path.ends_with("plant_rose_shared_young.png"),
				"rose sprout texture is plant_rose_shared_young.png")
		else:
			_assert_true(tex != null and tex.resource_path.ends_with("%s_sprout.png" % sp), 
				"%s sprout texture is %s_sprout.png (got %s)" % [sp, sp, tex.resource_path if tex else "null"])
		
		# VEGETATIVE UNPRUNED (within prune window, e.g. progress 0.60)
		visual.is_pruned = false
		visual.growth_progress = 0.60
		visual.current_stage = FlowerVisual.Stage.VEGETATIVE
		has_sprite = visual._update_branching_sprite()
		_assert_true(has_sprite, "%s veg unpruned has branching sprite" % sp)
		tex = visual._branch_sprite.texture
		if sp == "rose":
			_assert_true(tex != null and tex.resource_path.ends_with("plant_rose_shared_branching.png"),
				"rose veg unpruned texture is plant_rose_shared_branching.png")
		else:
			_assert_true(tex != null and tex.resource_path.ends_with("%s_veg_bush.png" % sp),
				"%s veg unpruned texture is %s_veg_bush.png" % [sp, sp])

		# VEGETATIVE LATE UNPRUNED (after prune window, e.g. progress 0.86)
		visual.is_pruned = false
		visual.growth_progress = 0.86
		visual.current_stage = FlowerVisual.Stage.VEGETATIVE
		has_sprite = visual._update_branching_sprite()
		_assert_true(has_sprite, "%s veg late unpruned has branching sprite" % sp)
		tex = visual._branch_sprite.texture
		if sp == "rose":
			_assert_true(tex != null and tex.resource_path.ends_with("plant_rose_red_cluster_buds.png"),
				"rose veg late unpruned texture is plant_rose_red_cluster_buds.png")
		else:
			# Non-rose flowers explicitly map vegetative_late_unpruned to their veg_bush sprite
			_assert_true(tex != null and tex.resource_path.ends_with("%s_veg_bush.png" % sp),
				"%s veg late unpruned maps to explicit configured asset %s_veg_bush.png" % [sp, sp])
		
		# BLOOMING UNPRUNED
		visual.is_pruned = false
		visual.growth_progress = 1.0
		visual.current_stage = FlowerVisual.Stage.BLOOMING
		has_sprite = visual._update_branching_sprite()
		_assert_true(has_sprite, "%s bloom unpruned has branching sprite" % sp)
		tex = visual._branch_sprite.texture
		if sp == "rose":
			_assert_true(tex != null and tex.resource_path.ends_with("plant_rose_red_cluster_bloom.png"),
				"rose bloom unpruned texture is plant_rose_red_cluster_bloom.png")
		else:
			_assert_true(tex != null and tex.resource_path.ends_with("%s_bloom_standard.png" % sp),
				"%s bloom unpruned texture is %s_bloom_standard.png" % [sp, sp])
		
		visual.free()

func _test_pruning_differentiation() -> void:
	print(">>> [TEST] Pruning Differentiation (Hero vs Standard)...")
	var species_list := ["rose", "lavender", "tulip", "daisy"]
	
	for sp in species_list:
		var visual := FlowerVisualScript.new()
		visual.flower_id = sp
		
		# Vegetative pruned -> single stem / prime bud
		visual.current_stage = FlowerVisual.Stage.VEGETATIVE
		visual.is_pruned = true
		visual.growth_progress = 0.65
		visual._update_branching_sprite()
		var tex: Texture2D = visual._branch_sprite.texture
		if sp == "rose":
			_assert_true(tex != null and tex.resource_path.ends_with("plant_rose_red_prime_bud.png"),
				"rose vegetative pruned produces plant_rose_red_prime_bud.png")
		else:
			_assert_true(tex != null and tex.resource_path.ends_with("%s_veg_single.png" % sp),
				"%s vegetative pruned produces veg_single" % sp)
		
		# Blooming pruned -> premium hero bloom
		visual.current_stage = FlowerVisual.Stage.BLOOMING
		visual.is_pruned = true
		visual.growth_progress = 1.0
		visual._update_branching_sprite()
		tex = visual._branch_sprite.texture
		if sp == "rose":
			_assert_true(tex != null and tex.resource_path.ends_with("plant_rose_red_prime_bloom.png"),
				"rose blooming pruned produces plant_rose_red_prime_bloom.png")
		else:
			_assert_true(tex != null and tex.resource_path.ends_with("%s_bloom_premium.png" % sp),
				"%s blooming pruned produces bloom_premium" % sp)
		
		visual.free()

func _test_target_heights_contract() -> void:
	print(">>> [TEST] Target Heights and Anchors Contract...")
	var visual := FlowerVisualScript.new()
	visual.flower_id = "rose"
	
	# Sprout height: 42.0
	visual.current_stage = FlowerVisual.Stage.SPROUT
	visual._update_branching_sprite()
	var h: float = visual._branch_sprite.scale.y * visual._branch_sprite.texture.get_height()
	_assert_true(abs(h - 42.0) < 0.1, "Sprout target height is 42.0px (got %.1f)" % h)
	_assert_eq(visual._branch_sprite.position, Vector2(0, 2.0), "Ground position Y is 2.0")
	
	# Vegetative branching height: 52.0
	visual.is_pruned = false
	visual.growth_progress = 0.60
	visual.current_stage = FlowerVisual.Stage.VEGETATIVE
	visual._update_branching_sprite()
	h = visual._branch_sprite.scale.y * visual._branch_sprite.texture.get_height()
	_assert_true(abs(h - 52.0) < 0.1, "Vegetative branching target height is 52.0px (got %.1f)" % h)

	# Vegetative single (pruned bud) height: 56.0
	visual.is_pruned = true
	visual.growth_progress = 0.65
	visual.current_stage = FlowerVisual.Stage.VEGETATIVE
	visual._update_branching_sprite()
	h = visual._branch_sprite.scale.y * visual._branch_sprite.texture.get_height()
	_assert_true(abs(h - 56.0) < 0.1, "Vegetative single target height is 56.0px (got %.1f)" % h)

	# Vegetative late unpruned height: 54.0
	visual.is_pruned = false
	visual.growth_progress = 0.86
	visual.current_stage = FlowerVisual.Stage.VEGETATIVE
	visual._update_branching_sprite()
	h = visual._branch_sprite.scale.y * visual._branch_sprite.texture.get_height()
	_assert_true(abs(h - 54.0) < 0.1, "Vegetative late unpruned target height is 54.0px (got %.1f)" % h)
	
	# Blooming unpruned height: 66.0
	visual.is_pruned = false
	visual.growth_progress = 1.0
	visual.current_stage = FlowerVisual.Stage.BLOOMING
	visual._update_branching_sprite()
	h = visual._branch_sprite.scale.y * visual._branch_sprite.texture.get_height()
	_assert_true(abs(h - 66.0) < 0.1, "Blooming standard height is 66.0px (got %.1f)" % h)
	
	# Blooming pruned (hero) height: 80.0
	visual.is_pruned = true
	visual.growth_progress = 1.0
	visual.current_stage = FlowerVisual.Stage.BLOOMING
	visual._update_branching_sprite()
	h = visual._branch_sprite.scale.y * visual._branch_sprite.texture.get_height()
	_assert_true(abs(h - 80.0) < 0.1, "Blooming hero height is 80.0px (got %.1f)" % h)
	
	visual.free()

func _test_red_rose_lifecycle_visuals() -> void:
	print(">>> [TEST] Red Rose Production Lifecycle Visuals Contract...")
	var visual := FlowerVisualScript.new()
	visual.flower_id = "rose"

	# 1. Sprout -> Young
	visual.current_stage = FlowerVisual.Stage.SPROUT
	visual.growth_progress = 0.30
	visual.is_pruned = false
	visual._update_branching_sprite()
	_assert_true(visual._branch_sprite.texture.resource_path.ends_with("plant_rose_shared_young.png"),
		"Rose Sprout resolves to plant_rose_shared_young.png")

	# 2. Vegetative prune-window unpruned -> Branching
	visual.current_stage = FlowerVisual.Stage.VEGETATIVE
	visual.growth_progress = 0.65
	visual.is_pruned = false
	visual._update_branching_sprite()
	_assert_true(visual._branch_sprite.texture.resource_path.ends_with("plant_rose_shared_branching.png"),
		"Rose Veg in-window unpruned resolves to plant_rose_shared_branching.png")

	# 3. Vegetative pruned -> Prime Bud
	visual.current_stage = FlowerVisual.Stage.VEGETATIVE
	visual.growth_progress = 0.70
	visual.is_pruned = true
	visual._update_branching_sprite()
	_assert_true(visual._branch_sprite.texture.resource_path.ends_with("plant_rose_red_prime_bud.png"),
		"Rose Veg pruned resolves to plant_rose_red_prime_bud.png")

	# 4. Vegetative late unpruned -> Cluster Buds
	visual.current_stage = FlowerVisual.Stage.VEGETATIVE
	visual.growth_progress = 0.88
	visual.is_pruned = false
	visual._update_branching_sprite()
	_assert_true(visual._branch_sprite.texture.resource_path.ends_with("plant_rose_red_cluster_buds.png"),
		"Rose Veg late unpruned resolves to plant_rose_red_cluster_buds.png")

	# 5. Blooming unpruned -> Cluster Bloom
	visual.current_stage = FlowerVisual.Stage.BLOOMING
	visual.growth_progress = 1.0
	visual.is_pruned = false
	visual._update_branching_sprite()
	_assert_true(visual._branch_sprite.texture.resource_path.ends_with("plant_rose_red_cluster_bloom.png"),
		"Rose Blooming unpruned resolves to plant_rose_red_cluster_bloom.png")

	# 6. Blooming pruned (Hero) -> Prime Bloom
	visual.current_stage = FlowerVisual.Stage.BLOOMING
	visual.growth_progress = 1.0
	visual.is_pruned = true
	visual._update_branching_sprite()
	_assert_true(visual._branch_sprite.texture.resource_path.ends_with("plant_rose_red_prime_bloom.png"),
		"Rose Blooming pruned resolves to plant_rose_red_prime_bloom.png")

	# 7. Transition Stability: Ground Contact Point & Visual Center X
	var stage_configs := [
		{"stage": FlowerVisual.Stage.SPROUT, "progress": 0.30, "pruned": false, "name": "Young"},
		{"stage": FlowerVisual.Stage.VEGETATIVE, "progress": 0.65, "pruned": false, "name": "Branching"},
		{"stage": FlowerVisual.Stage.VEGETATIVE, "progress": 0.70, "pruned": true, "name": "Prime Bud"},
		{"stage": FlowerVisual.Stage.VEGETATIVE, "progress": 0.88, "pruned": false, "name": "Cluster Buds"},
		{"stage": FlowerVisual.Stage.BLOOMING, "progress": 1.0, "pruned": false, "name": "Cluster Bloom"},
		{"stage": FlowerVisual.Stage.BLOOMING, "progress": 1.0, "pruned": true, "name": "Prime Bloom"}
	]

	var contact_points: Array[Vector2] = []
	for cfg in stage_configs:
		visual.current_stage = cfg["stage"]
		visual.growth_progress = cfg["progress"]
		visual.is_pruned = cfg["pruned"]
		visual._update_branching_sprite()
		# Contact point in local FlowerVisual coordinates
		# Base anchor in texture coordinates is anchor_vec, local offset from center is (anchor_vec - 0.5) * size
		# With _branch_sprite.offset = base_offset + offset_vec, contact point = _branch_sprite.position + offset_vec * scale
		var contact := visual._branch_sprite.position
		contact_points.append(contact)

	for i in range(1, contact_points.size()):
		var prev: Vector2 = contact_points[i - 1]
		var curr: Vector2 = contact_points[i]
		var dy: float = abs(curr.y - prev.y)
		var dx: float = abs(curr.x - prev.x)
		_assert_true(dy <= 1.0, "Transition %s -> %s delta Y <= 1.0px (got %.2f)" % [stage_configs[i - 1]["name"], stage_configs[i]["name"], dy])
		_assert_true(dx <= 1.0, "Transition %s -> %s delta X <= 1.0px (got %.2f)" % [stage_configs[i - 1]["name"], stage_configs[i]["name"], dx])

	# 8. Cleanliness Guard: Ensure NO hardcoded 'rose' conditional in flower_visual.gd
	var fv_file := FileAccess.open("res://scripts/flowers/flower_visual.gd", FileAccess.READ)
	if fv_file != null:
		var fv_text := fv_file.get_as_text()
		fv_file.close()
		_assert_true(not fv_text.contains('flower_id == "rose"'), "flower_visual.gd contains NO hardcoded 'flower_id == \"rose\"' conditional")
		_assert_true(not fv_text.contains('flower_id == "rose_crimson"'), "flower_visual.gd contains NO hardcoded 'flower_id == \"rose_crimson\"' conditional")

	# 9. Cleanliness Guard: Ensure NO ArtSource paths in data/flowers.json
	var fj_file := FileAccess.open("res://data/flowers.json", FileAccess.READ)
	if fj_file != null:
		var fj_text := fj_file.get_as_text()
		fj_file.close()
		_assert_true(not fj_text.contains("ArtSource"), "data/flowers.json contains NO references to 'ArtSource'")

	visual.free()


func _test_procedural_fallback_hybrids() -> void:
	print(">>> [TEST] Procedural Fallback Hybrids...")
	var hybrids := ["velvet_dusk", "blushbell", "twilight_bell", "sunburst_daisy", "crown_petal", "meadow_mist"]
	
	for hb in hybrids:
		var visual := FlowerVisualScript.new()
		visual.flower_id = hb
		visual.current_stage = FlowerVisual.Stage.BLOOMING
		var has_sprite := visual._update_branching_sprite()
		# Current behavior: returns false (no growth stage textures for these hybrids)
		_assert_true(not has_sprite, "Hybrid %s correctly returns false for branching sprite (falls back to procedural drawing)" % hb)
		visual.free()

func _test_legacy_flower_mappings() -> void:
	print(">>> [TEST] Legacy Flower Visual Mappings...")
	var visual := FlowerVisualScript.new()
	
	# Sunflower blooming maps to master_sunflower.png
	visual.flower_id = "sunflower"
	visual.current_stage = FlowerVisual.Stage.BLOOMING
	var has_sprite := visual._update_branching_sprite()
	_assert_true(has_sprite and visual._branch_sprite.texture.resource_path.ends_with("master_sunflower.png"),
		"Sunflower blooming maps to master_sunflower.png")
	
	# Roselight blooming maps to master_roselight.png
	visual.flower_id = "roselight"
	visual.current_stage = FlowerVisual.Stage.BLOOMING
	has_sprite = visual._update_branching_sprite()
	_assert_true(has_sprite and visual._branch_sprite.texture.resource_path.ends_with("master_roselight.png"),
		"Roselight blooming maps to master_roselight.png")
		
	visual.free()
	
func _test_seed_contract() -> void:
	print(">>> [TEST] Universal Seed Procedural Contract...")
	# Stage.SEED maps to "seed" state
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.SEED, false), "seed", "Stage.SEED maps to 'seed'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.SEED, true), "seed", "Stage.SEED pruned still maps to 'seed'")

	# Seed stage asset resolution universally returns empty dict cleanly without warnings
	var rose_seed := FlowerAssetResolver.resolve_visual_stage_asset("rose", "seed")
	_assert_true(rose_seed.is_empty(), "Rose seed asset cleanly returns empty dict (no stage PNG required)")
	var lavender_seed := FlowerAssetResolver.resolve_visual_stage_asset("lavender", "seed")
	_assert_true(lavender_seed.is_empty(), "Lavender seed asset cleanly returns empty dict")

	# FlowerVisual at Stage.SEED does not create or display a branching sprite
	var visual := FlowerVisualScript.new()
	visual.flower_id = "rose"
	visual.current_stage = FlowerVisual.Stage.SEED
	var has_sprite := visual._update_branching_sprite()
	_assert_true(not has_sprite, "FlowerVisual at Stage.SEED returns false for branching sprite")
	visual.free()

func _test_procedural_fallback_gate() -> void:
	print(">>> [TEST] Procedural Fallback Gate...")
	var procedural_hybrids := ["blushbell", "velvet_dusk", "twilight_bell", "sunburst_daisy", "crown_petal", "meadow_mist"]
	for hb in procedural_hybrids:
		_assert_true(FlowerAssetResolver.is_procedural_flower(hb), "Hybrid '%s' is recognized as procedural flower" % hb)
		var f_data := FlowerData.get_flower(hb)
		var pstyle: String = f_data.get("visual_profile", {}).get("procedural_style", "")
		_assert_true(not pstyle.is_empty(), "Hybrid '%s' has explicit procedural_style ('%s')" % [hb, pstyle])

	var sprite_flowers := ["rose", "lavender", "tulip", "daisy", "sunflower", "roselight", "golden_rose", "sunflare_spike"]
	for sp in sprite_flowers:
		_assert_true(not FlowerAssetResolver.is_procedural_flower(sp), "Sprite flower '%s' is NOT marked as procedural" % sp)

	_assert_true(not FlowerAssetResolver.is_procedural_flower("unknown_orchid"), "Unknown flower is NOT marked as procedural")

func _test_sprite_flower_null_presentation() -> void:
	print(">>> [TEST] Sprite Flowers Null Presentation on Resolution Failure...")
	# Verify that a non-procedural flower cannot fall back to drawing procedural petals
	var visual := FlowerVisualScript.new()
	visual.flower_id = "nonexistent_flower"
	visual.current_stage = FlowerVisual.Stage.BLOOMING
	var has_sprite := visual._update_branching_sprite()
	_assert_true(not has_sprite, "Unknown flower sprite resolution fails")
	_assert_true(not FlowerAssetResolver.is_procedural_flower(visual.flower_id), "Unknown flower fails procedural gate")
	visual.free()

func _test_runtime_metadata_fixture() -> void:
	print(">>> [TEST] Runtime Metadata Application Extreme Fixture...")
	FlowerData._ensure_initialized()
	FlowerData._cached_flowers["test_extreme"] = {
		"id": "test_extreme",
		"display_name": "Test Extreme",
		"status": "cvp_base",
		"visual_profile": {
			"ground_anchor": [0.25, 0.75],
			"ground_position_y": -15.0,
			"sway_intensity": 2.5,
			"stages": {
				"sprout": {
					"sprite": "res://assets/flowers/growth_stages/rose_crimson_sprout.png",
					"target_height": 120.0,
					"offset": [14.0, -9.0]
				}
			}
		}
	}

	var res := FlowerAssetResolver.resolve_visual_stage_asset("test_extreme", "sprout")
	_assert_eq(res.get("target_height"), 120.0, "Extreme fixture target height resolved")
	_assert_eq(res.get("offset"), Vector2(14.0, -9.0), "Extreme fixture offset resolved")
	_assert_eq(res.get("ground_anchor"), Vector2(0.25, 0.75), "Extreme fixture ground_anchor resolved")
	_assert_eq(res.get("ground_position_y"), -15.0, "Extreme fixture ground_position_y resolved")
	_assert_eq(res.get("sway_intensity"), 2.5, "Extreme fixture sway_intensity resolved")

	var visual := FlowerVisualScript.new()
	visual.flower_id = "test_extreme"
	visual.current_stage = FlowerVisual.Stage.SPROUT
	var ok := visual._update_branching_sprite()
	_assert_true(ok, "Extreme fixture sprite applied")

	var tex: Texture2D = visual._branch_sprite.texture
	var expected_scale := 120.0 / float(tex.get_height())
	_assert_true(abs(visual._branch_sprite.scale.y - expected_scale) < 0.001, "Branch sprite scale reflects target_height: 120.0")

	var base_offset := Vector2((0.5 - 0.25) * tex.get_width(), (0.5 - 0.75) * tex.get_height())
	var expected_offset := base_offset + Vector2(14.0, -9.0)
	_assert_eq(visual._branch_sprite.offset, expected_offset, "Branch sprite offset reflects ground_anchor and custom offset")
	_assert_eq(visual._branch_sprite.position.y, -15.0, "Branch sprite position.y reflects ground_position_y: -15.0")
	_assert_eq(visual._sway_intensity, 2.5, "Visual _sway_intensity reflects sway_intensity: 2.5")

	visual.sway_enabled = true
	visual.current_stage = FlowerVisual.Stage.BLOOMING
	visual._process(0.1)

	visual.free()
	FlowerData._cached_flowers.erase("test_extreme")
