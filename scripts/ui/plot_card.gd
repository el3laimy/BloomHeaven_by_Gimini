class_name PlotCard
extends Control

## Botanical Plot Info Card (Weathered Parchment Style) for BloomHaven.
## Displays flower portrait, species title, moisture droplets gauge, pruning status,
## and a 4-step growth stage timeline with golden active selector.

@onready var card_frame: NinePatchRect = $CardParchment
@onready var header_rect: TextureRect = $HeaderPlaque
@onready var flower_icon: TextureRect = $CardParchment/Margin/VBox/ContentHBox/FlowerPortrait
@onready var title_label: Label = $CardParchment/Margin/VBox/ContentHBox/DetailsVBox/SpeciesName
@onready var stage_label: Label = $CardParchment/Margin/VBox/ContentHBox/DetailsVBox/StageLevel
@onready var droplets_hbox: HBoxContainer = $CardParchment/Margin/VBox/ContentHBox/DetailsVBox/MoistureHBox/Droplets
@onready var prune_badge: TextureRect = $CardParchment/Margin/VBox/ContentHBox/DetailsVBox/PruneBadge
@onready var stages_hbox: HBoxContainer = $CardParchment/Margin/VBox/TimelineVBox/StagesHBox
@onready var stage_selector: TextureRect = $CardParchment/Margin/VBox/TimelineVBox/ActiveSelector
@onready var close_btn: Button = $CloseBtn

var _active_stage_idx: int = 0


func _ready() -> void:
	if close_btn != null:
		close_btn.pressed.connect(func(): hide())
	hide()


func display_plot(plot_data: Dictionary) -> void:
	show()
	var plot_index: int = plot_data.get("index", 0)
	var flower_id: String = plot_data.get("flower_id", "")
	var state_name: String = plot_data.get("state", "Empty")
	var moisture: float = plot_data.get("moisture", 0.0)
	var growth_progress: float = plot_data.get("growth_progress", 0.0)
	var quality: int = plot_data.get("quality", 1)
	var is_pruned: bool = plot_data.get("is_pruned", false)

	# 1. Species Title & Stage Name
	if flower_id.is_empty():
		title_label.text = "Empty Loam"
		stage_label.text = "Ready to sow seeds"
		flower_icon.texture = null
		_active_stage_idx = -1
	else:
		var f_data := FlowerData.get_flower(flower_id)
		var f_name: String = f_data.get("display_name", flower_id.capitalize())
		title_label.text = f_name
		flower_icon.texture = _get_flower_texture(flower_id)

		if state_name == "Mature":
			stage_label.text = "Stage 4 · Full Bloom ★%d" % quality
			_active_stage_idx = 3
		elif growth_progress > 0.65:
			stage_label.text = "Stage 3 · Bud Forming"
			_active_stage_idx = 2
		elif growth_progress > 0.25:
			stage_label.text = "Stage 2 · Young Bush"
			_active_stage_idx = 1
		else:
			stage_label.text = "Stage 1 · Seedling Sprout"
			_active_stage_idx = 0

	# 2. Moisture droplets (4 droplets gauge)
	_update_moisture_droplets(moisture)

	# 3. Pruning Badge
	if prune_badge != null:
		prune_badge.visible = is_pruned

	# 4. Growth Timeline Selector
	call_deferred("_update_timeline_selector")


func _update_moisture_droplets(moisture: float) -> void:
	if droplets_hbox == null:
		return
	var filled_tex := preload("res://assets/ui/plot_info/droplet_blue.png")
	var empty_tex := preload("res://assets/ui/plot_info/droplet_gray.png")

	# 4 droplets calculation
	var filled_count := int(ceil(clamp(moisture, 0.0, 1.0) * 4.0))
	for i in range(4):
		var drop: TextureRect = droplets_hbox.get_node_or_null("Drop%d" % (i + 1))
		if drop != null:
			drop.texture = filled_tex if (i < filled_count) else empty_tex


func _update_timeline_selector() -> void:
	if stage_selector == null or stages_hbox == null:
		return
	if _active_stage_idx < 0 or _active_stage_idx >= stages_hbox.get_child_count():
		stage_selector.visible = false
		return

	stage_selector.visible = true
	var target_stage: Control = stages_hbox.get_child(_active_stage_idx) as Control
	if target_stage != null:
		var target_center := target_stage.global_position + (target_stage.size * 0.5)
		stage_selector.global_position = target_center - (stage_selector.size * 0.5)


func _get_flower_texture(flower_id: String) -> Texture2D:
	var path := ""
	match flower_id:
		"rose": path = "res://assets/flowers/growth_stages/rose_crimson_bloom_standard.png"
		"lavender": path = "res://assets/flowers/growth_stages/lavender_bloom_standard.png"
		"sunflower": path = "res://assets/flowers/master_sunflower.png"
		"tulip": path = "res://assets/flowers/growth_stages/tulip_bloom_standard.png"
		"daisy": path = "res://assets/flowers/growth_stages/daisy_bloom_standard.png"
		"roselight": path = "res://assets/flowers/master_roselight.png"
		"golden_rose": path = "res://assets/flowers/master_golden_rose.png"
		"sunflare_spike": path = "res://assets/flowers/master_sunflare_spike.png"
		_: path = "res://assets/flowers/growth_stages/rose_crimson_bloom_standard.png"
	if ResourceLoader.exists(path):
		return load(path)
	return null
