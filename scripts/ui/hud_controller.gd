class_name HudController
extends CanvasLayer

## Rich, responsive HUD for Milestone P3 with Trait Genetics, Breeding Roster (12-slot max),
## Specimen Inspector, upgraded Breeding Lab, and non-clipping toast notifications.

signal tool_selected(tool_id: String)
signal seed_selected(flower_id: String)
signal zoom_in_requested()
signal zoom_out_requested()
signal reset_camera_requested()
signal speed_changed(multiplier: float)
signal breed_requested(parent_a_id: String, parent_b_id: String, rng_seed: int)
signal craft_bouquet_requested(bouquet_id: String)
signal fulfill_request_requested(order_id: String)
signal preserve_plot_requested(plot: GardenPlot)
signal harvest_plot_requested(plot: GardenPlot)
signal release_specimen_requested(specimen_id: String)
signal layout_preset_changed(preset: int)
signal perspective_changed(mode: int)
signal character_toggled(enabled: bool)
signal upgrade_purchased(upgrade_id: String)
signal quick_sell_requested(flower_id: String, count: int)
signal sell_all_requested()

@export var current_tool: String = "plant"
@export var current_seed: String = "rose"

var _root_control: Control = null
var _tool_buttons: Dictionary = {}
var _seed_buttons: Dictionary = {}
var _inv_labels: Dictionary = {}

# Modular Storybook HUD components (Fiona Finch style)
const SideOrderRailScript := preload("res://scripts/ui/hud/side_order_rail.gd")
const LilyHubPopupScript := preload("res://scripts/ui/hud/lily_hub_popup.gd")
const InventoryDrawerScript := preload("res://scripts/ui/hud/inventory_drawer.gd")

var _side_order_rail: Control = null
var _lily_hub: Control = null
var _inventory_drawer: Control = null

# Enhanced Plot Card elements
var _stage_seed: Label = null
var _stage_sprout: Label = null
var _stage_young: Label = null
var _stage_bloom: Label = null
var _plot_droplets_lbl: Label = null
var _plot_prune_alert_box: PanelContainer = null
var _plot_prune_alert_lbl: Label = null

const UpgradesModalScene := preload("res://scenes/ui/modals/upgrades_modal.tscn")
const RequestsModalScene := preload("res://scenes/ui/modals/requests_modal.tscn")
const BouquetModalScene := preload("res://scenes/ui/modals/bouquet_modal.tscn")
const BreedingModalScene := preload("res://scenes/ui/modals/breeding_modal.tscn")
const JournalModalScene := preload("res://scenes/ui/modals/journal_modal.tscn")

var _upgrades_modal_instance: UpgradesModal = null
var _requests_modal_instance: RequestsModal = null
var _bouquets_modal_instance: BouquetModal = null
var _breeding_modal_instance: BreedingModal = null
var _journal_modal_instance: JournalModal = null
var _cached_upgrades: Dictionary = {}

var _upgrades_overlay: Control = null
var _upgrades_modal: PanelContainer = null
var _upgrades_btn: Button = null
var _upgrades_list_box: VBoxContainer = null

# P4 Visual Lab references
const ModularFlowerVisualScript := preload("res://scripts/flowers/modular_flower_visual.gd")

var _is_beauty_mode: bool = false
var _bottom_toolbar_node: Control = null
var _utility_controls_node: Control = null

var _visual_lab_overlay: Control = null
var _visual_lab_modal: PanelContainer = null
var _visual_lab_btn: Button = null
var _selected_hybrid_cross: String = "roselight"
var _selected_strategy: int = 2 # 0: Whole-Authored, 1: Full Modular, 2: Curated Hybrid
var _visual_preview_parent_a: Node2D = null
var _visual_preview_parent_b: Node2D = null
var _visual_preview_hybrid: Node2D = null
var _parent_a_title_lbl: Label = null
var _parent_b_title_lbl: Label = null
var _hybrid_title_lbl: Label = null
var _provenance_container: VBoxContainer = null
var _same_species_container: HBoxContainer = null
var _strategy_desc_lbl: Label = null
var _char_toggle_btn: Button = null
var _persp_toggle_btn: Button = null
var _active_layout_preset: int = 0
var _active_perspective: int = 0
var _is_character_enabled: bool = true

var _plot_info_card: PanelContainer = null
var _plot_info_title: Label = null
var _plot_info_desc: Label = null
var _plot_growth_bar: ProgressBar = null
var _plot_water_badge: Label = null
var _plot_actions_box: HBoxContainer = null
var _plot_harvest_btn: Button = null
var _plot_preserve_btn: Button = null

# Storybook Wood & Parchment Modular UI Instances
var _top_left_cluster: TopLeftCluster = null
var _tool_dock_instance: ToolDock = null
var _seed_bar_instance: SeedBar = null
var _plot_card_instance: PlotCard = null

var _toast_container: VBoxContainer = null
var _selected_plot_ref: GardenPlot = null

# Toast deduplication guard state
var _last_toast_message: String = ""
var _last_toast_time_msec: int = 0

# Modal Overlays
var _requests_overlay: Control = null
var _bouquets_overlay: Control = null
var _breeding_overlay: Control = null
var _journal_overlay: Control = null
var _discovery_overlay: Control = null
var _inspector_overlay: Control = null
var _reveal_overlay: Control = null

# Modals
var _requests_modal: PanelContainer = null
var _bouquets_modal: PanelContainer = null
var _breeding_modal: PanelContainer = null
var _journal_modal: PanelContainer = null
var _discovery_modal: PanelContainer = null
var _inspector_modal: PanelContainer = null
var _reveal_modal: PanelContainer = null

# Top Bar Nav references
var _requests_btn: Button = null
var _bouquets_btn: Button = null
var _journal_btn: Button = null
var _breeding_btn: Button = null
var _coins_lbl: Label = null

# Requests UI references
var _requests_cards_container: GridContainer = null

# Bouquet UI references
var _bouquets_cards_container: GridContainer = null

# Breeding UI state (P3 Reusable Breeding Roster)
var _selected_parent_a_id: String = ""
var _selected_parent_b_id: String = ""
var _parent_card_a: PanelContainer = null
var _parent_card_b: PanelContainer = null
var _roster_cards_container: GridContainer = null
var _breed_action_btn: Button = null
var _breed_fee_lbl: Label = null
var _breed_preview_lbl: Label = null
var _roster_count_lbl: Label = null

# Journal UI references
var _journal_progress_lbl: Label = null
var _journal_cards_container: GridContainer = null

# Specimen Inspector references
var _inspector_specimen: FlowerSpecimen = null
var _inspector_flower_visual: FlowerVisual = null
var _inspector_title_lbl: Label = null
var _inspector_gen_lbl: Label = null
var _inspector_color_lbl: Label = null
var _inspector_petal_lbl: Label = null
var _inspector_fragrance_lbl: Label = null
var _inspector_vigor_lbl: Label = null
var _inspector_pedigree_lbl: Label = null
var _inspector_raw_genotype_lbl: Label = null
var _inspector_show_raw_genes: bool = false

# Offspring Reveal references
var _reveal_specimen: FlowerSpecimen = null
var _reveal_flower_visual: FlowerVisual = null
var _reveal_title_lbl: Label = null
var _reveal_species_lbl: Label = null
var _reveal_traits_lbl: Label = null
var _reveal_preserve_btn: Button = null
var _reveal_harvest_btn: Button = null

# Cached game state
var _cached_inventory: Dictionary = {}
var _cached_bouquets: Dictionary = {}
var _cached_coins: int = 0
var _cached_completed_requests: Dictionary = {}
var _cached_discovered: Dictionary = {}
var _cached_unknown_seeds: int = 0
var _cached_breeding_roster: Array[FlowerSpecimen] = []


func _ready() -> void:
	_build_hud_ui()
	_build_requests_modal()
	_build_bouquets_modal()
	_build_breeding_modal()
	_build_journal_modal()
	_build_discovery_modal()
	_build_inspector_modal()
	_build_reveal_modal()
	_build_visual_lab_modal()
	_build_upgrades_modal()
	_update_tool_buttons_visual()
	_update_seed_buttons_visual()


