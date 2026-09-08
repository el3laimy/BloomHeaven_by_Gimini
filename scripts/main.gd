class_name MainGame
extends Node2D

## Main Game Orchestrator for Finest Garden (Bloomhaven).
## Coordinates GardenGrid, GardenCamera, HudController, Breeding Lab, Bouquet Workshop,
## Florist Requests, Botanical Journal, Trait Genetics Engine, and SaveManager V1.

const GardenLayoutManagerScript := preload("res://scripts/garden/garden_layout_manager.gd")
const SaveManagerScript := preload("res://scripts/core/save_manager.gd")
const PauseMenuScene := preload("res://scenes/ui/pause_menu.tscn")
const SettingsMenuScene := preload("res://scenes/ui/settings_menu.tscn")
const TutorialOverlayScene := preload("res://scenes/ui/tutorial_overlay.tscn")

@onready var environment: Node2D = $GardenEnvironment
@onready var garden_grid: GardenGrid = $GardenGrid
@onready var character: CharacterBody2D = $GardenerCharacter
@onready var camera: GardenCamera = $GardenCamera
@onready var hud: HudController = $HUD

var inventory: Dictionary = {
	"rose": 0,
	"lavender": 0,
	"sunflower": 0,
	"roselight": 0,
	"golden_rose": 0,
	"sunflare_spike": 0
}

var bouquet_inventory: Dictionary = {
	"garden_harmony": 0,
	"crimson_romance": 0,
	"ethereal_lumina": 0,
	"solar_grandeur": 0
}

var perfume_inventory: Dictionary = {
	"lavender_mist": 0,
	"velvet_rose_elixir": 0,
	"solar_amber_essence": 0
}

var order_manager: OrderManager = OrderManager.new()
var upgrade_manager: UpgradeManager = UpgradeManager.new()

var coins: int = 0

var combo_count: int:
	get:
		return order_manager.combo_count if order_manager != null else _combo_count_fallback
	set(v):
		if order_manager != null:
			order_manager.combo_count = v
		_combo_count_fallback = v
var _combo_count_fallback: int = 0

var combo_timer: float:
	get:
		return order_manager.combo_timer if order_manager != null else _combo_timer_fallback
	set(v):
		if order_manager != null:
			order_manager.combo_timer = v
		_combo_timer_fallback = v
var _combo_timer_fallback: float = 0.0

var active_upgrades: Dictionary:
	get:
		return upgrade_manager.active_upgrades if upgrade_manager != null else _active_upgrades_fallback
	set(v):
		if upgrade_manager != null:
			upgrade_manager.active_upgrades = v
		_active_upgrades_fallback = v
var _active_upgrades_fallback: Dictionary = {
	"swift_boots": false,
	"double_sprinkler": false,
	"enriched_soil": false,
	"fertilizer_box": false,
	"expanded_satchel": false
}

var live_orders_patience: Dictionary:
	get:
		return order_manager.live_orders_patience if order_manager != null else _live_orders_patience_fallback
	set(v):
		if order_manager != null:
			order_manager.live_orders_patience = v
		_live_orders_patience_fallback = v
var _live_orders_patience_fallback: Dictionary = {
	"order_1": 75.0,
	"order_2": 80.0,
	"order_3": 85.0,
	"order_4": 90.0,
	"order_5": 80.0,
	"order_6": 95.0
}

var completed_requests: Dictionary:
	get:
		return order_manager.completed_requests if order_manager != null else _completed_requests_fallback
	set(v):
		if order_manager != null:
			order_manager.completed_requests = v
		_completed_requests_fallback = v
var _completed_requests_fallback: Dictionary = {
	"order_1": false,
	"order_2": false,
	"order_3": false,
	"order_4": false,
	"order_5": false,
	"order_6": false
}

var discovered_flowers: Dictionary = {
	"rose": true,
	"lavender": true,
	"sunflower": true,
	"roselight": false,
	"golden_rose": false,
	"sunflare_spike": false,
	"tulip": true,
	"daisy": true,
	"rose_cream": true
}

var unknown_hybrid_seeds: Array[String] = []
var unknown_hybrid_specimens: Array[FlowerSpecimen] = []
var breeding_roster: Array[FlowerSpecimen] = []

