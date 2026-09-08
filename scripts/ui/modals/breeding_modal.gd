class_name BreedingModal
extends Control

## Standalone UI Modal for the Botanical Breeding Conservatory & Genetics Workshop.
## Redesigned with cozy storybook aesthetics, real botanical artwork preview pedestals,
## dynamic hybrid outcome predictions, and illustrated specimen cabinet grid.

signal breed_performed(parent_a_id: String, parent_b_id: String, specimen_a: FlowerSpecimen, specimen_b: FlowerSpecimen)
signal closed()

@onready var _close_btn: Button = $CenterContainer/Panel/Margin/VBox/HeaderHBox/CloseBtn
@onready var _slot_a_panel: PanelContainer = $CenterContainer/Panel/Margin/VBox/AltarSection/SlotA
@onready var _slot_a_tex: TextureRect = $CenterContainer/Panel/Margin/VBox/AltarSection/SlotA/Margin/VBox/Texture
@onready var _slot_a_label: Label = $CenterContainer/Panel/Margin/VBox/AltarSection/SlotA/Margin/VBox/Label
@onready var _slot_a_trait: Label = $CenterContainer/Panel/Margin/VBox/AltarSection/SlotA/Margin/VBox/TraitLabel
@onready var _slot_a_clear_btn: Button = $CenterContainer/Panel/Margin/VBox/AltarSection/SlotA/Margin/VBox/Header/ClearBtnA

@onready var _slot_b_panel: PanelContainer = $CenterContainer/Panel/Margin/VBox/AltarSection/SlotB
@onready var _slot_b_tex: TextureRect = $CenterContainer/Panel/Margin/VBox/AltarSection/SlotB/Margin/VBox/Texture
@onready var _slot_b_label: Label = $CenterContainer/Panel/Margin/VBox/AltarSection/SlotB/Margin/VBox/Label
@onready var _slot_b_trait: Label = $CenterContainer/Panel/Margin/VBox/AltarSection/SlotB/Margin/VBox/TraitLabel
@onready var _slot_b_clear_btn: Button = $CenterContainer/Panel/Margin/VBox/AltarSection/SlotB/Margin/VBox/Header/ClearBtnB

@onready var _preview_label: Label = $CenterContainer/Panel/Margin/VBox/AltarSection/CenterCrucible/PreviewBox/Margin/VBox/PreviewLabel
@onready var _preview_tex: TextureRect = $CenterContainer/Panel/Margin/VBox/AltarSection/CenterCrucible/PreviewBox/Margin/VBox/PreviewTexture
@onready var _breed_btn: Button = $CenterContainer/Panel/Margin/VBox/ActionHBox/BreedBtn
@onready var _clear_btn: Button = $CenterContainer/Panel/Margin/VBox/ActionHBox/ClearBtn

@onready var _tab_base_btn: Button = $CenterContainer/Panel/Margin/VBox/CabinetHeader/TabBase
@onready var _tab_roster_btn: Button = $CenterContainer/Panel/Margin/VBox/CabinetHeader/TabRoster
@onready var _roster_grid: GridContainer = $CenterContainer/Panel/Margin/VBox/Scroll/RosterGrid
@onready var _roster_vbox: VBoxContainer = $CenterContainer/Panel/Margin/VBox/Scroll/RosterVBox

var selected_parent_a_id: String = ""
var selected_parent_b_id: String = ""
var selected_specimen_a: FlowerSpecimen = null
var selected_specimen_b: FlowerSpecimen = null

var available_roster: Array[FlowerSpecimen] = []
var basic_inventory: Dictionary = {}

var _active_tab: int = 0 # 0: Garden Flowers, 1: Preserved Roster

static var _flower_tex_cache: Dictionary = {}


func _ready() -> void:
	if _close_btn != null:
		_close_btn.pressed.connect(func():
			_play_click()
			hide()
			closed.emit()
		)
	if _clear_btn != null:
		_clear_btn.pressed.connect(clear_slots)
	if _breed_btn != null:
		_breed_btn.pressed.connect(_on_breed_clicked)
	if _slot_a_clear_btn != null:
		_slot_a_clear_btn.pressed.connect(_clear_slot_a)
	if _slot_b_clear_btn != null:
		_slot_b_clear_btn.pressed.connect(_clear_slot_b)

	if _tab_base_btn != null:
		_tab_base_btn.pressed.connect(func():
			_active_tab = 0
			_play_click()
			_update_tab_styles()
			_populate_roster()
		)
	if _tab_roster_btn != null:
		_tab_roster_btn.pressed.connect(func():
			_active_tab = 1
			_play_click()
			_update_tab_styles()
			_populate_roster()
		)

	_update_tab_styles()