func _build_hud_ui() -> void:
	_root_control = Control.new()
	_root_control.name = "Root"
	_root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.theme = preload("res://assets/ui/garden_theme.tres")
	add_child(_root_control)

	var margin := MarginContainer.new()
	margin.name = "SafeArea"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_root_control.add_child(margin)

	# --- SLIM STORYBOOK TOP BAR ---
	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(top_bar)

	# Left: Storybook Title & Subtitle Badge
	var header_box := VBoxContainer.new()
	header_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_box.add_theme_constant_override("separation", 1)
	top_bar.add_child(header_box)

	var title_lbl := Label.new()
	title_lbl.text = "🌻 BloomHaven"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.98, 0.94, 0.82, 1.0))
	header_box.add_child(title_lbl)

	var badge_lbl := Label.new()
	badge_lbl.text = "Cozy Botanical Haven"
	badge_lbl.add_theme_font_size_override("font_size", 9)
	badge_lbl.add_theme_color_override("font_color", Color(0.65, 0.88, 0.70, 0.9))
	header_box.add_child(badge_lbl)

	# Spacer (gives center garden 75% free view)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(spacer)

	# Top Right: Coins Purse, Satchel Button, Beauty & Settings
	var top_right_hbox := HBoxContainer.new()
	top_right_hbox.name = "TopRightHBox"
	top_right_hbox.add_theme_constant_override("separation", 6)
	top_bar.add_child(top_right_hbox)

	_coins_lbl = _create_currency_badge(top_right_hbox, "Gold", 0)

	var satchel_btn := Button.new()
	satchel_btn.name = "SatchelBtn"
	satchel_btn.text = "🌸 Stand & Satchel"
	satchel_btn.tooltip_text = "Flower Stand: Quick Sell harvested flowers for instant coins or inspect satchel"
	satchel_btn.custom_minimum_size = Vector2(130, 30)
	satchel_btn.add_theme_font_size_override("font_size", 11)
	satchel_btn.pressed.connect(func():
		if is_instance_valid(_inventory_drawer):
			_inventory_drawer.toggle()
	)
	top_right_hbox.add_child(satchel_btn)

	var beauty_btn := _create_action_button(top_right_hbox, "🌿", "beauty_view", func(_id: String) -> void: toggle_beauty_mode())
	beauty_btn.tooltip_text = "Toggle Clean Garden Presentation"
	beauty_btn.custom_minimum_size = Vector2(34, 30)

	var settings_btn := Button.new()
	settings_btn.name = "SettingsBtn"
	settings_btn.text = "⚙️"
	settings_btn.custom_minimum_size = Vector2(34, 30)
	settings_btn.pressed.connect(func():
		var p = get_parent()
		if p != null and p.has_method("_toggle_pause_menu"):
			p._toggle_pause_menu()
		_play_sfx("click")
	)
	top_right_hbox.add_child(settings_btn)

	# --- MODULAR STORYBOOK COMPONENTS ---
	_inventory_drawer = preload("res://scenes/ui/hud/inventory_drawer.tscn").instantiate()
	_inventory_drawer.visible = false
	if _inventory_drawer.has_signal("quick_sell_requested"):
		_inventory_drawer.connect("quick_sell_requested", func(f_id: String, count: int) -> void:
			quick_sell_requested.emit(f_id, count)
		)
	if _inventory_drawer.has_signal("sell_all_requested"):
		_inventory_drawer.connect("sell_all_requested", func() -> void:
			sell_all_requested.emit()
		)
	_root_control.add_child(_inventory_drawer)

	_side_order_rail = preload("res://scenes/ui/hud/side_order_rail.tscn").instantiate()
	_side_order_rail.fulfill_requested.connect(func(o_id: String) -> void:
		fulfill_request_requested.emit(o_id)
	)
	_root_control.add_child(_side_order_rail)

	_lily_hub = preload("res://scenes/ui/hud/lily_hub_popup.tscn").instantiate()
	_lily_hub.visible = false
	_lily_hub.open_journal_requested.connect(open_journal_modal)
	_lily_hub.open_upgrades_requested.connect(open_upgrades_modal)
	_lily_hub.open_breeding_requested.connect(open_breeding_modal)
	_lily_hub.open_bouquets_requested.connect(open_bouquets_modal)
	_root_control.add_child(_lily_hub)

	# Hidden backwards-compatibility dummy container
	var dummy_compat := Control.new()
	dummy_compat.name = "LegacyCompat"
	dummy_compat.visible = false
	_root_control.add_child(dummy_compat)

	_requests_btn = Button.new()
	dummy_compat.add_child(_requests_btn)
	_bouquets_btn = Button.new()
	dummy_compat.add_child(_bouquets_btn)
	_journal_btn = Button.new()
	dummy_compat.add_child(_journal_btn)
	_breeding_btn = Button.new()
	dummy_compat.add_child(_breeding_btn)
	_upgrades_btn = Button.new()
	dummy_compat.add_child(_upgrades_btn)
	_visual_lab_btn = Button.new()
	dummy_compat.add_child(_visual_lab_btn)

	for fid in ["rose", "tulip", "daisy", "lavender", "sunflower", "bouquets", "unknown_seed"]:
		var lbl := Label.new()
		dummy_compat.add_child(lbl)
		_inv_labels[fid] = lbl

	# Bottom Center: Main Toolbar & Seed Selector
	_build_bottom_toolbar(margin)

	# Bottom Right: Plot Inspector Card
	_build_plot_inspector(margin)

	# Bottom Left: Camera & Speed Controls
	_build_utility_controls(margin)

	# Hide legacy flat elements
	top_bar.visible = false
	if is_instance_valid(_bottom_toolbar_node):
		_bottom_toolbar_node.visible = false
	if is_instance_valid(_plot_info_card):
		_plot_info_card.visible = false

	# --- STORYBOOK MASTER ASSETS HUD INTEGRATION ---
	# 1. Top-Left Wood Sign, Coins & Satchel Cluster
	_top_left_cluster = preload("res://scenes/ui/hud/top_left_cluster.tscn").instantiate()
	_root_control.add_child(_top_left_cluster)
	_top_left_cluster.satchel_toggle_requested.connect(func():
		if is_instance_valid(_inventory_drawer):
			_inventory_drawer.toggle()
	)
	_top_left_cluster.settings_requested.connect(func():
		var p = get_parent()
		if p != null and p.has_method("_toggle_pause_menu"):
			p._toggle_pause_menu()
		_play_sfx("click")
	)
	_top_left_cluster.coins_plus_requested.connect(func():
		open_upgrades_modal()
	)

	# 2. Bottom Center Tool Dock & Lily Cameo Hub
	_tool_dock_instance = preload("res://scenes/ui/tool_dock.tscn").instantiate()
	_root_control.add_child(_tool_dock_instance)
	_tool_dock_instance.tool_changed.connect(func(t_name: String):
		_on_tool_btn_pressed(t_name)
	)
	_tool_dock_instance.lily_hub_toggle_requested.connect(func():
		if is_instance_valid(_lily_hub):
			_lily_hub.toggle()
	)
	_tool_dock_instance.seeds_toggle_requested.connect(func():
		if is_instance_valid(_seed_bar_instance):
			_seed_bar_instance.toggle()
	)

	# 3. Bottom Right Seed Box Cabinet
	_seed_bar_instance = preload("res://scenes/ui/seed_bar.tscn").instantiate()
	_root_control.add_child(_seed_bar_instance)
	_seed_bar_instance.seed_changed.connect(func(s_id: String):
		_on_seed_btn_pressed(s_id)
	)

	# 4. Bottom Left Weathered Parchment Plot Info Card
	_plot_card_instance = preload("res://scenes/ui/plot_card.tscn").instantiate()
	_root_control.add_child(_plot_card_instance)

	# Top-Centered Responsive Non-Clipping Toast Notification Wrapper
	var toast_wrapper := CenterContainer.new()
	toast_wrapper.name = "ToastWrapper"
	toast_wrapper.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toast_wrapper.offset_top = 80
	toast_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.add_child(toast_wrapper)

	_toast_container = VBoxContainer.new()
	_toast_container.name = "ToastContainer"
	_toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_container.add_theme_constant_override("separation", 4)
	toast_wrapper.add_child(_toast_container)


func _create_currency_badge(parent: HBoxContainer, label_name: String, initial_val: int) -> Label:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.13, 0.05, 0.95)
	style.set_border_width_all(1)
	style.border_color = Color(1.0, 0.85, 0.30, 0.85)
	style.set_corner_radius_all(8)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	panel.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = "💰"
	icon_lbl.add_theme_font_size_override("font_size", 11)
	hbox.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = label_name + ":"
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65))
	hbox.add_child(name_lbl)

	var count_lbl := Label.new()
	count_lbl.text = str(initial_val)
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))
	hbox.add_child(count_lbl)

	parent.add_child(panel)
	return count_lbl


func _create_inventory_badge(
	parent: HBoxContainer,
	icon: String,
	flower_name: String,
	initial_count: int,
	color_tint: Color
) -> Label:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.15, 0.10, 0.88)
	style.set_border_width_all(1)
	style.border_color = color_tint.darkened(0.2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	panel.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 11)
	icon_lbl.add_theme_color_override("font_color", color_tint)
	hbox.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = flower_name + ":"
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.76))
	hbox.add_child(name_lbl)

	var count_lbl := Label.new()
	count_lbl.text = str(initial_count)
	count_lbl.add_theme_font_size_override("font_size", 11)
	count_lbl.add_theme_color_override("font_color", color_tint)
	hbox.add_child(count_lbl)

	parent.add_child(panel)
	return count_lbl


func _build_bottom_toolbar(margin: MarginContainer) -> void:
	var bottom_center := VBoxContainer.new()
	bottom_center.name = "BottomToolbar"
	_bottom_toolbar_node = bottom_center
	bottom_center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bottom_center.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom_center.add_theme_constant_override("separation", 6)
	margin.add_child(bottom_center)

	# Seed Selection Bar (Toggleable drawer)
	var seed_panel := PanelContainer.new()
	seed_panel.name = "SeedSelectionBar"
	seed_panel.visible = false
	var seed_style := StyleBoxFlat.new()
	seed_style.bg_color = Color(0.06, 0.12, 0.08, 0.95)
	seed_style.set_border_width_all(1)
	seed_style.border_color = Color(0.35, 0.60, 0.40, 0.9)
	seed_style.set_corner_radius_all(10)
	seed_style.content_margin_left = 12
	seed_style.content_margin_right = 12
	seed_style.content_margin_top = 5
	seed_style.content_margin_bottom = 5
	seed_panel.add_theme_stylebox_override("panel", seed_style)

	var seed_hbox := HBoxContainer.new()
	seed_hbox.add_theme_constant_override("separation", 8)
	seed_panel.add_child(seed_hbox)

	var seed_title := Label.new()
	seed_title.text = "🌱 Select Seed:"
	seed_title.add_theme_font_size_override("font_size", 12)
	seed_title.add_theme_color_override("font_color", Color(0.65, 0.85, 0.70))
	seed_hbox.add_child(seed_title)

	_seed_buttons["rose"] = _create_choice_button(seed_hbox, "🌹 Rose", "rose", _on_seed_btn_pressed)
	_seed_buttons["tulip"] = _create_choice_button(seed_hbox, "🌷 Tulip", "tulip", _on_seed_btn_pressed)
	_seed_buttons["daisy"] = _create_choice_button(seed_hbox, "🌼 Daisy", "daisy", _on_seed_btn_pressed)
	_seed_buttons["lavender"] = _create_choice_button(seed_hbox, "🪻 Lavender", "lavender", _on_seed_btn_pressed)
	_seed_buttons["sunflower"] = _create_choice_button(seed_hbox, "🌻 Sunflower", "sunflower", _on_seed_btn_pressed)
	
	_seed_buttons["mystery_seed"] = _create_choice_button(seed_hbox, "★ Mystery (0)", "mystery_seed", _on_seed_btn_pressed)
	_seed_buttons["mystery_seed"].modulate = Color(1.1, 1.0, 0.6)

	bottom_center.add_child(seed_panel)

	# Main Tool Action Bar (Gardener's Personal Tool Tray)
	var tool_panel := PanelContainer.new()
	var tool_style := StyleBoxFlat.new()
	tool_style.bg_color = Color(0.08, 0.14, 0.10, 0.96)
	tool_style.set_border_width_all(1)
	tool_style.border_color = Color(0.75, 0.62, 0.32, 0.85) # Warm Gold Rim
	tool_style.set_corner_radius_all(12)
	tool_style.content_margin_left = 12
	tool_style.content_margin_right = 12
	tool_style.content_margin_top = 6
	tool_style.content_margin_bottom = 6
	tool_panel.add_theme_stylebox_override("panel", tool_style)

	var tool_hbox := HBoxContainer.new()
	tool_hbox.add_theme_constant_override("separation", 8)
	tool_panel.add_child(tool_hbox)

	_tool_buttons["plant"] = _create_choice_button(tool_hbox, "🪣 Plant [1]", "plant", _on_tool_btn_pressed)
	_tool_buttons["water"] = _create_choice_button(tool_hbox, "🚿 Water [2]", "water", _on_tool_btn_pressed)
	_tool_buttons["prune"] = _create_choice_button(tool_hbox, "✂️ Prune [3]", "prune", _on_tool_btn_pressed)
	_tool_buttons["harvest"] = _create_choice_button(tool_hbox, "🧺 Harvest [4]", "harvest", _on_tool_btn_pressed)
	_tool_buttons["fertilizer"] = _create_choice_button(tool_hbox, "🧪 Fert [5]", "fertilizer", _on_tool_btn_pressed)

	var sep := VSeparator.new()
	tool_hbox.add_child(sep)

	var seeds_btn := Button.new()
	seeds_btn.name = "ToggleSeedsBtn"
	seeds_btn.text = "🌱 Seeds"
	seeds_btn.custom_minimum_size = Vector2(74, 32)
	seeds_btn.add_theme_font_size_override("font_size", 11)
	seeds_btn.pressed.connect(func():
		seed_panel.visible = not seed_panel.visible
		_play_sfx("click")
	)
	tool_hbox.add_child(seeds_btn)

	var lily_btn := Button.new()
	lily_btn.name = "LilyHubBtn"
	lily_btn.text = "👒 Lily"
	lily_btn.custom_minimum_size = Vector2(80, 32)
	lily_btn.add_theme_font_size_override("font_size", 12)
	lily_btn.add_theme_color_override("font_color", Color(1.0, 0.94, 0.75))
	lily_btn.pressed.connect(func():
		if is_instance_valid(_lily_hub):
			_lily_hub.toggle()
		_play_sfx("click")
	)
	tool_hbox.add_child(lily_btn)

	bottom_center.add_child(tool_panel)


