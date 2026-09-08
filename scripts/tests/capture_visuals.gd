extends SceneTree

## Comprehensive Visual Capture Suite for Milestone P4 — Living Garden Visual Slice.
## Captures all required visual evidence artifacts:
## 1. p4_living_garden_overview.png: Clean living garden environment without debug clutter
## 2. p4_whole_vs_modular_vs_curated.png: Direct 3-strategy comparison (Approach A vs B vs C)
## 3. p4_same_species_variations.png: 3 specimens of the SAME hybrid species (Roselight A, B, C)
## 4. p4_visual_inheritance_comparison.png: Lineage breakdown across 3 hybrid crosses with provenance tags
## 5. p4_character_scale_and_movement.png: Gardener character walking near flowers, paths, and bench
## 6. p4_perspective_depth_ordering.png: 3/4 angled view showing Y-sort depth ordering
## 7. p4_custom_layout_presets.png: Showcase of Classic Promenade, Botanist's Quad, and Serpentine Oasis
## 8. p4_direct_customization.png: Direct player-arrangement / bench relocation

var frame_count: int = 0
var main_node: MainGame = null
var output_dir: String = "/home/el3laimy/.gemini/antigravity-ide/brain/eb1af34d-36d1-4c02-afee-20db3b1389ab"


func _init() -> void:
	var main_scene_res := load("res://scenes/main.tscn")
	main_node = main_scene_res.instantiate() as MainGame
	root.add_child(main_node)