func open_lab(roster: Array[FlowerSpecimen], inventory: Dictionary) -> void:
	available_roster = roster
	basic_inventory = inventory
	clear_slots()
	_update_tab_styles()
	_populate_roster()
	show()


func clear_slots() -> void:
	_play_click()
	selected_parent_a_id = ""
	selected_parent_b_id = ""
	selected_specimen_a = null
	selected_specimen_b = null
	_update_slots_ui()
	_populate_roster()


func _clear_slot_a() -> void:
	_play_click()
	selected_parent_a_id = ""
	selected_specimen_a = null
	_update_slots_ui()
	_populate_roster()


func _clear_slot_b() -> void:
	_play_click()
	selected_parent_b_id = ""
	selected_specimen_b = null
	_update_slots_ui()
	_populate_roster()


func _update_tab_styles() -> void:
	if _tab_base_btn != null:
		if _active_tab == 0:
			_tab_base_btn.modulate = Color(1.0, 0.95, 0.6)
		else:
			_tab_base_btn.modulate = Color(0.7, 0.7, 0.7)
	if _tab_roster_btn != null:
		if _active_tab == 1:
			_tab_roster_btn.modulate = Color(1.0, 0.95, 0.6)
		else:
			_tab_roster_btn.modulate = Color(0.7, 0.7, 0.7)


func _populate_roster() -> void:
	if _roster_grid != null:
		for child in _roster_grid.get_children():
			child.queue_free()

	# Also maintain _roster_vbox for strict test compatibility if referenced
	if _roster_vbox != null:
		for child in _roster_vbox.get_children():
			child.queue_free()

	if _active_tab == 0:
		# 1. Base Garden Flowers from inventory
		var basic_species: Array[String] = ["rose", "tulip", "daisy", "lavender", "sunflower"]
		for s_id in basic_species:
			var count: int = basic_inventory.get(s_id, 0)
			var card := _create_grid_species_card(s_id, count)
			if _roster_grid != null:
				_roster_grid.add_child(card)

		# Also check for harvested hybrid flowers in basic inventory
		for h_id in ["roselight", "golden_rose", "sunflare_spike"]:
			var count: int = basic_inventory.get(h_id, 0)
			if count > 0:
				var card := _create_grid_species_card(h_id, count)
				if _roster_grid != null:
					_roster_grid.add_child(card)
	else:
		# 2. Registered FlowerSpecimens from breeding roster
		if available_roster.is_empty():
			var empty_lbl := Label.new()
			empty_lbl.text = "No preserved hybrid specimens in roster yet.\nCross-breed your first seeds to register prize specimens!"
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.7))
			empty_lbl.add_theme_font_size_override("font_size", 11)
			if _roster_grid != null:
				_roster_grid.add_child(empty_lbl)
		else:
			for specimen in available_roster:
				if is_instance_valid(specimen):
					var card := _create_grid_specimen_card(specimen)
					if _roster_grid != null:
						_roster_grid.add_child(card)