func _build_plot_inspector(margin: MarginContainer) -> void:
	_plot_info_card = PanelContainer.new()
	_plot_info_card.name = "PlotInspector"
	_plot_info_card.size_flags_horizontal = Control.SIZE_SHRINK_END
	_plot_info_card.size_flags_vertical = Control.SIZE_SHRINK_END
	_plot_info_card.custom_minimum_size = Vector2(265, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.14, 0.10, 0.94)
	style.set_border_width_all(1)
	style.border_color = Color(0.85, 0.70, 0.35, 0.75) # Warm Gold rim
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_plot_info_card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_plot_info_card.add_child(vbox)

	_plot_info_title = Label.new()
	_plot_info_title.text = "Garden Plot #1"
	_plot_info_title.add_theme_font_size_override("font_size", 13)
	_plot_info_title.add_theme_color_override("font_color", Color(0.98, 0.94, 0.82))
	vbox.add_child(_plot_info_title)

	# --- Growth Stages Timeline ---
	var timeline_hbox := HBoxContainer.new()
	timeline_hbox.name = "TimelineHBox"
	timeline_hbox.add_theme_constant_override("separation", 3)
	vbox.add_child(timeline_hbox)

	_stage_seed = Label.new()
	_stage_seed.text = "🌱 Seed"
	_stage_seed.add_theme_font_size_override("font_size", 9)
	timeline_hbox.add_child(_stage_seed)

	var arr1 := Label.new()
	arr1.text = "➔"
	arr1.add_theme_font_size_override("font_size", 8)
	arr1.modulate = Color(0.6, 0.6, 0.6)
	timeline_hbox.add_child(arr1)

	_stage_sprout = Label.new()
	_stage_sprout.text = "🌿 Sprout"
	_stage_sprout.add_theme_font_size_override("font_size", 9)
	timeline_hbox.add_child(_stage_sprout)

	var arr2 := Label.new()
	arr2.text = "➔"
	arr2.add_theme_font_size_override("font_size", 8)
	arr2.modulate = Color(0.6, 0.6, 0.6)
	timeline_hbox.add_child(arr2)

	_stage_young = Label.new()
	_stage_young.text = "🌺 Young"
	_stage_young.add_theme_font_size_override("font_size", 9)
	timeline_hbox.add_child(_stage_young)

	var arr3 := Label.new()
	arr3.text = "➔"
	arr3.add_theme_font_size_override("font_size", 8)
	arr3.modulate = Color(0.6, 0.6, 0.6)
	timeline_hbox.add_child(arr3)

	_stage_bloom = Label.new()
	_stage_bloom.text = "🌹 Bloom"
	_stage_bloom.add_theme_font_size_override("font_size", 9)
	timeline_hbox.add_child(_stage_bloom)

	_plot_info_desc = Label.new()
	_plot_info_desc.text = "Status: Empty soil"
	_plot_info_desc.add_theme_font_size_override("font_size", 11)
	_plot_info_desc.add_theme_color_override("font_color", Color(0.65, 0.75, 0.68))
	vbox.add_child(_plot_info_desc)

	_plot_growth_bar = ProgressBar.new()
	_plot_growth_bar.custom_minimum_size = Vector2(0, 12)
	_plot_growth_bar.max_value = 100.0
	_plot_growth_bar.value = 0.0
	_plot_growth_bar.show_percentage = true
	vbox.add_child(_plot_growth_bar)

	# Droplets moisture indicator
	var moist_hbox := HBoxContainer.new()
	moist_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(moist_hbox)

	_plot_droplets_lbl = Label.new()
	_plot_droplets_lbl.text = "💧💧💧 (Hydrated)"
	_plot_droplets_lbl.add_theme_font_size_override("font_size", 10)
	moist_hbox.add_child(_plot_droplets_lbl)

	_plot_water_badge = Label.new()
	_plot_water_badge.text = "Soil: Dry"
	_plot_water_badge.add_theme_font_size_override("font_size", 10)
	_plot_water_badge.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5))
	moist_hbox.add_child(_plot_water_badge)

	# Prune opportunity alert box
	_plot_prune_alert_box = PanelContainer.new()
	_plot_prune_alert_box.name = "PruneAlertBox"
	_plot_prune_alert_box.visible = false
	var alert_style := StyleBoxFlat.new()
	alert_style.bg_color = Color(0.22, 0.18, 0.06, 0.95)
	alert_style.set_border_width_all(1)
	alert_style.border_color = Color(1.0, 0.85, 0.3)
	alert_style.set_corner_radius_all(6)
	alert_style.content_margin_left = 6
	alert_style.content_margin_right = 6
	alert_style.content_margin_top = 3
	alert_style.content_margin_bottom = 3
	_plot_prune_alert_box.add_theme_stylebox_override("panel", alert_style)
	vbox.add_child(_plot_prune_alert_box)

	_plot_prune_alert_lbl = Label.new()
	_plot_prune_alert_lbl.text = "✂️ Prune Now! (★★★ Hero Bloom)"
	_plot_prune_alert_lbl.add_theme_font_size_override("font_size", 10)
	_plot_prune_alert_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	_plot_prune_alert_box.add_child(_plot_prune_alert_lbl)

	# Action buttons for mature flowers (Harvest / Preserve)
	_plot_actions_box = HBoxContainer.new()
	_plot_actions_box.add_theme_constant_override("separation", 6)
	_plot_actions_box.visible = false
	vbox.add_child(_plot_actions_box)

	_plot_harvest_btn = Button.new()
	_plot_harvest_btn.text = "🧺 Harvest (+1)"
	_plot_harvest_btn.add_theme_font_size_override("font_size", 10)
	_plot_harvest_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_plot_harvest_btn.pressed.connect(func() -> void:
		if is_instance_valid(_selected_plot_ref):
			harvest_plot_requested.emit(_selected_plot_ref)
	)
	_plot_actions_box.add_child(_plot_harvest_btn)

	_plot_preserve_btn = Button.new()
	_plot_preserve_btn.text = "🌿 Preserve (Roster)"
	_plot_preserve_btn.add_theme_font_size_override("font_size", 10)
	_plot_preserve_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_plot_preserve_btn.modulate = Color(1.1, 1.0, 0.7)
	_plot_preserve_btn.pressed.connect(func() -> void:
		if is_instance_valid(_selected_plot_ref):
			preserve_plot_requested.emit(_selected_plot_ref)
	)
	_plot_actions_box.add_child(_plot_preserve_btn)

	margin.add_child(_plot_info_card)


func _build_utility_controls(margin: MarginContainer) -> void:
	var bottom_left := VBoxContainer.new()
	bottom_left.name = "UtilityControls"
	_utility_controls_node = bottom_left
	bottom_left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bottom_left.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom_left.add_theme_constant_override("separation", 5)
	margin.add_child(bottom_left)

	# Camera Toolbar
	var cam_panel := PanelContainer.new()
	var cam_style := StyleBoxFlat.new()
	cam_style.bg_color = Color(0.06, 0.12, 0.08, 0.85)
	cam_style.set_border_width_all(1)
	cam_style.border_color = Color(0.18, 0.32, 0.22, 0.7)
	cam_style.set_corner_radius_all(8)
	cam_style.content_margin_left = 6
	cam_style.content_margin_right = 6
	cam_style.content_margin_top = 4
	cam_style.content_margin_bottom = 4
	cam_panel.add_theme_stylebox_override("panel", cam_style)

	var cam_hbox := HBoxContainer.new()
	cam_hbox.add_theme_constant_override("separation", 5)
	cam_panel.add_child(cam_hbox)

	_create_action_button(cam_hbox, "Zoom +", "zoom_in", func(_id: String) -> void: zoom_in_requested.emit())
	_create_action_button(cam_hbox, "Zoom -", "zoom_out", func(_id: String) -> void: zoom_out_requested.emit())
	_create_action_button(cam_hbox, "Reset", "reset_cam", func(_id: String) -> void: reset_camera_requested.emit())

	bottom_left.add_child(cam_panel)

	# Speed Control Toolbar
	var speed_panel := PanelContainer.new()
	speed_panel.add_theme_stylebox_override("panel", cam_style)

	var speed_hbox := HBoxContainer.new()
	speed_hbox.add_theme_constant_override("separation", 5)
	speed_panel.add_child(speed_hbox)

	var speed_lbl := Label.new()
	speed_lbl.text = "Speed:"
	speed_lbl.add_theme_font_size_override("font_size", 10)
	speed_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.65))
	speed_hbox.add_child(speed_lbl)

	_create_action_button(speed_hbox, "1x", "speed_1", func(_id: String) -> void: speed_changed.emit(1.0))
	_create_action_button(speed_hbox, "2x", "speed_2", func(_id: String) -> void: speed_changed.emit(2.0))
	_create_action_button(speed_hbox, "5x", "speed_5", func(_id: String) -> void: speed_changed.emit(5.0))

	bottom_left.add_child(speed_panel)