var current_tool: String = "plant"
var current_seed: String = "rose"
var global_speed_multiplier: float = 1.0

# UI Overlays & Menus
var _pause_menu: PauseMenu = null
var _settings_menu: SettingsMenu = null
var _tutorial_overlay: TutorialOverlay = null
var _auto_save_timer: float = 0.0


func _ready() -> void:
	_load_game_state()
	_init_starter_breeding_stock()
	_setup_menus()
	_connect_signals()
	_sync_hud_state()
	_apply_all_active_upgrades()
	hud.update_discoveries(discovered_flowers)
	hud.update_requests(completed_requests)
	hud.update_breeding_roster(breeding_roster)
	_start_ambient_music()
	
	if not SaveManagerScript.has_save() and _tutorial_overlay != null:
		_tutorial_overlay.show_step(0)
	else:
		hud.show_toast("🌸 Welcome to BloomHaven! Fiona Finch management mode active.", Color(0.65, 0.95, 0.75))


func _process(delta: float) -> void:
	if is_instance_valid(garden_grid) and is_instance_valid(garden_grid.selected_plot):
		hud.update_plot_info(garden_grid.selected_plot)

	# Order patience and combo decay managed by OrderManager
	if order_manager != null:
		order_manager.tick(delta)

	# Auto-save every 30 seconds
	_auto_save_timer += delta
	if _auto_save_timer >= 30.0:
		_auto_save_timer = 0.0
		_save_game_state()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if is_instance_valid(hud) and hud.has_method("has_active_modal") and hud.has_active_modal():
			hud.close_top_modal()
			_play_sfx("click")
		else:
			_toggle_pause_menu()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				current_tool = "plant"
				_sync_hud_state()
				if is_instance_valid(character) and character.has_method("set_active_tool"):
					character.set_active_tool("plant")
				_play_sfx("click")
				hud.show_toast("🌱 Tool: Planting Trowel [1]", Color(0.6, 0.9, 0.6))
			KEY_2:
				current_tool = "water"
				_sync_hud_state()
				if is_instance_valid(character) and character.has_method("set_active_tool"):
					character.set_active_tool("water")
				_play_sfx("click")
				hud.show_toast("💧 Tool: Watering Can [2]", Color(0.4, 0.8, 1.0))
			KEY_3:
				current_tool = "prune"
				_sync_hud_state()
				if is_instance_valid(character) and character.has_method("set_active_tool"):
					character.set_active_tool("prune")
				_play_sfx("click")
				hud.show_toast("✂️ Tool: Pruning Shears [3]", Color(1.0, 0.9, 0.4))
			KEY_4:
				current_tool = "harvest"
				_sync_hud_state()
				if is_instance_valid(character) and character.has_method("set_active_tool"):
					character.set_active_tool("harvest")
				_play_sfx("click")
				hud.show_toast("🌸 Tool: Harvest Basket [4]", Color(1.0, 0.6, 0.8))
			KEY_5:
				if not active_upgrades.get("fertilizer_box", false):
					_play_sfx("error")
					hud.show_toast("🔒 Unlock Organic Compost Elixir in Upgrades Shop first!", Color(1.0, 0.45, 0.45))
				else:
					current_tool = "fertilizer"
					_sync_hud_state()
					if is_instance_valid(character) and character.has_method("set_active_tool"):
						character.set_active_tool("fertilizer")
					_play_sfx("click")
					hud.show_toast("🧪 Tool: Organic Fertilizer [5]", Color(0.4, 1.0, 0.6))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if is_instance_valid(character):
			character.clear_queue()
			_play_sfx("click")
			hud.show_toast("🧹 Action Queue Cleared", Color(0.7, 0.7, 0.7))