func _create_grid_species_card(species_id: String, count: int) -> PanelContainer:
	var f_data := FlowerData.get_flower(species_id)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(165, 140)

	var style := StyleBoxFlat.new()
	var is_in_a: bool = (selected_parent_a_id == species_id and selected_specimen_a == null)
	var is_in_b: bool = (selected_parent_b_id == species_id and selected_specimen_b == null)

	if is_in_a or is_in_b:
		style.bg_color = Color(0.12, 0.22, 0.16, 0.95)
		style.border_color = Color(1.0, 0.88, 0.35, 1.0)
		style.set_border_width_all(2)
	else:
		style.bg_color = Color(0.08, 0.14, 0.10, 0.9)
		style.border_color = Color(0.24, 0.38, 0.28, 0.8)
		style.set_border_width_all(1)

	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Header: Name and Stock
	var title_lbl := Label.new()
	title_lbl.text = f_data.get("display_name", species_id)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	vbox.add_child(title_lbl)

	# Botanical Thumbnail
	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(52, 52)
	tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture = get_flower_texture(species_id)
	vbox.add_child(tex_rect)

	# Stock & Trait Pill
	var stock_lbl := Label.new()
	stock_lbl.text = "Stock: %d" % count
	stock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stock_lbl.add_theme_font_size_override("font_size", 10)
	if count > 0:
		stock_lbl.add_theme_color_override("font_color", Color(0.5, 0.95, 0.6))
	else:
		stock_lbl.add_theme_color_override("font_color", Color(0.85, 0.45, 0.45))
	vbox.add_child(stock_lbl)

	# Selection Buttons
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox)

	var btn_a := Button.new()
	btn_a.text = "✓ Slot A" if is_in_a else "Slot A"
	btn_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_a.custom_minimum_size = Vector2(0, 24)
	btn_a.add_theme_font_size_override("font_size", 10)
	btn_a.disabled = (count <= 0)
	btn_a.pressed.connect(func():
		_play_click()
		selected_parent_a_id = species_id
		selected_specimen_a = null
		_pop_pedestal(_slot_a_panel)
		_update_slots_ui()
		_populate_roster()
	)
	hbox.add_child(btn_a)

	var btn_b := Button.new()
	btn_b.text = "✓ Slot B" if is_in_b else "Slot B"
	btn_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_b.custom_minimum_size = Vector2(0, 24)
	btn_b.add_theme_font_size_override("font_size", 10)
	btn_b.disabled = (count <= 0)
	btn_b.pressed.connect(func():
		_play_click()
		selected_parent_b_id = species_id
		selected_specimen_b = null
		_pop_pedestal(_slot_b_panel)
		_update_slots_ui()
		_populate_roster()
	)
	hbox.add_child(btn_b)

	return card


func _create_grid_specimen_card(specimen: FlowerSpecimen) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(165, 140)

	var style := StyleBoxFlat.new()
	var is_in_a: bool = (selected_specimen_a == specimen)
	var is_in_b: bool = (selected_specimen_b == specimen)

	if is_in_a or is_in_b:
		style.bg_color = Color(0.14, 0.24, 0.18, 0.95)
		style.border_color = Color(1.0, 0.88, 0.35, 1.0)
		style.set_border_width_all(2)
	else:
		style.bg_color = Color(0.09, 0.15, 0.12, 0.9)
		style.border_color = Color(0.3, 0.45, 0.35, 0.8)
		style.set_border_width_all(1)

	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "✨ %s" % specimen.get_display_title()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	vbox.add_child(title_lbl)

	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(52, 52)
	tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture = get_flower_texture(specimen.species_id)
	vbox.add_child(tex_rect)

	var info_lbl := Label.new()
	info_lbl.text = "Gen %d · %s" % [specimen.generation, specimen.phenotype.color_name if specimen.phenotype else "Pure"]
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_lbl.add_theme_font_size_override("font_size", 10)
	info_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.8))
	vbox.add_child(info_lbl)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox)

	var btn_a := Button.new()
	btn_a.text = "✓ Slot A" if is_in_a else "Slot A"
	btn_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_a.custom_minimum_size = Vector2(0, 24)
	btn_a.add_theme_font_size_override("font_size", 10)
	btn_a.pressed.connect(func():
		_play_click()
		selected_parent_a_id = specimen.species_id
		selected_specimen_a = specimen
		_pop_pedestal(_slot_a_panel)
		_update_slots_ui()
		_populate_roster()
	)
	hbox.add_child(btn_a)

	var btn_b := Button.new()
	btn_b.text = "✓ Slot B" if is_in_b else "Slot B"
	btn_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_b.custom_minimum_size = Vector2(0, 24)
	btn_b.add_theme_font_size_override("font_size", 10)
	btn_b.pressed.connect(func():
		_play_click()
		selected_parent_b_id = specimen.species_id
		selected_specimen_b = specimen
		_pop_pedestal(_slot_b_panel)
		_update_slots_ui()
		_populate_roster()
	)
	hbox.add_child(btn_b)

	return card