# =========================================================================
# FLORIST REQUESTS MODAL
# =========================================================================

func _build_requests_modal() -> void:
	_requests_modal_instance = RequestsModalScene.instantiate() as RequestsModal
	_requests_modal_instance.hide()
	_requests_modal_instance.fulfill_requested.connect(func(order_id: String) -> void:
		fulfill_request_requested.emit(order_id)
	)
	_root_control.add_child(_requests_modal_instance)


func open_requests_modal() -> void:
	_close_all_modals()
	if _requests_modal_instance != null:
		var main = get_parent()
		var pat: Dictionary = main.live_orders_patience if main != null and "live_orders_patience" in main else {}
		var combo: int = main.combo_count if main != null and "combo_count" in main else 0
		_requests_modal_instance.open_board(pat, _cached_completed_requests, _cached_inventory, _cached_bouquets, combo)


func close_requests_modal() -> void:
	if _requests_modal_instance != null:
		_requests_modal_instance.hide()


func _update_requests_cards() -> void:
	if _requests_modal_instance != null and _requests_modal_instance.visible:
		var main = get_parent()
		var pat: Dictionary = main.live_orders_patience if main != null and "live_orders_patience" in main else {}
		var combo: int = main.combo_count if main != null and "combo_count" in main else 0
		_requests_modal_instance.open_board(pat, _cached_completed_requests, _cached_inventory, _cached_bouquets, combo)


# =========================================================================
# BOUQUET WORKSHOP MODAL
# =========================================================================

func _build_bouquets_modal() -> void:
	_bouquets_modal_instance = BouquetModalScene.instantiate() as BouquetModal
	_bouquets_modal_instance.hide()
	_bouquets_modal_instance.bouquet_crafted.connect(func(b_id: String) -> void:
		craft_bouquet_requested.emit(b_id)
	)
	_root_control.add_child(_bouquets_modal_instance)


func open_bouquets_modal() -> void:
	_close_all_modals()
	if _bouquets_modal_instance != null:
		_bouquets_modal_instance.open_workshop(_cached_inventory)


func close_bouquets_modal() -> void:
	if _bouquets_modal_instance != null:
		_bouquets_modal_instance.hide()


func _update_bouquets_cards() -> void:
	if _bouquets_modal_instance != null and _bouquets_modal_instance.visible:
		_bouquets_modal_instance.open_workshop(_cached_inventory)


# =========================================================================
# UPGRADED BREEDING LAB & BREEDING ROSTER (12-SLOT MAX) — P3
# =========================================================================

func _build_breeding_modal() -> void:
	_breeding_modal_instance = BreedingModalScene.instantiate() as BreedingModal
	_breeding_modal_instance.hide()
	_breeding_modal_instance.breed_performed.connect(func(pa: String, pb: String, _sa: FlowerSpecimen, _sb: FlowerSpecimen) -> void:
		breed_requested.emit(pa, pb, int(Time.get_ticks_msec()))
	)
	_root_control.add_child(_breeding_modal_instance)


func open_breeding_modal() -> void:
	_close_all_modals()
	if _breeding_modal_instance != null:
		_breeding_modal_instance.open_lab(_cached_breeding_roster, _cached_inventory)


func close_breeding_modal() -> void:
	if _breeding_modal_instance != null:
		_breeding_modal_instance.hide()


func _update_breeding_modal_state() -> void:
	if _breeding_modal_instance != null and _breeding_modal_instance.visible:
		_breeding_modal_instance.open_lab(_cached_breeding_roster, _cached_inventory)


func _find_specimen_in_roster(specimen_id: String) -> FlowerSpecimen:
	for s in _cached_breeding_roster:
		if s.specimen_id == specimen_id:
			return s
	return null


func _get_stars_string(rating: int) -> String:
	match rating:
		1: return "★☆☆☆"
		2: return "★★☆☆"
		3: return "★★★☆"
		4: return "★★★★"
		_: return "★★☆☆"


# =========================================================================
# SPECIMEN INSPECTOR CARD MODAL — P3
# =========================================================================

func _build_inspector_modal() -> void:
	_inspector_overlay = Control.new()
	_inspector_overlay.name = "InspectorOverlay"
	_inspector_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_inspector_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_inspector_overlay.visible = false

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.035, 0.02, 0.88)
	_inspector_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_inspector_overlay.add_child(center)

	_inspector_modal = PanelContainer.new()
	_inspector_modal.custom_minimum_size = Vector2(460, 390)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.13, 0.08, 0.98)
	style.set_border_width_all(2)
	style.border_color = Color(0.65, 0.85, 0.70, 1.0)
	style.set_corner_radius_all(14)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	_inspector_modal.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_inspector_modal.add_child(vbox)

	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)

	_inspector_title_lbl = Label.new()
	_inspector_title_lbl.text = "🌸 SPECIMEN INSPECTOR"
	_inspector_title_lbl.add_theme_font_size_override("font_size", 15)
	_inspector_title_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.8))
	hdr.add_child(_inspector_title_lbl)

	var hdr_fill := Control.new()
	hdr_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(hdr_fill)

	var close_btn := Button.new()
	close_btn.text = "✕ Close"
	close_btn.pressed.connect(close_inspector_modal)
	hdr.add_child(close_btn)

	# Visual Preview
	var preview_box := CenterContainer.new()
	preview_box.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(preview_box)

	var halo := Panel.new()
	halo.custom_minimum_size = Vector2(70, 70)
	var h_style := StyleBoxFlat.new()
	h_style.bg_color = Color(0.1, 0.2, 0.14, 0.9)
	h_style.set_corner_radius_all(35)
	halo.add_theme_stylebox_override("panel", h_style)
	preview_box.add_child(halo)

	_inspector_flower_visual = FlowerVisual.new()
	_inspector_flower_visual.position = Vector2(35, 55)
	_inspector_flower_visual.current_stage = FlowerVisual.Stage.BLOOMING
	_inspector_flower_visual.scale = Vector2(1.2, 1.2)
	halo.add_child(_inspector_flower_visual)

	# Traits Card Breakdown
	var traits_panel := PanelContainer.new()
	var t_style := StyleBoxFlat.new()
	t_style.bg_color = Color(0.04, 0.08, 0.05, 0.8)
	t_style.set_corner_radius_all(8)
	t_style.content_margin_left = 10
	t_style.content_margin_right = 10
	t_style.content_margin_top = 8
	t_style.content_margin_bottom = 8
	traits_panel.add_theme_stylebox_override("panel", t_style)
	vbox.add_child(traits_panel)

	var t_vbox := VBoxContainer.new()
	t_vbox.add_theme_constant_override("separation", 4)
	traits_panel.add_child(t_vbox)

	_inspector_gen_lbl = _create_trait_row(t_vbox, "Generation / Pedigree:")
	_inspector_color_lbl = _create_trait_row(t_vbox, "Color Expression:")
	_inspector_petal_lbl = _create_trait_row(t_vbox, "Petal Form:")
	_inspector_fragrance_lbl = _create_trait_row(t_vbox, "Fragrance Rating:")
	_inspector_vigor_lbl = _create_trait_row(t_vbox, "Vigor & Vitality:")

	# Optional Developer Allele Toggle
	var dev_btn := Button.new()
	dev_btn.text = "🔍 Toggle Developer Genetic Details"
	dev_btn.add_theme_font_size_override("font_size", 9)
	dev_btn.pressed.connect(func() -> void:
		_inspector_show_raw_genes = not _inspector_show_raw_genes
		_update_inspector_display()
	)
	vbox.add_child(dev_btn)

	_inspector_raw_genotype_lbl = Label.new()
	_inspector_raw_genotype_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inspector_raw_genotype_lbl.add_theme_font_size_override("font_size", 9)
	_inspector_raw_genotype_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	_inspector_raw_genotype_lbl.visible = false
	vbox.add_child(_inspector_raw_genotype_lbl)

	center.add_child(_inspector_modal)
	_root_control.add_child(_inspector_overlay)


func _create_trait_row(parent: VBoxContainer, label_name: String) -> Label:
	var hbox := HBoxContainer.new()
	var title := Label.new()
	title.text = label_name
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(0.65, 0.75, 0.68))
	hbox.add_child(title)

	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(fill)

	var val := Label.new()
	val.text = "-"
	val.add_theme_font_size_override("font_size", 10)
	val.add_theme_color_override("font_color", Color(0.9, 0.95, 0.9))
	hbox.add_child(val)

	parent.add_child(hbox)
	return val


func open_inspector_modal(specimen: FlowerSpecimen) -> void:
	_inspector_specimen = specimen
	_inspector_show_raw_genes = false
	_inspector_overlay.visible = true
	_update_inspector_display()


func close_inspector_modal() -> void:
	_inspector_overlay.visible = false


func _update_inspector_display() -> void:
	if _inspector_specimen == null:
		return

	var sp := _inspector_specimen
	_inspector_title_lbl.text = "🌸 %s #%s" % [sp.species_id.capitalize(), sp.specimen_id]
	_inspector_flower_visual.flower_id = sp.species_id
	_inspector_flower_visual.phenotype = sp.phenotype
	_inspector_flower_visual.queue_redraw()

	var ped_str := sp.get_generation_label()
	if not sp.parent_a_id.is_empty() and not sp.parent_b_id.is_empty():
		ped_str += " (%s × %s)" % [sp.parent_a_id, sp.parent_b_id]
	else:
		ped_str += " (Starter Base Line)"
	_inspector_gen_lbl.text = ped_str

	_inspector_color_lbl.text = sp.phenotype.color_name
	_inspector_color_lbl.add_theme_color_override("font_color", sp.phenotype.color_tint)

	_inspector_petal_lbl.text = sp.phenotype.petal_form_name
	_inspector_fragrance_lbl.text = "%s (%s)" % [_get_stars_string(sp.phenotype.fragrance_rating), sp.phenotype.fragrance_name]
	_inspector_vigor_lbl.text = "%s (%.2fx Scale)" % [sp.phenotype.vigor_name, sp.phenotype.visual_scale]

	if _inspector_show_raw_genes and sp.genotype != null:
		_inspector_raw_genotype_lbl.visible = true
		_inspector_raw_genotype_lbl.text = "Developer Genotype: Color [%s,%s] · Petal [%s,%s] · Fragrance [%s,%s] · Vigor [%s,%s]" % [
			sp.genotype.color_alleles[0], sp.genotype.color_alleles[1],
			sp.genotype.petal_alleles[0], sp.genotype.petal_alleles[1],
			sp.genotype.fragrance_alleles[0], sp.genotype.fragrance_alleles[1],
			sp.genotype.vigor_alleles[0], sp.genotype.vigor_alleles[1]
		]
	else:
		_inspector_raw_genotype_lbl.visible = false