func _process(delta: float) -> bool:
	frame_count += 1

	match frame_count:
		5:
			# Setup Living Garden with blooming flowers and character near fountain
			main_node.coins = 120
			main_node.inventory["rose"] = 4
			main_node.inventory["lavender"] = 3
			main_node.inventory["sunflower"] = 2

			var grid: GardenGrid = main_node.garden_grid

			# Specimen 1: Roselight Crimson Round (Plot 0)
			var g_sp1 := FlowerGenotype.new(["Cr", "Cr"], ["Pr", "Pr"], ["f-", "f-"], ["v-", "v-"])
			var ph_sp1 := GeneticsEngine.resolve_phenotype(g_sp1, "roselight")
			var sp1 := FlowerSpecimen.new("H-101", "roselight", 1, g_sp1, ph_sp1)
			grid.get_plot(0).plant("roselight", false, sp1)
			grid.get_plot(0)._process(15.0)

			# Specimen 2: Roselight Plum Magenta Star (Plot 1)
			var g_sp2 := FlowerGenotype.new(["Cr", "Cp"], ["Ps", "Pr"], ["F+", "f-"], ["V+", "v-"])
			var ph_sp2 := GeneticsEngine.resolve_phenotype(g_sp2, "roselight")
			var sp2 := FlowerSpecimen.new("H-102", "roselight", 1, g_sp2, ph_sp2)
			grid.get_plot(1).plant("roselight", false, sp2)
			grid.get_plot(1)._process(15.0)

			# Specimen 3: Roselight Soft Lavender Pointed (Plot 2)
			var g_sp3 := FlowerGenotype.new(["Cp", "Cp"], ["Pp", "Pp"], ["F+", "F+"], ["V+", "V+"])
			var ph_sp3 := GeneticsEngine.resolve_phenotype(g_sp3, "roselight")
			var sp3 := FlowerSpecimen.new("H-103", "roselight", 1, g_sp3, ph_sp3)
			grid.get_plot(2).plant("roselight", false, sp3)
			grid.get_plot(2)._process(15.0)

			# Plot 3: Golden Sun Rose (Hybrid 2)
			var g_sp4 := FlowerGenotype.new(["Cr", "Cy"], ["Pr", "Pr"], ["F+", "f-"], ["V+", "V+"])
			var ph_sp4 := GeneticsEngine.resolve_phenotype(g_sp4, "golden_rose")
			var sp4 := FlowerSpecimen.new("H-201", "golden_rose", 1, g_sp4, ph_sp4)
			grid.get_plot(3).plant("golden_rose", false, sp4)
			grid.get_plot(3)._process(15.0)

			# Plot 4: Sunflare Spike (Hybrid 3)
			var g_sp5 := FlowerGenotype.new(["Cp", "Cy"], ["Ps", "Pr"], ["F+", "F+"], ["V+", "v-"])
			var ph_sp5 := GeneticsEngine.resolve_phenotype(g_sp5, "sunflare_spike")
			var sp5 := FlowerSpecimen.new("H-301", "sunflare_spike", 1, g_sp5, ph_sp5)
			grid.get_plot(4).plant("sunflare_spike", false, sp5)
			grid.get_plot(4)._process(15.0)

			# Plot 5: Growing Mystery Seed with shimmer aura
			var g_myst := FlowerGenotype.new(["Cr", "Cp"], ["Ps", "Pp"], ["F+", "f-"], ["V+", "v-"])
			var ph_myst := GeneticsEngine.resolve_phenotype(g_myst, "roselight")
			var sp_myst := FlowerSpecimen.new("H-104", "roselight", 1, g_myst, ph_myst)
			grid.get_plot(5).plant("roselight", true, sp_myst)
			grid.get_plot(5)._process(2.0)

			# Position Gardener near the stepping stones / fountain
			if main_node.character != null:
				main_node.character.position = Vector2(-70, 20)
				main_node.character.call("_update_facing", Vector2(1, 0))

			main_node._sync_hud_state()

		12:
			# Capture 1: Clean Living Garden Environment Overview
			_capture_screen("p4_living_garden_overview.png")

		16:
			# Setup Gardener Character Proximity to Plot 0
			if main_node.character != null:
				main_node.character.position = Vector2(-190, -100)
				main_node.character.call("_update_facing", Vector2(-1, 0))
				main_node.character.call("_check_plot_proximity")
				main_node.character.call("play_tending_gesture")

		20:
			# Capture 2: Gardener Character Scale & Proximity Interaction
			_capture_screen("p4_character_scale_and_movement.png")

		24:
			# Setup 3/4 Angled Perspective & Position Gardener in front of the Teak Bench
			main_node._on_perspective_changed(1) # 3/4 Angled
			if main_node.character != null:
				main_node.character.position = Vector2(-280, -75) # Walking in front of the bench
				main_node.character.call("_update_facing", Vector2(1, 0))

		28:
			# Capture 3: 3/4 Angled Perspective & Y-Sorting Depth
			_capture_screen("p4_perspective_depth_ordering.png")
			main_node._on_perspective_changed(0) # Reset to Top-Down

		32:
			# Setup Direct Spatial Customization (Bench relocated)
			if main_node.environment != null:
				main_node.environment.set("bench_position", Vector2(240, -130))
				main_node.environment.set("_selected_decor", "bench")
				main_node.environment.queue_redraw()

		36:
			# Capture 4: Direct Spatial Customization (Bench relocated)
			_capture_screen("p4_direct_customization.png")
			if main_node.environment != null:
				main_node.environment.set("_selected_decor", "")
				main_node.environment.set("bench_position", Vector2(-280, -110))
				main_node.environment.queue_redraw()

		40:
			# Setup Garden Layout Presets (Serpentine Oasis)
			main_node._on_layout_preset_changed(2) # Serpentine Oasis

		44:
			# Capture 5: Garden Layout Presets (Serpentine Oasis)
			_capture_screen("p4_custom_layout_presets.png")
			main_node._on_layout_preset_changed(0) # Reset to Promenade

		48:
			# Open P4 Visual Lab Modal: Strategy C (Curated Hybrid Pipeline)
			main_node.hud.open_visual_lab_modal()
			main_node.hud._set_visual_lab_strategy(2)
			main_node.hud._set_visual_lab_lineage("roselight")

		52:
			# Capture 6: Visual Inheritance Comparison with Trait Provenance Tags
			_capture_screen("p4_visual_inheritance_comparison.png")

		56:
			# Switch to Strategy A (Whole-Authored) in Visual Lab
			main_node.hud._set_visual_lab_strategy(0)

		60:
			# Capture 7: Whole-Authored Comparison
			_capture_screen("p4_whole_vs_modular_vs_curated.png")

		64:
			# Close modal and capture 3 Same-Species Variations in garden
			main_node.hud.close_visual_lab_modal()

		68:
			# Capture 8: 3 Same-Species Variations
			_capture_screen("p4_same_species_variations.png")

		72:
			print("✓ [P4-VISUAL] All P4 visual captures successfully generated.")
			quit(0)

	return false


func _capture_screen(filename: String) -> void:
	var image: Image = root.get_viewport().get_texture().get_image()
	var dest_path: String = output_dir + "/" + filename
	var err := image.save_png(dest_path)
	if err == OK:
		print("✓ Captured visual artifact: " + filename)
	else:
		printerr("Failed to save screenshot: " + dest_path)