func _setup_menus() -> void:
	# Instantiate Pause Menu
	_pause_menu = PauseMenuScene.instantiate() as PauseMenu
	_pause_menu.hide()
	_pause_menu.resume_requested.connect(func(): _pause_menu.hide())
	_pause_menu.settings_requested.connect(func():
		if _settings_menu:
			_settings_menu.show()
	)
	_pause_menu.save_requested.connect(func():
		_save_game_state()
		hud.show_toast("💾 Game saved successfully!", Color(0.6, 1.0, 0.7))
	)
	_pause_menu.main_menu_requested.connect(func():
		_save_game_state()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	hud.add_child(_pause_menu)

	# Instantiate Settings Menu
	_settings_menu = SettingsMenuScene.instantiate() as SettingsMenu
	_settings_menu.hide()
	_settings_menu.reset_camera_requested.connect(_on_reset_camera)
	hud.add_child(_settings_menu)

	# Instantiate Tutorial Overlay
	_tutorial_overlay = TutorialOverlayScene.instantiate() as TutorialOverlay
	_tutorial_overlay.hide()
	hud.add_child(_tutorial_overlay)


func _toggle_pause_menu() -> void:
	if _pause_menu == null:
		return
	if _pause_menu.visible:
		_pause_menu.hide()
	else:
		_pause_menu.show()


func _save_game_state() -> void:
	var roster_serialized: Array = []
	for spec in breeding_roster:
		roster_serialized.append(spec.serialize())

	var state_data: Dictionary = {
		"coins": coins,
		"inventory": inventory,
		"bouquet_inventory": bouquet_inventory,
		"perfume_inventory": perfume_inventory,
		"completed_requests": completed_requests,
		"live_orders_patience": order_manager.live_orders_patience if order_manager != null else {},
		"combo_count": order_manager.combo_count if order_manager != null else 0,
		"combo_timer": order_manager.combo_timer if order_manager != null else 0.0,
		"discovered_flowers": discovered_flowers,
		"active_upgrades": active_upgrades,
		"unknown_hybrid_seeds": unknown_hybrid_seeds,
		"breeding_roster": roster_serialized,
		"plots": SaveManagerScript.serialize_plots(garden_grid.plots) if is_instance_valid(garden_grid) else []
	}
	SaveManagerScript.save_game(state_data)


func _load_game_state() -> void:
	var data := SaveManagerScript.load_game()
	if data.is_empty():
		return

	coins = data.get("coins", coins)
	inventory = data.get("inventory", inventory)
	bouquet_inventory = data.get("bouquet_inventory", bouquet_inventory)
	perfume_inventory = data.get("perfume_inventory", perfume_inventory)
	completed_requests = data.get("completed_requests", completed_requests)
	discovered_flowers = data.get("discovered_flowers", discovered_flowers)
	active_upgrades = data.get("active_upgrades", active_upgrades)
	_apply_all_active_upgrades()

	if data.has("live_orders_patience") and data["live_orders_patience"] is Dictionary and order_manager != null:
		for o_id in data["live_orders_patience"]:
			order_manager.live_orders_patience[o_id] = float(data["live_orders_patience"][o_id])

	if data.has("combo_count") and order_manager != null:
		order_manager.combo_count = int(data["combo_count"])

	if data.has("combo_timer") and order_manager != null:
		order_manager.combo_timer = float(data["combo_timer"])
	
	if data.has("unknown_hybrid_seeds") and data["unknown_hybrid_seeds"] is Array:
		unknown_hybrid_seeds.clear()
		for s in data["unknown_hybrid_seeds"]:
			unknown_hybrid_seeds.append(str(s))

	if data.has("breeding_roster") and data["breeding_roster"] is Array:
		breeding_roster.clear()
		for s_dict in data["breeding_roster"]:
			breeding_roster.append(FlowerSpecimen.deserialize(s_dict))

	if data.has("plots") and data["plots"] is Array and is_instance_valid(garden_grid):
		SaveManagerScript.deserialize_plots(data["plots"], garden_grid.plots)


func _init_starter_breeding_stock() -> void:
	var ids: Array[String] = []
	for s in breeding_roster:
		if is_instance_valid(s):
			ids.append(s.specimen_id)

	if not ids.has("R-001"):
		breeding_roster.append(GeneticsEngine.create_starter_specimen("rose", "R-001"))
	if not ids.has("L-001"):
		breeding_roster.append(GeneticsEngine.create_starter_specimen("lavender", "L-001"))
	if not ids.has("S-001"):
		breeding_roster.append(GeneticsEngine.create_starter_specimen("sunflower", "S-001"))


func _connect_signals() -> void:
	if is_instance_valid(garden_grid):
		if not garden_grid.plot_selected.is_connected(_on_plot_selected):
			garden_grid.plot_selected.connect(_on_plot_selected)
		if not garden_grid.plot_action_requested.is_connected(_on_plot_action_requested):
			garden_grid.plot_action_requested.connect(_on_plot_action_requested)
		if not garden_grid.flower_harvested.is_connected(_on_flower_harvested):
			garden_grid.flower_harvested.connect(_on_flower_harvested)
		if not garden_grid.flower_revealed.is_connected(_on_flower_revealed):
			garden_grid.flower_revealed.connect(_on_flower_revealed)
		if garden_grid.has_signal("prune_window_opened") and not garden_grid.prune_window_opened.is_connected(_on_plot_prune_window_opened):
			garden_grid.prune_window_opened.connect(_on_plot_prune_window_opened)

	if is_instance_valid(hud):
		if not hud.tool_selected.is_connected(_on_tool_selected):
			hud.tool_selected.connect(_on_tool_selected)
		if not hud.seed_selected.is_connected(_on_seed_selected):
			hud.seed_selected.connect(_on_seed_selected)
		if not hud.zoom_in_requested.is_connected(_on_zoom_in):
			hud.zoom_in_requested.connect(_on_zoom_in)
		if not hud.zoom_out_requested.is_connected(_on_zoom_out):
			hud.zoom_out_requested.connect(_on_zoom_out)
		if not hud.reset_camera_requested.is_connected(_on_reset_camera):
			hud.reset_camera_requested.connect(_on_reset_camera)
		if not hud.speed_changed.is_connected(_on_speed_changed):
			hud.speed_changed.connect(_on_speed_changed)
		if not hud.breed_requested.is_connected(_on_breed_requested):
			hud.breed_requested.connect(_on_breed_requested)
		if not hud.craft_bouquet_requested.is_connected(_on_craft_bouquet_requested):
			hud.craft_bouquet_requested.connect(_on_craft_bouquet_requested)
		if not hud.fulfill_request_requested.is_connected(_on_fulfill_request_requested):
			hud.fulfill_request_requested.connect(_on_fulfill_request_requested)
		if not hud.preserve_plot_requested.is_connected(_on_preserve_plot_requested):
			hud.preserve_plot_requested.connect(_on_preserve_plot_requested)
		if not hud.harvest_plot_requested.is_connected(_on_harvest_plot_requested):
			hud.harvest_plot_requested.connect(_on_harvest_plot_requested)
		if not hud.release_specimen_requested.is_connected(_on_release_specimen_requested):
			hud.release_specimen_requested.connect(_on_release_specimen_requested)
		if not hud.layout_preset_changed.is_connected(_on_layout_preset_changed):
			hud.layout_preset_changed.connect(_on_layout_preset_changed)
		if not hud.perspective_changed.is_connected(_on_perspective_changed):
			hud.perspective_changed.connect(_on_perspective_changed)
		if not hud.character_toggled.is_connected(_on_character_toggled):
			hud.character_toggled.connect(_on_character_toggled)
		if hud.has_signal("upgrade_purchased") and not hud.upgrade_purchased.is_connected(_on_upgrade_purchased):
			hud.upgrade_purchased.connect(_on_upgrade_purchased)


func _sync_hud_state() -> void:
	if is_instance_valid(hud):
		hud.update_inventory(inventory, bouquet_inventory, coins, unknown_hybrid_seeds.size())
		hud.update_requests(completed_requests)
		hud.update_breeding_roster(breeding_roster)
		if hud.has_method("update_upgrades"):
			hud.update_upgrades(active_upgrades)


func _on_tool_selected(tool_id: String) -> void:
	if tool_id == "fertilizer" and not active_upgrades.get("fertilizer_box", false):
		_play_sfx("error")
		hud.show_toast("🔒 Unlock Organic Compost Elixir in Upgrades Shop first!", Color(1.0, 0.45, 0.45))
		_sync_hud_state()
		return

	current_tool = tool_id
	if is_instance_valid(character) and character.has_method("set_active_tool"):
		character.set_active_tool(tool_id)


func _on_seed_selected(flower_id: String) -> void:
	current_seed = flower_id
	current_tool = "plant"
	if is_instance_valid(character) and character.has_method("set_active_tool"):
		character.set_active_tool("plant")


func _on_plot_selected(plot: GardenPlot) -> void:
	hud.update_plot_info(plot)


func _on_plot_action_requested(plot: GardenPlot) -> void:
	if is_instance_valid(character) and character.character_enabled:
		character.queue_action_at_plot(plot, current_tool, func() -> void:
			_execute_actual_plot_action(plot)
		)
	else:
		_execute_actual_plot_action(plot)


func _execute_actual_plot_action(plot: GardenPlot) -> void:
	# Smart Context Adaptation when in general Plant tool:
	if current_tool == "plant" and plot.state != GardenPlot.State.EMPTY:
		if plot.state == GardenPlot.State.MATURE:
			plot.harvest()
			return
		elif plot.state == GardenPlot.State.GROWING:
			if plot.growth_progress >= 0.60 and plot.growth_progress <= 0.85 and not plot.is_pruned:
				_execute_prune(plot)
				return
			elif not plot.is_watered:
				_execute_water(plot)
				return

	match current_tool:
		"plant":
			_handle_planting_action(plot)
		"water":
			_execute_water(plot)
		"prune":
			_execute_prune(plot)
		"fertilizer":
			_execute_fertilizer(plot)
		"harvest":
			if plot.state == GardenPlot.State.MATURE:
				plot.harvest()
			else:
				hud.show_toast("Plot is not ready for harvest yet.", Color(0.7, 0.7, 0.7))
		_:
			pass


func _execute_water(plot: GardenPlot) -> void:
	if plot.state == GardenPlot.State.GROWING:
		if plot.water():
			hud.show_toast("💧 Soil Watered! Growth speed +60%.", Color(0.4, 0.8, 1.0))
			if active_upgrades.get("double_sprinkler", false):
				_water_adjacent_plot(plot)
	else:
		hud.show_toast("Nothing growing here to water.", Color(0.7, 0.7, 0.7))


func _execute_prune(plot: GardenPlot) -> void:
	if plot.state == GardenPlot.State.GROWING:
		if plot.prune():
			hud.show_toast("✂️ Side shoots pruned! Hero Bloom (★★★) forming.", Color(1.0, 0.9, 0.4))
		else:
			hud.show_toast("Already pruned or cannot be pruned.", Color(0.7, 0.7, 0.7))
	else:
		hud.show_toast("Plant must be growing to prune side shoots.", Color(0.7, 0.7, 0.7))


func _execute_fertilizer(plot: GardenPlot) -> void:
	if not active_upgrades.get("fertilizer_box", false):
		_play_sfx("error")
		hud.show_toast("🔒 Unlock Organic Compost Elixir in Upgrades Shop first!", Color(1.0, 0.45, 0.45))
		return

	if plot.state == GardenPlot.State.GROWING:
		if plot.apply_fertilizer():
			hud.show_toast("🧪 Applied Organic Compost Elixir! Growth accelerated.", Color(0.35, 0.95, 0.55))
		else:
			hud.show_toast("Plot already fertilized.", Color(0.7, 0.7, 0.7))
	else:
		hud.show_toast("Plant must be growing to apply fertilizer.", Color(0.7, 0.7, 0.7))


func _on_plot_prune_window_opened(plot: GardenPlot) -> void:
	_play_sfx("click", 0.08, -2.0)
	hud.show_toast("✂️ Plot #%d is ready for pruning (Hero Bloom ★★★)! [Press 3]" % (plot.plot_index + 1), Color(1.0, 0.9, 0.4))


func _water_adjacent_plot(target_plot: GardenPlot) -> void:
	if not is_instance_valid(garden_grid):
		return
	var plots: Array = garden_grid.plots
	var target_idx: int = plots.find(target_plot)
	if target_idx != -1:
		var adj_idx: int = target_idx + 1 if (target_idx % 2 == 0) else target_idx - 1
		if adj_idx >= 0 and adj_idx < plots.size():
			var adj_plot: GardenPlot = plots[adj_idx] as GardenPlot
			if adj_plot != null and adj_plot.state == GardenPlot.State.GROWING and not adj_plot.is_watered:
				adj_plot.water()


func _apply_all_active_upgrades() -> void:
	if upgrade_manager != null:
		upgrade_manager.apply_all_active_upgrades(character, garden_grid, inventory)


func _apply_upgrade_effect(upgrade_id: String) -> void:
	if upgrade_manager != null:
		upgrade_manager.apply_upgrade_effect(upgrade_id, character, garden_grid, inventory)


func _on_upgrade_purchased(upgrade_id: String) -> void:
	if upgrade_manager == null:
		return
	var res := upgrade_manager.purchase(upgrade_id, coins)
	if res.get("success", false):
		coins -= int(res["cost"])
		if upgrade_id == "expanded_satchel":
			inventory["rose"] = inventory.get("rose", 0) + 3
			inventory["tulip"] = inventory.get("tulip", 0) + 3
			inventory["daisy"] = inventory.get("daisy", 0) + 3
		upgrade_manager.apply_upgrade_effect(upgrade_id, character, garden_grid, inventory)
		_sync_hud_state()
		_play_sfx("upgrade")
		var up_data: Dictionary = res.get("upgrade_data", {})
		hud.show_toast("🛠️ Upgraded: %s!" % up_data.get("name", upgrade_id), Color(0.4, 1.0, 0.6))
		_save_game_state()
	else:
		_play_sfx("error")
		hud.show_toast(res.get("error", "Cannot purchase upgrade!"), Color(0.9, 0.4, 0.4))


func _handle_planting_action(plot: GardenPlot) -> void:
	if plot.state != GardenPlot.State.EMPTY:
		hud.show_toast("This plot is already occupied!", Color(0.9, 0.4, 0.4))
		return

	if current_seed == "mystery_seed":
		if unknown_hybrid_seeds.is_empty():
			hud.show_toast("No Mystery Hybrid Seeds available! Cross-breed in the Breeding Lab.", Color(0.9, 0.7, 0.4))
			return
		
		var next_species: String = unknown_hybrid_seeds.pop_front()
		var next_specimen: FlowerSpecimen = null
		if not unknown_hybrid_specimens.is_empty():
			next_specimen = unknown_hybrid_specimens.pop_front()
		else:
			next_specimen = GeneticsEngine.create_starter_specimen(next_species)

		if plot.plant(next_species, true, next_specimen):
			hud.show_toast("Planted an Unknown Mystery Hybrid Seed!", Color(1.0, 0.9, 0.4))
			_sync_hud_state()
	else:
		var starter_sp := GeneticsEngine.create_starter_specimen(current_seed)
		if plot.plant(current_seed, false, starter_sp):
			var data: Dictionary = FlowerData.get_flower(current_seed)
			hud.show_toast("Planted %s." % data.get("display_name", "Flower"), Color(0.6, 0.9, 0.6))


func _on_flower_harvested(flower_id: String, count: int) -> void:
	if not inventory.has(flower_id):
		inventory[flower_id] = 0
	inventory[flower_id] += count
	_sync_hud_state()
	_save_game_state()


func _on_preserve_plot_requested(plot: GardenPlot) -> void:
	if plot.state != GardenPlot.State.MATURE or plot.current_specimen == null:
		return

	if breeding_roster.size() >= 12:
		hud.show_toast("Breeding Stock is full (12/12)! Release a specimen first.", Color(0.95, 0.55, 0.55))
		return

	var preserved: FlowerSpecimen = plot.preserve_for_breeding()
	if preserved != null:
		breeding_roster.append(preserved)
		hud.show_toast("Preserved %s to Breeding Stock!" % preserved.nickname, Color(0.65, 0.95, 0.75))
		_sync_hud_state()
		_save_game_state()


func _on_harvest_plot_requested(plot: GardenPlot) -> void:
	if plot.state == GardenPlot.State.MATURE:
		plot.harvest()


func _on_release_specimen_requested(specimen_id: String) -> void:
	var idx := -1
	for i in range(breeding_roster.size()):
		if breeding_roster[i].specimen_id == specimen_id:
			idx = i
			break
	if idx >= 0:
		var removed: FlowerSpecimen = breeding_roster[idx]
		breeding_roster.remove_at(idx)
		hud.show_toast("Released %s from Breeding Stock." % removed.specimen_id, Color(0.8, 0.8, 0.8))
		_sync_hud_state()
		_save_game_state()


func _on_flower_revealed(flower_id: String, plot: GardenPlot) -> void:
	var is_first_discovery: bool = not bool(discovered_flowers.get(flower_id, false))
	discovered_flowers[flower_id] = true
	hud.update_discoveries(discovered_flowers)

	if is_first_discovery:
		hud.show_discovery_modal(flower_id)
	else:
		var f_data := FlowerData.get_flower(flower_id)
		var sp_id := plot.current_specimen.specimen_id if plot.current_specimen != null else ""
		hud.show_toast("Harvested %s (%s)" % [f_data.get("display_name", flower_id), sp_id], Color(0.7, 0.95, 0.7))
	_save_game_state()


func _on_breed_requested(parent_a_id: String, parent_b_id: String, rng_seed: int) -> void:
	var specimen_a: FlowerSpecimen = null
	var specimen_b: FlowerSpecimen = null
	var deduct_inventory_a: String = ""
	var deduct_inventory_b: String = ""

	# 1. Direct match by specimen_id in breeding_roster (Preserved Stock)
	for spec in breeding_roster:
		if is_instance_valid(spec):
			if spec.specimen_id == parent_a_id and specimen_a == null:
				specimen_a = spec
			elif spec.specimen_id == parent_b_id and specimen_b == null:
				specimen_b = spec

	# 2. If parent_a_id is a species from garden inventory:
	if specimen_a == null:
		var needed_a := 2 if parent_a_id == parent_b_id else 1
		if inventory.get(parent_a_id, 0) >= needed_a:
			for spec in breeding_roster:
				if is_instance_valid(spec) and spec.species_id == parent_a_id:
					specimen_a = spec
					break
			if specimen_a == null:
				specimen_a = GeneticsEngine.create_starter_specimen(parent_a_id)
			deduct_inventory_a = parent_a_id

	# 3. If parent_b_id is a species from garden inventory:
	if specimen_b == null:
		var available_b: int = inventory.get(parent_b_id, 0)
		if deduct_inventory_a == parent_b_id:
			available_b -= 1
		if available_b >= 1:
			for spec in breeding_roster:
				if is_instance_valid(spec) and spec.species_id == parent_b_id and (spec != specimen_a or parent_a_id != parent_b_id):
					specimen_b = spec
					break
			if specimen_b == null:
				specimen_b = GeneticsEngine.create_starter_specimen(parent_b_id)
			deduct_inventory_b = parent_b_id

	if specimen_a == null or specimen_b == null:
		_play_sfx("error")
		if hud != null:
			hud.show_toast("Parent specimens or required inventory flowers not available!", Color(0.9, 0.4, 0.4))
		return

	var cross_result: Dictionary = GeneticsEngine.cross_specimens(specimen_a, specimen_b, rng_seed)
	var hybrid_species: String = cross_result.get("species", "")
	var offspring: FlowerSpecimen = cross_result.get("specimen", null)

	if hybrid_species.is_empty() or offspring == null:
		_play_sfx("error")
		if hud != null:
			hud.show_toast("These parent species cannot produce a viable hybrid!", Color(0.9, 0.6, 0.4))
		return

	# Deduct inventory if used from garden harvest
	if not deduct_inventory_a.is_empty():
		inventory[deduct_inventory_a] = max(0, inventory.get(deduct_inventory_a, 0) - 1)
	if not deduct_inventory_b.is_empty():
		inventory[deduct_inventory_b] = max(0, inventory.get(deduct_inventory_b, 0) - 1)

	unknown_hybrid_seeds.append(hybrid_species)
	unknown_hybrid_specimens.append(offspring)

	_play_sfx("upgrade")
	_sync_hud_state()
	if hud != null:
		hud.show_toast("✨ Bred seed %s (%s)! Plant it from the Seed Tray to reveal traits." % [
			offspring.specimen_id,
			FlowerData.get_flower(hybrid_species).get("display_name", hybrid_species)
		], Color(0.95, 0.88, 0.45))
	_save_game_state()


func _on_craft_bouquet_requested(bouquet_id: String) -> void:
	var check := BouquetData.check_ingredients(bouquet_id, inventory)
	if not check["can_craft"]:
		hud.show_toast("Missing ingredients for %s!" % BouquetData.get_bouquet(bouquet_id).get("display_name", bouquet_id), Color(0.9, 0.4, 0.4))
		return

	var b_data := BouquetData.get_bouquet(bouquet_id)
	var ingredients: Dictionary = b_data.get("ingredients", {})
	for flower_id in ingredients:
		var needed: int = int(ingredients[flower_id])
		inventory[flower_id] -= needed

	if not bouquet_inventory.has(bouquet_id):
		bouquet_inventory[bouquet_id] = 0
	bouquet_inventory[bouquet_id] += 1

	_sync_hud_state()
	hud.show_toast("💐 Crafted 1 %s!" % b_data.get("display_name", bouquet_id), Color(0.95, 0.80, 0.90))
	_save_game_state()


func _on_fulfill_request_requested(order_id: String) -> void:
	if order_manager == null:
		return

	var res := order_manager.fulfill_order(order_id, inventory, bouquet_inventory)
	if not res.get("success", false):
		_play_sfx("error")
		hud.show_toast("Cannot fulfill order: missing required items!", Color(0.9, 0.4, 0.4))
		return

	var total_earned: int = int(res.get("total_coins", 25))
	var tip_earned: int = int(res.get("tip_coins", 0))
	coins += total_earned

	_play_sfx("coin")
	if is_instance_valid(character) and character.has_method("play_action"):
		character.play_action("celebrate", 1.2)

	_sync_hud_state()
	var tip_msg := " (+%d Tip!)" % tip_earned if tip_earned > 0 else ""
	var combo_msg := " [🔥 Combo x%d]" % combo_count if combo_count > 1 else ""
	hud.show_toast("💰 Order completed! Earned +%d Coins%s%s from %s." % [
		total_earned, tip_msg, combo_msg, res.get("customer_name", "Customer")
	], Color(0.98, 0.88, 0.35))

	if is_instance_valid(hud) and hud.has_method("show_floating_reward"):
		var reward_str := "+%d 🪙" % total_earned
		if tip_earned > 0:
			reward_str += " (+%d Tip!)" % tip_earned
		var spawn_p: Vector2 = get_viewport_rect().size * 0.5
		if is_instance_valid(character):
			spawn_p = character.get_global_transform_with_canvas().origin + Vector2(0, -50)
		hud.show_floating_reward(reward_str, spawn_p, Color(1.0, 0.9, 0.3))

	_save_game_state()


func _on_zoom_in() -> void:
	if is_instance_valid(camera):
		camera.zoom_in()


func _on_zoom_out() -> void:
	if is_instance_valid(camera):
		camera.zoom_out()


func _on_reset_camera() -> void:
	if is_instance_valid(camera):
		camera.reset_camera()


func _on_speed_changed(multiplier: float) -> void:
	global_speed_multiplier = multiplier
	if is_instance_valid(garden_grid):
		garden_grid.set_speed_multiplier(multiplier)
	if is_instance_valid(hud):
		hud.show_toast("Pacing set to %.0fx" % multiplier, Color(0.85, 0.95, 0.85))


func _on_layout_preset_changed(preset_idx: int) -> void:
	if is_instance_valid(garden_grid):
		garden_grid.switch_layout(preset_idx)
		var preset_name: String = GardenLayoutManagerScript.PRESET_NAMES.get(preset_idx, "Custom Layout")
		hud.show_toast("Switched layout to %s." % preset_name, Color(0.85, 0.95, 0.85))


func _on_perspective_changed(mode: int) -> void:
	if is_instance_valid(garden_grid):
		garden_grid.set_perspective_mode(mode)
	if is_instance_valid(environment):
		environment.perspective_mode = mode
		environment.queue_redraw()
	var mode_name := "3/4 Angled Depth" if mode == 1 else "Top-Down (2D)"
	hud.show_toast("Perspective set to %s." % mode_name, Color(0.85, 0.95, 1.0))


func _on_character_toggled(enabled: bool) -> void:
	if is_instance_valid(character):
		character.character_enabled = enabled
	var char_state := "enabled" if enabled else "disabled"
	hud.show_toast("Gardener character %s." % char_state, Color(0.9, 0.9, 0.7))


func _start_ambient_music() -> void:
	if is_inside_tree() and has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am != null and am.has_method("play_music"):
			am.play_music("garden", 1.5)


func _play_sfx(sfx_name: String, pitch_randomness: float = 0.06, volume_offset_db: float = 0.0) -> void:
	if is_inside_tree() and has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.play_sfx(sfx_name, pitch_randomness, volume_offset_db)