# =========================================================================
# OFFSPRING SPECIMEN REVEAL MODAL — P3
# =========================================================================

func _build_reveal_modal() -> void:
	_reveal_overlay = Control.new()
	_reveal_overlay.name = "RevealOverlay"
	_reveal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_reveal_overlay.visible = false

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.035, 0.02, 0.88)
	_reveal_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_overlay.add_child(center)

	_reveal_modal = PanelContainer.new()
	_reveal_modal.custom_minimum_size = Vector2(460, 390)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.13, 0.08, 0.98)
	style.set_border_width_all(2)
	style.border_color = Color(1.0, 0.88, 0.35, 1.0)
	style.set_corner_radius_all(16)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_reveal_modal.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	_reveal_modal.add_child(vbox)

	_reveal_title_lbl = Label.new()
	_reveal_title_lbl.text = "★ NEW SPECIMEN BRED! ★"
	_reveal_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_title_lbl.add_theme_font_size_override("font_size", 16)
	_reveal_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(_reveal_title_lbl)

	var showcase_box := CenterContainer.new()
	showcase_box.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(showcase_box)

	var halo := Panel.new()
	halo.custom_minimum_size = Vector2(76, 76)
	var h_style := StyleBoxFlat.new()
	h_style.bg_color = Color(0.12, 0.24, 0.16, 0.9)
	h_style.set_corner_radius_all(38)
	halo.add_theme_stylebox_override("panel", h_style)
	showcase_box.add_child(halo)

	_reveal_flower_visual = FlowerVisual.new()
	_reveal_flower_visual.position = Vector2(38, 58)
	_reveal_flower_visual.current_stage = FlowerVisual.Stage.BLOOMING
	_reveal_flower_visual.scale = Vector2(1.3, 1.3)
	halo.add_child(_reveal_flower_visual)

	_reveal_species_lbl = Label.new()
	_reveal_species_lbl.text = "Roselight Bloom #H-012"
	_reveal_species_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_species_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_reveal_species_lbl)

	_reveal_traits_lbl = Label.new()
	_reveal_traits_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_traits_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reveal_traits_lbl.add_theme_font_size_override("font_size", 10)
	_reveal_traits_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.88))
	vbox.add_child(_reveal_traits_lbl)

	# Action Choice Buttons (Mutually exclusive Preserve vs Harvest)
	var choice_box := HBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 8)
	vbox.add_child(choice_box)

	_reveal_preserve_btn = Button.new()
	_reveal_preserve_btn.text = "🌿 Preserve to Breeding Stock"
	_reveal_preserve_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reveal_preserve_btn.custom_minimum_size = Vector2(0, 32)
	_reveal_preserve_btn.modulate = Color(1.1, 1.0, 0.7)
	choice_box.add_child(_reveal_preserve_btn)

	_reveal_harvest_btn = Button.new()
	_reveal_harvest_btn.text = "🧺 Harvest to Bulk (+1)"
	_reveal_harvest_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reveal_harvest_btn.custom_minimum_size = Vector2(0, 32)
	choice_box.add_child(_reveal_harvest_btn)

	center.add_child(_reveal_modal)
	_root_control.add_child(_reveal_overlay)


func show_specimen_reveal(
	specimen: FlowerSpecimen,
	on_preserve_callable: Callable,
	on_harvest_callable: Callable
) -> void:
	_close_all_modals()
	_reveal_specimen = specimen

	_reveal_species_lbl.text = "%s (%s #%s)" % [
		FlowerData.get_flower(specimen.species_id).get("display_name", specimen.species_id),
		specimen.get_generation_label(),
		specimen.specimen_id
	]
	_reveal_species_lbl.add_theme_color_override("font_color", specimen.phenotype.color_tint)

	_reveal_flower_visual.flower_id = specimen.species_id
	_reveal_flower_visual.phenotype = specimen.phenotype
	_reveal_flower_visual.queue_redraw()

	var trait_text := "Color: %s · Petals: %s\nFragrance: %s (%s) · Vigor: %s" % [
		specimen.phenotype.color_name,
		specimen.phenotype.petal_form_name,
		_get_stars_string(specimen.phenotype.fragrance_rating),
		specimen.phenotype.fragrance_name,
		specimen.phenotype.vigor_name
	]
	_reveal_traits_lbl.text = trait_text

	# Configure buttons
	_reveal_preserve_btn.pressed.disconnect(_on_reveal_preserve_clicked) if _reveal_preserve_btn.pressed.is_connected(_on_reveal_preserve_clicked) else null
	_reveal_harvest_btn.pressed.disconnect(_on_reveal_harvest_clicked) if _reveal_harvest_btn.pressed.is_connected(_on_reveal_harvest_clicked) else null

	var roster_full: bool = _cached_breeding_roster.size() >= 12
	if roster_full:
		_reveal_preserve_btn.text = "🌿 Stock Full (12/12)"
		_reveal_preserve_btn.disabled = true
	else:
		_reveal_preserve_btn.text = "🌿 Preserve to Breeding Stock"
		_reveal_preserve_btn.disabled = false

	_reveal_preserve_btn.pressed.connect(func() -> void:
		_reveal_overlay.visible = false
		on_preserve_callable.call()
	)
	_reveal_harvest_btn.pressed.connect(func() -> void:
		_reveal_overlay.visible = false
		on_harvest_callable.call()
	)

	_reveal_overlay.visible = true


func _on_reveal_preserve_clicked() -> void:
	pass


func _on_reveal_harvest_clicked() -> void:
	pass


# =========================================================================
# BOTANICAL JOURNAL & DISCOVERY MODALS
# =========================================================================

func _build_journal_modal() -> void:
	_journal_modal_instance = JournalModalScene.instantiate() as JournalModal
	_journal_modal_instance.hide()
	_root_control.add_child(_journal_modal_instance)


func open_journal_modal() -> void:
	_close_all_modals()
	if _journal_modal_instance != null:
		_journal_modal_instance.open_journal(_cached_discovered)


func close_journal_modal() -> void:
	if _journal_modal_instance != null:
		_journal_modal_instance.hide()


func _update_journal_cards() -> void:
	if _journal_modal_instance != null and _journal_modal_instance.visible:
		_journal_modal_instance.open_journal(_cached_discovered)





func _build_discovery_modal() -> void:
	_discovery_overlay = Control.new()
	_discovery_overlay.name = "DiscoveryOverlay"
	_discovery_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_discovery_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_discovery_overlay.visible = false

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.035, 0.02, 0.88)
	_discovery_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_discovery_overlay.add_child(center)

	_discovery_modal = PanelContainer.new()
	_discovery_modal.custom_minimum_size = Vector2(460, 380)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.13, 0.08, 0.98)
	style.set_border_width_all(2)
	style.border_color = Color(1.0, 0.88, 0.35, 1.0)
	style.set_corner_radius_all(16)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	_discovery_modal.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	_discovery_modal.add_child(vbox)

	var header_lbl := Label.new()
	header_lbl.name = "HeaderLabel"
	header_lbl.text = "★ NEW SPECIES DISCOVERY! ★"
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_lbl.add_theme_font_size_override("font_size", 15)
	header_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(header_lbl)

	var showcase_box := CenterContainer.new()
	showcase_box.custom_minimum_size = Vector2(0, 90)
	vbox.add_child(showcase_box)

	var halo_panel := Panel.new()
	halo_panel.custom_minimum_size = Vector2(80, 80)
	var halo_style := StyleBoxFlat.new()
	halo_style.bg_color = Color(0.12, 0.24, 0.16, 0.9)
	halo_style.set_corner_radius_all(40)
	halo_panel.add_theme_stylebox_override("panel", halo_style)
	showcase_box.add_child(halo_panel)

	var showcase_flower := FlowerVisual.new()
	showcase_flower.name = "ShowcaseFlower"
	showcase_flower.position = Vector2(40, 62)
	showcase_flower.current_stage = FlowerVisual.Stage.BLOOMING
	showcase_flower.scale = Vector2(1.4, 1.4)
	halo_panel.add_child(showcase_flower)

	var name_lbl := Label.new()
	name_lbl.name = "FlowerNameLabel"
	name_lbl.text = "Roselight Bloom"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_lbl)

	var parent_lbl := Label.new()
	parent_lbl.name = "ParentLabel"
	parent_lbl.text = "Cultivated from: Red Rose + Lavender"
	parent_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent_lbl.add_theme_font_size_override("font_size", 12)
	parent_lbl.add_theme_color_override("font_color", Color(0.75, 0.92, 0.80))
	vbox.add_child(parent_lbl)

	var lore_lbl := Label.new()
	lore_lbl.name = "LoreLabel"
	lore_lbl.text = "An ethereal hybrid combining velvety rose petals with fragrant lavender hues."
	lore_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.add_theme_font_size_override("font_size", 11)
	lore_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 0.86))
	vbox.add_child(lore_lbl)

	var ok_btn := Button.new()
	ok_btn.text = "🌿 Add to Botanical Journal"
	ok_btn.custom_minimum_size = Vector2(220, 36)
	ok_btn.pressed.connect(func() -> void:
		_discovery_overlay.visible = false
	)
	vbox.add_child(ok_btn)

	center.add_child(_discovery_modal)
	_root_control.add_child(_discovery_overlay)


func show_discovery_modal(flower_id: String) -> void:
	show_discovery_presentation(flower_id)