func _pop_pedestal(panel: Control) -> void:
	if panel == null:
		return
	var tween := create_tween()
	panel.scale = Vector2(0.95, 0.95)
	panel.pivot_offset = panel.size * 0.5
	tween.tween_property(panel, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.08)


func _update_slots_ui() -> void:
	# 1. Parent A Pedestal
	if _slot_a_label != null:
		if not selected_parent_a_id.is_empty():
			var name_a: String = selected_specimen_a.get_display_title() if selected_specimen_a != null else FlowerData.get_flower(selected_parent_a_id).get("display_name", selected_parent_a_id)
			_slot_a_label.text = name_a
			_slot_a_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
			if _slot_a_tex != null:
				_slot_a_tex.texture = get_flower_texture(selected_parent_a_id)
				_slot_a_tex.visible = true
			if _slot_a_trait != null:
				_slot_a_trait.text = _get_flower_trait_summary(selected_parent_a_id, selected_specimen_a)
				_slot_a_trait.add_theme_color_override("font_color", Color(0.7, 0.9, 0.75))
			if _slot_a_clear_btn != null:
				_slot_a_clear_btn.visible = true
		else:
			_slot_a_label.text = "Empty Slot"
			_slot_a_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.65))
			if _slot_a_tex != null:
				_slot_a_tex.visible = false
			if _slot_a_trait != null:
				_slot_a_trait.text = "Select specimen below"
				_slot_a_trait.add_theme_color_override("font_color", Color(0.5, 0.6, 0.55))
			if _slot_a_clear_btn != null:
				_slot_a_clear_btn.visible = false

	# 2. Parent B Pedestal
	if _slot_b_label != null:
		if not selected_parent_b_id.is_empty():
			var name_b: String = selected_specimen_b.get_display_title() if selected_specimen_b != null else FlowerData.get_flower(selected_parent_b_id).get("display_name", selected_parent_b_id)
			_slot_b_label.text = name_b
			_slot_b_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
			if _slot_b_tex != null:
				_slot_b_tex.texture = get_flower_texture(selected_parent_b_id)
				_slot_b_tex.visible = true
			if _slot_b_trait != null:
				_slot_b_trait.text = _get_flower_trait_summary(selected_parent_b_id, selected_specimen_b)
				_slot_b_trait.add_theme_color_override("font_color", Color(0.7, 0.9, 0.75))
			if _slot_b_clear_btn != null:
				_slot_b_clear_btn.visible = true
		else:
			_slot_b_label.text = "Empty Slot"
			_slot_b_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.65))
			if _slot_b_tex != null:
				_slot_b_tex.visible = false
			if _slot_b_trait != null:
				_slot_b_trait.text = "Select specimen below"
				_slot_b_trait.add_theme_color_override("font_color", Color(0.5, 0.6, 0.55))
			if _slot_b_clear_btn != null:
				_slot_b_clear_btn.visible = false

	# 3. Dynamic Outcome Simulation & Crucible Prediction
	var can_breed: bool = not selected_parent_a_id.is_empty() and not selected_parent_b_id.is_empty()
	if _breed_btn != null:
		_breed_btn.disabled = not can_breed

	if _preview_label != null:
		if can_breed:
			var resolved_hybrid := GeneticsEngine.resolve_species(selected_parent_a_id, selected_parent_b_id)
			if not resolved_hybrid.is_empty() and resolved_hybrid != selected_parent_a_id:
				# Emergent hybrid discovery
				var h_data := FlowerData.get_flower(resolved_hybrid)
				var h_name: String = h_data.get("display_name", resolved_hybrid.capitalize())
				_preview_label.text = "✨ Emergent Hybrid: %s!\nCombines %s with %s (100%% Pollination Rate)" % [
					h_name,
					FlowerData.get_flower(selected_parent_a_id).get("display_name", selected_parent_a_id),
					FlowerData.get_flower(selected_parent_b_id).get("display_name", selected_parent_b_id)
				]
				_preview_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
				if _preview_tex != null:
					_preview_tex.texture = get_flower_texture(resolved_hybrid)
					_preview_tex.visible = true
				if _breed_btn != null:
					_breed_btn.text = "✨ Pollinate & Harvest %s Seed 🌾" % h_name
			elif selected_parent_a_id == selected_parent_b_id:
				# Purebred Lineage Refinement
				var sp_name: String = FlowerData.get_flower(selected_parent_a_id).get("display_name", selected_parent_a_id)
				_preview_label.text = "🌱 Purebred Lineage Refinement (%s)\nReinforces heritable vigor, fragrance rating & petal size." % sp_name
				_preview_label.add_theme_color_override("font_color", Color(0.5, 0.95, 0.7))
				if _preview_tex != null:
					_preview_tex.texture = get_flower_texture(selected_parent_a_id)
					_preview_tex.visible = true
				if _breed_btn != null:
					_breed_btn.text = "✨ Pollinate Purebred %s Seed 🌾" % sp_name
			else:
				# Incompatible cross
				_preview_label.text = "⚠️ Incompatible Cross\nThese species cannot pollinate together. Try:\n🌹 Rose + 🪻 Lavender (Roselight)\n🌹 Rose + 🌻 Sunflower (Golden Rose)\n🪻 Lavender + 🌻 Sunflower (Sunflare)"
				_preview_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.4))
				if _preview_tex != null:
					_preview_tex.visible = false
				if _breed_btn != null:
					_breed_btn.disabled = true
					_breed_btn.text = "⚠️ Incompatible Species"
		else:
			_preview_label.text = "Select two parent specimens to simulate genetic inheritance."
			_preview_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.7))
			if _preview_tex != null:
				_preview_tex.visible = false
			if _breed_btn != null:
				_breed_btn.text = "✨ Cross-Breed Hybrid Seed"


