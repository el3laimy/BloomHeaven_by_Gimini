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
	_test_procedural_fallback_hybrids()
	_test_legacy_flower_mappings()

func _test_visual_state_resolver() -> void:
	print(">>> [TEST] FlowerVisualStateResolver...")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.SEED, false), "seed", "Stage SEED maps to 'seed'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.SPROUT, false), "sprout", "Stage SPROUT maps to 'sprout'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.VEGETATIVE, false), "vegetative_branching", "Veg unpruned maps to 'vegetative_branching'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.VEGETATIVE, true), "vegetative_single", "Veg pruned maps to 'vegetative_single'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.BLOOMING, false), "bloom_standard", "Bloom unpruned standard maps to 'bloom_standard'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.BLOOMING, true), "bloom_hero", "Bloom pruned maps to 'bloom_hero'")
	_assert_eq(FlowerVisualStateResolver.resolve_visual_state(FlowerVisual.Stage.BLOOMING, false, "hero"), "bloom_hero", "Bloom unpruned with quality='hero' maps to 'bloom_hero'")

func _test_asset_resolver_diagnostics() -> void:
	print(">>> [TEST] FlowerAssetResolver Safety & Diagnostics...")
	_assert_true(FlowerAssetResolver.resolve_visual_stage_asset("nonexistent_flower", "sprout").is_empty(), "Unknown flower returns empty dict")
	_assert_true(FlowerAssetResolver.resolve_visual_stage_asset("velvet_dusk", "sprout").is_empty(), "Procedural hybrid returns empty dict")
	_assert_true(FlowerAssetResolver.resolve_visual_stage_asset("rose", "").is_empty(), "Empty state key returns empty dict")

	# Active profile resolution test
	var rose_sprout: Dictionary = FlowerAssetResolver.resolve_visual_stage_asset("rose", "sprout")
	_assert_true(not rose_sprout.is_empty(), "Rose sprout asset resolved from profile")
	_assert_eq(rose_sprout.get("target_height"), 38.0, "Rose sprout target height is 38.0")
	_assert_true(rose_sprout.get("texture") != null and (rose_sprout.get("texture") as Texture2D).resource_path.ends_with("rose_crimson_sprout.png"), "Rose sprout texture is rose_crimson_sprout.png")

	var daisy_hero: Dictionary = FlowerAssetResolver.resolve_visual_stage_asset("daisy", "bloom_hero")
	_assert_true(not daisy_hero.is_empty(), "Daisy bloom hero asset resolved from profile")
	_assert_eq(daisy_hero.get("target_height"), 80.0, "Daisy bloom hero target height is 80.0")
	_assert_true(daisy_hero.get("texture") != null and (daisy_hero.get("texture") as Texture2D).resource_path.ends_with("daisy_bloom_premium.png"), "Daisy bloom hero texture is daisy_bloom_premium.png")

func _test_base_species_growth_textures() -> void:
	print(">>> [TEST] Base CVP Species Growth Textures...")
	var species_list := ["rose", "lavender", "tulip", "daisy", "rose_cream", "rose_crimson"]
	
	for sp in species_list:
		var visual := FlowerVisualScript.new()
		visual.flower_id = sp
		
		# SPROUT
		visual.current_stage = FlowerVisual.Stage.SPROUT
		var has_sprite := visual._update_branching_sprite()
		_assert_true(has_sprite, "%s sprout has branching sprite" % sp)
		var tex: Texture2D = visual._branch_sprite.texture
		var expected_key: String = "rose_crimson" if sp in ["rose", "rose_crimson"] else sp
		_assert_true(tex != null and tex.resource_path.ends_with("%s_sprout.png" % expected_key), 
			"%s sprout texture is %s_sprout.png (got %s)" % [sp, expected_key, tex.resource_path if tex else "null"])
		
		# VEGETATIVE UNPRUNED
		visual.is_pruned = false
		visual.current_stage = FlowerVisual.Stage.VEGETATIVE
		has_sprite = visual._update_branching_sprite()
		_assert_true(has_sprite, "%s veg unpruned has branching sprite" % sp)
		tex = visual._branch_sprite.texture
		_assert_true(tex != null and tex.resource_path.ends_with("%s_veg_bush.png" % expected_key),
			"%s veg unpruned texture is %s_veg_bush.png" % [sp, expected_key])
		
		# BLOOMING UNPRUNED
		visual.is_pruned = false
		visual.current_stage = FlowerVisual.Stage.BLOOMING
		has_sprite = visual._update_branching_sprite()
		_assert_true(has_sprite, "%s bloom unpruned has branching sprite" % sp)
		tex = visual._branch_sprite.texture
		_assert_true(tex != null and tex.resource_path.ends_with("%s_bloom_standard.png" % expected_key),
			"%s bloom unpruned texture is %s_bloom_standard.png" % [sp, expected_key])
		
		visual.free()