func show_discovery_presentation(flower_id: String) -> void:
	_close_all_modals()
	var data: Dictionary = FlowerData.get_flower(flower_id)
	
	var showcase: FlowerVisual = _discovery_modal.find_child("ShowcaseFlower", true, false) as FlowerVisual
	if is_instance_valid(showcase):
		showcase.flower_id = flower_id
		showcase.is_mystery = false
		showcase.current_stage = FlowerVisual.Stage.BLOOMING
		showcase.queue_redraw()

	var name_lbl: Label = _discovery_modal.find_child("FlowerNameLabel", true, false) as Label
	if is_instance_valid(name_lbl):
		name_lbl.text = String(data.get("display_name", flower_id))
		name_lbl.add_theme_color_override("font_color", data.get("primary_color", Color.WHITE))

	var parent_lbl: Label = _discovery_modal.find_child("ParentLabel", true, false) as Label
	if is_instance_valid(parent_lbl):
		var parents: Array = data.get("parents", [])
		if parents.size() == 2:
			var p1_name: String = FlowerData.get_flower(parents[0]).get("display_name", "")
			var p2_name: String = FlowerData.get_flower(parents[1]).get("display_name", "")
			parent_lbl.text = "Cultivated from: %s + %s" % [p1_name, p2_name]
		else:
			parent_lbl.text = "Discovered Hybrid"

	var lore_lbl: Label = _discovery_modal.find_child("LoreLabel", true, false) as Label
	if is_instance_valid(lore_lbl):
		lore_lbl.text = String(data.get("description", ""))

	_discovery_overlay.visible = true


func _close_all_modals() -> void:
	if _requests_modal_instance != null: _requests_modal_instance.hide()
	if _bouquets_modal_instance != null: _bouquets_modal_instance.hide()
	if _breeding_modal_instance != null: _breeding_modal_instance.hide()
	if _journal_modal_instance != null: _journal_modal_instance.hide()
	if _upgrades_modal_instance != null: _upgrades_modal_instance.hide()
	if _requests_overlay != null: _requests_overlay.visible = false
	if _bouquets_overlay != null: _bouquets_overlay.visible = false
	if _breeding_overlay != null: _breeding_overlay.visible = false
	if _journal_overlay != null: _journal_overlay.visible = false
	if _discovery_overlay != null: _discovery_overlay.visible = false
	if _inspector_overlay != null: _inspector_overlay.visible = false
	if _reveal_overlay != null: _reveal_overlay.visible = false
	if _visual_lab_overlay != null: _visual_lab_overlay.visible = false
	if _upgrades_overlay != null: _upgrades_overlay.visible = false


func has_active_modal() -> bool:
	if _requests_modal_instance != null and _requests_modal_instance.visible: return true
	if _bouquets_modal_instance != null and _bouquets_modal_instance.visible: return true
	if _breeding_modal_instance != null and _breeding_modal_instance.visible: return true
	if _journal_modal_instance != null and _journal_modal_instance.visible: return true
	if _upgrades_modal_instance != null and _upgrades_modal_instance.visible: return true
	if _requests_overlay != null and _requests_overlay.visible: return true
	if _bouquets_overlay != null and _bouquets_overlay.visible: return true
	if _breeding_overlay != null and _breeding_overlay.visible: return true
	if _journal_overlay != null and _journal_overlay.visible: return true
	if _discovery_overlay != null and _discovery_overlay.visible: return true
	if _inspector_overlay != null and _inspector_overlay.visible: return true
	if _reveal_overlay != null and _reveal_overlay.visible: return true
	if _visual_lab_overlay != null and _visual_lab_overlay.visible: return true
	if _upgrades_overlay != null and _upgrades_overlay.visible: return true
	return false


func close_top_modal() -> bool:
	if not has_active_modal():
		return false
	_close_all_modals()
	return true


func show_floating_reward(text: String, global_pos: Vector2, color_tint: Color = Color(1.0, 0.88, 0.25)) -> void:
	if _root_control == null:
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.position = global_pos - Vector2(40, 20)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", color_tint)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 0.9))
	lbl.add_theme_constant_override("outline_size", 4)
	_root_control.add_child(lbl)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", global_pos.y - 65.0, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(lbl.queue_free)


# =========================================================================
# P4 VISUAL LAB MODAL IMPLEMENTATION
# =========================================================================

func _build_visual_lab_modal() -> void:
	_visual_lab_overlay = Control.new()
	_visual_lab_overlay.name = "VisualLabOverlay"
	_visual_lab_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_visual_lab_overlay.visible = false

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.05, 0.03, 0.88)
	_visual_lab_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_visual_lab_overlay.add_child(center)

	_visual_lab_modal = PanelContainer.new()
	_visual_lab_modal.custom_minimum_size = Vector2(880, 560)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.12, 0.08, 0.98)
	style.set_border_width_all(2)
	style.border_color = Color(0.65, 0.45, 0.85, 0.85) # Amethyst Purple
	style.set_corner_radius_all(10)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 16
	_visual_lab_modal.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_visual_lab_modal.add_child(vbox)

	# Header with Title & Close
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var header_vbox := VBoxContainer.new()
	header_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_vbox)

	var title_lbl := Label.new()
	title_lbl.text = "🧪 P4 VISUAL LAB — FLOWER ART & LIVING GARDEN EXPERIMENT"
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 1.0))
	header_vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "PROTOTYPE_ONLY · Comparing Whole-Authored, Full Modular, and Curated Hybrid Art Pipelines"
	sub_lbl.add_theme_font_size_override("font_size", 9)
	sub_lbl.add_theme_color_override("font_color", Color(0.70, 0.60, 0.85))
	header_vbox.add_child(sub_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕ Close"
	close_btn.custom_minimum_size = Vector2(70, 26)
	close_btn.pressed.connect(close_visual_lab_modal)
	header.add_child(close_btn)

	# Main Tab Controls
	var tabs_box := HBoxContainer.new()
	tabs_box.add_theme_constant_override("separation", 8)
	vbox.add_child(tabs_box)

	# Strategy Selectors
	var strat_lbl := Label.new()
	strat_lbl.text = "Art Pipeline Strategy:"
	strat_lbl.add_theme_font_size_override("font_size", 11)
	tabs_box.add_child(strat_lbl)

	var btn_strat_a := Button.new()
	btn_strat_a.text = "A: Whole-Authored"
	btn_strat_a.pressed.connect(func() -> void: _set_visual_lab_strategy(0))
	tabs_box.add_child(btn_strat_a)

	var btn_strat_b := Button.new()
	btn_strat_b.text = "B: Full Modular"
	btn_strat_b.pressed.connect(func() -> void: _set_visual_lab_strategy(1))
	tabs_box.add_child(btn_strat_b)

	var btn_strat_c := Button.new()
	btn_strat_c.text = "C: Curated Hybrid Pipeline (Master + Modular)"
	btn_strat_c.pressed.connect(func() -> void: _set_visual_lab_strategy(2))
	btn_strat_c.modulate = Color(1.1, 1.1, 0.7)
	tabs_box.add_child(btn_strat_c)

	# Hybrid Lineage Selectors
	var lin_box := HBoxContainer.new()
	lin_box.add_theme_constant_override("separation", 8)
	vbox.add_child(lin_box)

	var lin_lbl := Label.new()
	lin_lbl.text = "Lineage Cross:"
	lin_lbl.add_theme_font_size_override("font_size", 11)
	lin_box.add_child(lin_lbl)

	var btn_lin1 := Button.new()
	btn_lin1.text = "Rose × Lavender (Roselight)"
	btn_lin1.pressed.connect(func() -> void: _set_visual_lab_lineage("roselight"))
	lin_box.add_child(btn_lin1)

	var btn_lin2 := Button.new()
	btn_lin2.text = "Rose × Sunflower (Golden Rose)"
	btn_lin2.pressed.connect(func() -> void: _set_visual_lab_lineage("golden_rose"))
	lin_box.add_child(btn_lin2)

	var btn_lin3 := Button.new()
	btn_lin3.text = "Lavender × Sunflower (Sunflare Spike)"
	btn_lin3.pressed.connect(func() -> void: _set_visual_lab_lineage("sunflare_spike"))
	lin_box.add_child(btn_lin3)

	# Strategy Description Banner
	_strategy_desc_lbl = Label.new()
	_strategy_desc_lbl.text = "Strategy C: Master botanical architecture with modular heritable phenotype variations (Color, Petals, Vigor, Shimmer)."
	_strategy_desc_lbl.add_theme_font_size_override("font_size", 10)
	_strategy_desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 0.85))
	vbox.add_child(_strategy_desc_lbl)

	# Visual Comparison Columns (Parent A + Parent B -> Hybrid)
	var preview_row := HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 12)
	vbox.add_child(preview_row)

	# Parent A Card
	var card_a := _create_lineage_card(preview_row, "Parent A (Rose)", "rose", Color(0.95, 0.4, 0.45))
	_parent_a_title_lbl = card_a.get_node("VBox/TitleLabel") as Label
	_visual_preview_parent_a = card_a.get_node("VBox/VisualContainer/ModularVisual") as Node2D

	# Plus Sign
	var plus_lbl := Label.new()
	plus_lbl.text = "+\n×"
	plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus_lbl.add_theme_font_size_override("font_size", 18)
	plus_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 0.7))
	preview_row.add_child(plus_lbl)

	# Parent B Card
	var card_b := _create_lineage_card(preview_row, "Parent B (Lavender)", "lavender", Color(0.75, 0.6, 0.95))
	_parent_b_title_lbl = card_b.get_node("VBox/TitleLabel") as Label
	_visual_preview_parent_b = card_b.get_node("VBox/VisualContainer/ModularVisual") as Node2D

	# Arrow Sign
	var arrow_lbl := Label.new()
	arrow_lbl.text = "→\n═"
	arrow_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow_lbl.add_theme_font_size_override("font_size", 18)
	arrow_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	preview_row.add_child(arrow_lbl)

	# Hybrid Result Card
	var card_h := _create_lineage_card(preview_row, "Hybrid (Roselight Bloom)", "roselight", Color(0.9, 0.45, 0.8))
	_hybrid_title_lbl = card_h.get_node("VBox/TitleLabel") as Label
	_visual_preview_hybrid = card_h.get_node("VBox/VisualContainer/ModularVisual") as Node2D

	# Trait Provenance Breakdown Panel
	var prov_panel := PanelContainer.new()
	prov_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var prov_style := StyleBoxFlat.new()
	prov_style.bg_color = Color(0.04, 0.08, 0.05, 0.9)
	prov_style.set_corner_radius_all(6)
	prov_style.content_margin_left = 12
	prov_style.content_margin_right = 12
	prov_style.content_margin_top = 8
	prov_style.content_margin_bottom = 8
	prov_panel.add_theme_stylebox_override("panel", style)
	preview_row.add_child(prov_panel)

	_provenance_container = VBoxContainer.new()
	_provenance_container.add_theme_constant_override("separation", 3)
	prov_panel.add_child(_provenance_container)

	# Bottom Controls: Spatial Layouts & Environment Controls
	var env_bar := HBoxContainer.new()
	env_bar.add_theme_constant_override("separation", 8)
	vbox.add_child(env_bar)

	var env_lbl := Label.new()
	env_lbl.text = "Living Garden Controls:"
	env_lbl.add_theme_font_size_override("font_size", 11)
	env_bar.add_child(env_lbl)

	var btn_prom := Button.new()
	btn_prom.text = "Layout: Promenade"
	btn_prom.pressed.connect(func() -> void: layout_preset_changed.emit(0))
	env_bar.add_child(btn_prom)

	var btn_quad := Button.new()
	btn_quad.text = "Layout: Quad"
	btn_quad.pressed.connect(func() -> void: layout_preset_changed.emit(1))
	env_bar.add_child(btn_quad)

	var btn_oasis := Button.new()
	btn_oasis.text = "Layout: Oasis"
	btn_oasis.pressed.connect(func() -> void: layout_preset_changed.emit(2))
	env_bar.add_child(btn_oasis)

	_persp_toggle_btn = Button.new()
	_persp_toggle_btn.text = "Perspective: Top-Down (2D)"
	_persp_toggle_btn.pressed.connect(func() -> void:
		_active_perspective = 1 if _active_perspective == 0 else 0
		_persp_toggle_btn.text = "Perspective: 3/4 Angled Depth" if _active_perspective == 1 else "Perspective: Top-Down (2D)"
		perspective_changed.emit(_active_perspective)
	)
	env_bar.add_child(_persp_toggle_btn)

	_char_toggle_btn = Button.new()
	_char_toggle_btn.text = "🚶 Gardener: ON"
	_char_toggle_btn.pressed.connect(func() -> void:
		_is_character_enabled = not _is_character_enabled
		_char_toggle_btn.text = "🚶 Gardener: ON" if _is_character_enabled else "🚶 Gardener: OFF"
		character_toggled.emit(_is_character_enabled)
	)
	env_bar.add_child(_char_toggle_btn)

	center.add_child(_visual_lab_modal)
	_root_control.add_child(_visual_lab_overlay)
	_update_visual_lab_state()