func _get_flower_trait_summary(species_id: String, specimen: FlowerSpecimen) -> String:
	if specimen != null and specimen.phenotype != null:
		return "%s · Fragrance: %d★" % [specimen.phenotype.color_name, specimen.phenotype.fragrance_rating]
	match species_id:
		"rose": return "Crimson Red · Fragrance: 3★"
		"lavender": return "Aromatic Stalk · Fragrance: 4★"
		"sunflower": return "Golden Radiant · Exceptional Vigor"
		"tulip": return "Orange Flame · Fragrance: 3★"
		"daisy": return "Sunny Disc · Star Petals"
		"roselight": return "Plum Magenta · Luminescent"
		"golden_rose": return "Sun-Kissed Gold · Rare ★★★"
		"sunflare_spike": return "Solar Amber · Rare ★★★"
		_: return "Botanical Specimen"


func _on_breed_clicked() -> void:
	if selected_parent_a_id.is_empty() or selected_parent_b_id.is_empty():
		return

	_play_harvest_chime()
	breed_performed.emit(selected_parent_a_id, selected_parent_b_id, selected_specimen_a, selected_specimen_b)
	hide()
	closed.emit()


func _play_click() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		get_tree().root.get_node("AudioManager").play_sfx("click")


func _play_harvest_chime() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		get_tree().root.get_node("AudioManager").play_sfx("harvest")


static func get_flower_texture(flower_id: String) -> Texture2D:
	if _flower_tex_cache.has(flower_id):
		return _flower_tex_cache[flower_id]

	var path: String = ""
	match flower_id:
		"sunflower": path = "res://assets/flowers/master_sunflower.png"
		"roselight": path = "res://assets/flowers/master_roselight.png"
		"golden_rose": path = "res://assets/flowers/master_golden_rose.png"
		"sunflare_spike": path = "res://assets/flowers/master_sunflare_spike.png"
		"rose": path = "res://assets/flowers/growth_stages/rose_crimson_bloom_standard.png"
		"tulip": path = "res://assets/flowers/growth_stages/tulip_bloom_standard.png"
		"daisy": path = "res://assets/flowers/growth_stages/daisy_bloom_standard.png"
		"lavender": path = "res://assets/flowers/growth_stages/lavender_bloom_standard.png"
		_:
			var f_data := FlowerData.get_flower(flower_id)
			path = f_data.get("master_sprite", "res://assets/flowers/growth_stages/rose_crimson_bloom_standard.png")

	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		_flower_tex_cache[flower_id] = tex
		return tex

	return null