func _test_pruning_differentiation() -> void:
	print(">>> [TEST] Pruning Differentiation (Hero vs Standard)...")
	var species_list := ["rose", "lavender", "tulip", "daisy"]
	
	for sp in species_list:
		var visual := FlowerVisualScript.new()
		visual.flower_id = sp
		var expected_key: String = "rose_crimson" if sp == "rose" else sp
		
		# Vegetative pruned -> single stem
		visual.current_stage = FlowerVisual.Stage.VEGETATIVE
		visual.is_pruned = true
		visual._update_branching_sprite()
		var tex: Texture2D = visual._branch_sprite.texture
		_assert_true(tex != null and tex.resource_path.ends_with("%s_veg_single.png" % expected_key),
			"%s vegetative pruned produces veg_single" % sp)
		
		# Blooming pruned -> premium hero bloom
		visual.current_stage = FlowerVisual.Stage.BLOOMING
		visual.is_pruned = true
		visual._update_branching_sprite()
		tex = visual._branch_sprite.texture
		_assert_true(tex != null and tex.resource_path.ends_with("%s_bloom_premium.png" % expected_key),
			"%s blooming pruned produces bloom_premium" % sp)
		
		visual.free()

func _test_target_heights_contract() -> void:
	print(">>> [TEST] Target Heights and Anchors Contract...")
	var visual := FlowerVisualScript.new()
	visual.flower_id = "rose"
	
	# Sprout height: 38.0
	visual.current_stage = FlowerVisual.Stage.SPROUT
	visual._update_branching_sprite()
	var h: float = visual._branch_sprite.scale.y * visual._branch_sprite.texture.get_height()
	_assert_true(abs(h - 38.0) < 0.1, "Sprout target height is 38.0px (got %.1f)" % h)
	_assert_eq(visual._branch_sprite.position, Vector2(0, 2.0), "Ground position Y is 2.0")
	
	# Vegetative height: 52.0
	visual.current_stage = FlowerVisual.Stage.VEGETATIVE
	visual._update_branching_sprite()
	h = visual._branch_sprite.scale.y * visual._branch_sprite.texture.get_height()
	_assert_true(abs(h - 52.0) < 0.1, "Vegetative target height is 52.0px (got %.1f)" % h)
	
	# Blooming unpruned height: 66.0
	visual.is_pruned = false
	visual.current_stage = FlowerVisual.Stage.BLOOMING
	visual._update_branching_sprite()
	h = visual._branch_sprite.scale.y * visual._branch_sprite.texture.get_height()
	_assert_true(abs(h - 66.0) < 0.1, "Blooming standard height is 66.0px (got %.1f)" % h)
	
	# Blooming pruned (hero) height: 80.0
	visual.is_pruned = true
	visual.current_stage = FlowerVisual.Stage.BLOOMING
	visual._update_branching_sprite()
	h = visual._branch_sprite.scale.y * visual._branch_sprite.texture.get_height()
	_assert_true(abs(h - 80.0) < 0.1, "Blooming hero height is 80.0px (got %.1f)" % h)
	
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