func _create_lineage_card(parent: Control, title: String, flower_id: String, color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(170, 220)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.14, 0.10, 0.95)
	style.set_border_width_all(1)
	style.border_color = color.darkened(0.3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.name = "TitleLabel"
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", color)
	vbox.add_child(title_lbl)

	var visual_container := Control.new()
	visual_container.name = "VisualContainer"
	visual_container.custom_minimum_size = Vector2(150, 150)
	vbox.add_child(visual_container)

	var visual := ModularFlowerVisualScript.new()
	visual.name = "ModularVisual"
	visual.position = Vector2(75, 110)
	visual.flower_id = flower_id
	visual_container.add_child(visual)

	parent.add_child(card)
	return card


func _set_visual_lab_strategy(strat_idx: int) -> void:
	_selected_strategy = strat_idx
	match strat_idx:
		0:
			_strategy_desc_lbl.text = "Strategy A: Whole-authored standalone botanical silhouettes. High artistic cohesion per asset."
		1:
			_strategy_desc_lbl.text = "Strategy B: Full modular composition from raw interchangeable parts (stems, leaves, petals, centers)."
		2:
			_strategy_desc_lbl.text = "Strategy C: Curated Hybrid Pipeline. Master species architecture with modular heritable phenotype variations."
	_update_visual_lab_state()


func _set_visual_lab_lineage(hybrid_id: String) -> void:
	_selected_hybrid_cross = hybrid_id
	_update_visual_lab_state()


func _update_visual_lab_state() -> void:
	if _visual_preview_parent_a == null or _visual_preview_parent_b == null or _visual_preview_hybrid == null:
		return

	var parent_a_id := "rose"
	var parent_b_id := "lavender"
	var hybrid_name := "Roselight Bloom"

	match _selected_hybrid_cross:
		"roselight":
			parent_a_id = "rose"
			parent_b_id = "lavender"
			hybrid_name = "Roselight Bloom"
		"golden_rose":
			parent_a_id = "rose"
			parent_b_id = "sunflower"
			hybrid_name = "Golden Sun Rose"
		"sunflare_spike":
			parent_a_id = "lavender"
			parent_b_id = "sunflower"
			hybrid_name = "Sunflare Spike"

	_parent_a_title_lbl.text = "Parent A (%s)" % parent_a_id.capitalize()
	_parent_b_title_lbl.text = "Parent B (%s)" % parent_b_id.capitalize()
	_hybrid_title_lbl.text = "Hybrid (%s)" % hybrid_name

	var ph_a: FlowerPhenotype = GeneticsEngine.create_starter_specimen(parent_a_id).phenotype
	var ph_b: FlowerPhenotype = GeneticsEngine.create_starter_specimen(parent_b_id).phenotype

	var g_hyb := FlowerGenotype.new(["Cr", "Cp"], ["Ps", "Pr"], ["F+", "F+"], ["V+", "v-"])
	if _selected_hybrid_cross == "golden_rose":
		g_hyb = FlowerGenotype.new(["Cr", "Cy"], ["Pr", "Pr"], ["F+", "f-"], ["V+", "V+"])
	elif _selected_hybrid_cross == "sunflare_spike":
		g_hyb = FlowerGenotype.new(["Cp", "Cy"], ["Ps", "Pr"], ["F+", "F+"], ["V+", "v-"])
	var ph_hyb := GeneticsEngine.resolve_phenotype(g_hyb, _selected_hybrid_cross)

	_visual_preview_parent_a.set("strategy", _selected_strategy)
	_visual_preview_parent_a.set("flower_id", parent_a_id)
	_visual_preview_parent_a.set("phenotype", ph_a)
	_visual_preview_parent_a.queue_redraw()

	_visual_preview_parent_b.set("strategy", _selected_strategy)
	_visual_preview_parent_b.set("flower_id", parent_b_id)
	_visual_preview_parent_b.set("phenotype", ph_b)
	_visual_preview_parent_b.queue_redraw()

	_visual_preview_hybrid.set("strategy", _selected_strategy)
	_visual_preview_hybrid.set("flower_id", _selected_hybrid_cross)
	_visual_preview_hybrid.set("phenotype", ph_hyb)
	_visual_preview_hybrid.queue_redraw()

	# Rebuild Provenance List
	for child in _provenance_container.get_children():
		child.queue_free()

	var prov_title := Label.new()
	prov_title.text = "Visual Trait Provenance Breakdown:"
	prov_title.add_theme_font_size_override("font_size", 11)
	prov_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	_provenance_container.add_child(prov_title)

	var traits_list: Array[Dictionary] = ModularFlowerVisualScript.get_trait_provenance_breakdown(_selected_hybrid_cross)
	for t in traits_list:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_provenance_container.add_child(row)

		var badge := Label.new()
		badge.text = "• %s:" % t["part"]
		badge.add_theme_font_size_override("font_size", 10)
		badge.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		row.add_child(badge)

		var src := Label.new()
		src.text = t["source"]
		src.add_theme_font_size_override("font_size", 10)
		src.add_theme_color_override("font_color", t["color"])
		row.add_child(src)


func open_visual_lab_modal() -> void:
	_close_all_modals()
	_update_visual_lab_state()
	_visual_lab_overlay.visible = true


func close_visual_lab_modal() -> void:
	if _visual_lab_overlay != null:
		_visual_lab_overlay.visible = false


func toggle_beauty_mode() -> void:
	_is_beauty_mode = not _is_beauty_mode
	if is_instance_valid(_bottom_toolbar_node):
		_bottom_toolbar_node.visible = not _is_beauty_mode
	if is_instance_valid(_plot_info_card):
		_plot_info_card.visible = not _is_beauty_mode
	if is_instance_valid(_utility_controls_node):
		_utility_controls_node.visible = not _is_beauty_mode
	if is_instance_valid(_side_order_rail):
		_side_order_rail.visible = not _is_beauty_mode
	if is_instance_valid(_top_left_cluster):
		_top_left_cluster.visible = not _is_beauty_mode
	if is_instance_valid(_tool_dock_instance):
		_tool_dock_instance.visible = not _is_beauty_mode
	if is_instance_valid(_seed_bar_instance):
		_seed_bar_instance.visible = not _is_beauty_mode
	if is_instance_valid(_plot_card_instance):
		_plot_card_instance.visible = not _is_beauty_mode
	if _is_beauty_mode:
		show_toast("🌿 Beauty View Active (Clean presentation)", Color(0.85, 1.0, 0.9))
	else:
		show_toast("Standard Gameplay HUD restored", Color(0.9, 0.9, 0.9))


# =========================================================================
# STATE UPDATES & TOASTS
# =========================================================================

func update_inventory(
	flowers: Dictionary,
	bouquets: Dictionary,
	coins: int,
	unknown_seeds_count: int
) -> void:
	_cached_inventory = flowers
	_cached_bouquets = bouquets
	_cached_coins = coins
	_cached_unknown_seeds = unknown_seeds_count

	if is_instance_valid(_coins_lbl):
		_coins_lbl.text = str(coins)

	if is_instance_valid(_top_left_cluster):
		var total_fl: int = 0
		for f in flowers:
			total_fl += int(flowers[f])
		_top_left_cluster.update_values(coins, total_fl)

	if is_instance_valid(_seed_bar_instance):
		_seed_bar_instance.update_counts(flowers, unknown_seeds_count)

	if is_instance_valid(_inventory_drawer):
		_inventory_drawer.update_inventory(flowers, bouquets)

	if is_instance_valid(_side_order_rail):
		var p = get_parent()
		var pat = p.order_manager.live_orders_patience if (p != null and "order_manager" in p and p.order_manager != null) else {}
		_side_order_rail.update_state(flowers, bouquets, pat, _cached_completed_requests)

	for flower_id in ["rose", "lavender", "sunflower"]:
		if _inv_labels.has(flower_id):
			_inv_labels[flower_id].text = str(flowers.get(flower_id, 0))

	if _inv_labels.has("bouquets"):
		var total_bouquets: int = 0
		for b_id in bouquets:
			total_bouquets += int(bouquets[b_id])
		_inv_labels["bouquets"].text = str(total_bouquets)

	if _inv_labels.has("unknown_seed"):
		_inv_labels["unknown_seed"].text = str(unknown_seeds_count)

	if _seed_buttons.has("mystery_seed"):
		_seed_buttons["mystery_seed"].text = "★ Mystery Seed (%d)" % unknown_seeds_count

	_update_breeding_modal_state()
	_update_bouquets_cards()
	_update_requests_cards()


func update_breeding_roster(roster: Array[FlowerSpecimen]) -> void:
	_cached_breeding_roster = roster
	_update_breeding_modal_state()


func update_discoveries(discovered: Dictionary) -> void:
	_cached_discovered = discovered
	_update_journal_cards()


func update_requests(completed_requests: Dictionary) -> void:
	_cached_completed_requests = completed_requests
	if is_instance_valid(_side_order_rail):
		var p = get_parent()
		var pat = p.order_manager.live_orders_patience if (p != null and "order_manager" in p and p.order_manager != null) else {}
		_side_order_rail.update_state(_cached_inventory, _cached_bouquets, pat, _cached_completed_requests)
	_update_requests_cards()


func update_plot_info(plot: GardenPlot) -> void:
	_selected_plot_ref = plot
	_plot_info_title.text = "Garden Plot #%d" % (plot.plot_index + 1)

	if is_instance_valid(_plot_card_instance):
		var plot_data := {
			"index": plot.plot_index,
			"flower_id": plot.current_flower_id if (plot.state != GardenPlot.State.EMPTY) else "",
			"state": "Mature" if (plot.state == GardenPlot.State.MATURE) else ("Growing" if (plot.state == GardenPlot.State.GROWING) else "Empty"),
			"moisture": 1.0 if plot.is_watered else 0.0,
			"growth_progress": plot.growth_progress,
			"quality": plot.quality,
			"is_pruned": plot.is_pruned
		}
		_plot_card_instance.display_plot(plot_data)

	match plot.state:
		GardenPlot.State.EMPTY:
			_plot_info_desc.text = "Status: Empty Plot"
			_plot_growth_bar.value = 0.0
			_plot_growth_bar.modulate = Color.WHITE
			_plot_actions_box.visible = false
			_update_timeline_stages(-1)
			if _plot_prune_alert_box: _plot_prune_alert_box.visible = false
			if _plot_droplets_lbl: _plot_droplets_lbl.text = "🏜️ (Parched Soil)"
		GardenPlot.State.GROWING:
			var stage_text := "Growing: "
			if plot.is_mystery_seed and not plot.is_revealed:
				stage_text += "Unknown Mystery Hybrid"
			else:
				var data := FlowerData.get_flower(plot.current_flower_id)
				stage_text += String(data.get("display_name", "Flower"))
			_plot_info_desc.text = stage_text
			_plot_growth_bar.value = plot.growth_progress * 100.0
			_plot_growth_bar.modulate = Color(0.4, 0.85, 0.4)
			_plot_actions_box.visible = false

			# Growth timeline step
			if plot.growth_progress >= 0.60:
				_update_timeline_stages(2) # Young
			elif plot.growth_progress >= 0.25:
				_update_timeline_stages(1) # Sprout
			else:
				_update_timeline_stages(0) # Seed

			# Pruning Window Alert
			if _plot_prune_alert_box != null:
				if plot.growth_progress >= 0.60 and plot.growth_progress <= 0.85 and not plot.is_pruned:
					_plot_prune_alert_box.visible = true
					var pct_left := int((0.85 - plot.growth_progress) / 0.25 * 100.0)
					_plot_prune_alert_lbl.text = "✂️ Pruning Opportunity! (%d%% left) ➔ ★★★ Hero" % pct_left
					_plot_prune_alert_box.modulate = Color(1.2, 1.15, 0.6)
				elif plot.is_pruned:
					_plot_prune_alert_box.visible = true
					_plot_prune_alert_lbl.text = "✨ Pruned! (★★★ Hero Bloom forming)"
					_plot_prune_alert_box.modulate = Color(0.7, 1.1, 0.8)
				else:
					_plot_prune_alert_box.visible = false

			if _plot_droplets_lbl:
				if plot.is_watered:
					_plot_droplets_lbl.text = "💧💧💧 (Hydrated +60%)"
					_plot_droplets_lbl.modulate = Color(0.4, 0.85, 1.0)
				else:
					_plot_droplets_lbl.text = "🏜️ (Thirsty Soil)"
					_plot_droplets_lbl.modulate = Color(1.0, 0.6, 0.5)

		GardenPlot.State.MATURE:
			var data := FlowerData.get_flower(plot.current_flower_id)
			var specimen_info := ""
			if plot.current_specimen != null:
				specimen_info = " · %s" % plot.current_specimen.phenotype.color_name
			_plot_info_desc.text = "Blooming: %s%s" % [String(data.get("display_name", "Flower")), specimen_info]
			_plot_growth_bar.value = 100.0
			_plot_growth_bar.modulate = Color(1.0, 0.88, 0.3)
			_plot_actions_box.visible = true
			_update_timeline_stages(3) # Bloom

			if _plot_prune_alert_box != null:
				if plot.is_pruned:
					_plot_prune_alert_box.visible = true
					_plot_prune_alert_lbl.text = "👑 ★★★ Hero Bloom Harvest Ready!"
					_plot_prune_alert_box.modulate = Color(1.3, 1.2, 0.5)
				else:
					_plot_prune_alert_box.visible = false

			if _plot_droplets_lbl:
				_plot_droplets_lbl.text = "💧 (Harvest Ready)"
				_plot_droplets_lbl.modulate = Color(0.6, 0.9, 0.7)

			var roster_full: bool = _cached_breeding_roster.size() >= 12
			if roster_full:
				_plot_preserve_btn.text = "Stock Full (12/12)"
				_plot_preserve_btn.disabled = true
			else:
				_plot_preserve_btn.text = "🌿 Preserve (Roster)"
				_plot_preserve_btn.disabled = false

	if plot.is_watered:
		_plot_water_badge.text = "Soil: Watered (1.8x Boost)"
		_plot_water_badge.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	else:
		_plot_water_badge.text = "Soil: Dry"
		_plot_water_badge.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5))


func _update_timeline_stages(active_stage: int) -> void:
	var stages = [_stage_seed, _stage_sprout, _stage_young, _stage_bloom]
	for i in range(stages.size()):
		var lbl: Label = stages[i]
		if lbl == null: continue
		if active_stage < 0:
			lbl.modulate = Color(0.5, 0.5, 0.5, 0.3)
		elif i == active_stage:
			lbl.modulate = Color(1.3, 1.25, 0.6, 1.0)
		elif i < active_stage:
			lbl.modulate = Color(0.5, 0.9, 0.6, 0.85)
		else:
			lbl.modulate = Color(0.5, 0.5, 0.5, 0.45)


func show_toast(message: String, color_tint: Color = Color.WHITE) -> void:
	if _toast_container == null or message.is_empty():
		return

	var now_msec := Time.get_ticks_msec()
	if message == _last_toast_message and (now_msec - _last_toast_time_msec) < 1500:
		return
	_last_toast_message = message
	_last_toast_time_msec = now_msec

	while _toast_container.get_child_count() >= 2:
		var oldest: Node = _toast_container.get_child(0)
		if is_instance_valid(oldest):
			oldest.queue_free()
			_toast_container.remove_child(oldest)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.10, 0.07, 0.96)
	style.set_border_width_all(1)
	style.border_color = color_tint.darkened(0.2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.text = message
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(356, 0)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", color_tint)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(lbl)

	_toast_container.add_child(panel)

	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.18).from(0.0)
	tween.tween_interval(2.8)
	tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(panel.queue_free)


func _create_choice_button(parent: Control, text: String, id: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 11)
	btn.custom_minimum_size = Vector2(85, 30)
	btn.pressed.connect(func() -> void:
		_play_sfx("click")
		callback.call(id)
	)
	parent.add_child(btn)
	return btn


func _create_action_button(parent: Control, text: String, id: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 11)
	btn.custom_minimum_size = Vector2(65, 24)
	btn.pressed.connect(func() -> void:
		_play_sfx("click")
		callback.call(id)
	)
	parent.add_child(btn)
	return btn


func _on_tool_btn_pressed(tool_id: String) -> void:
	_play_sfx("click")
	current_tool = tool_id
	_update_tool_buttons_visual()
	tool_selected.emit(tool_id)


func _on_seed_btn_pressed(seed_id: String) -> void:
	_play_sfx("click")
	current_seed = seed_id
	current_tool = "plant"
	_update_seed_buttons_visual()
	_update_tool_buttons_visual()
	seed_selected.emit(seed_id)


func _update_tool_buttons_visual() -> void:
	for tool_id in _tool_buttons:
		var btn: Button = _tool_buttons[tool_id]
		if tool_id == current_tool:
			btn.modulate = Color(1.2, 1.2, 0.8)
		else:
			btn.modulate = Color.WHITE


func _update_seed_buttons_visual() -> void:
	for seed_id in _seed_buttons:
		var btn: Button = _seed_buttons[seed_id]
		if seed_id == current_seed:
			btn.modulate = Color(1.2, 1.2, 0.7)
		else:
			if seed_id == "mystery_seed":
				btn.modulate = Color(1.1, 1.0, 0.6)
			else:
				btn.modulate = Color.WHITE


# =========================================================================
# UPGRADES SHED MODAL (Fiona Finch Shop)
# =========================================================================

func _build_upgrades_modal() -> void:
	_upgrades_modal_instance = UpgradesModalScene.instantiate() as UpgradesModal
	_upgrades_modal_instance.hide()
	_upgrades_modal_instance.upgrade_purchased.connect(func(id: String) -> void:
		upgrade_purchased.emit(id)
	)
	_root_control.add_child(_upgrades_modal_instance)


func open_upgrades_modal() -> void:
	_close_all_modals()
	if _upgrades_modal_instance != null:
		var main = get_parent()
		var ups: Dictionary = main.active_upgrades if main != null and "active_upgrades" in main else _cached_upgrades
		_upgrades_modal_instance.open_shop(ups, _cached_coins)


func close_upgrades_modal() -> void:
	if _upgrades_modal_instance != null:
		_upgrades_modal_instance.hide()


func update_upgrades(upgrades: Dictionary) -> void:
	_cached_upgrades = upgrades
	if _upgrades_modal_instance != null and _upgrades_modal_instance.visible:
		_upgrades_modal_instance.open_shop(_cached_upgrades, _cached_coins)


func _play_sfx(sfx_name: String = "click") -> void:
	if is_inside_tree() and has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.play_sfx(sfx_name)
