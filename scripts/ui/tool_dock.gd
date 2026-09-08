class_name ToolDock
extends Control

## Gardener's Carved Wood Action Dock & Lily Portrait Hub.

signal tool_changed(tool_name: String)
signal seeds_toggle_requested()
signal lily_hub_toggle_requested()

@onready var plant_btn: TextureButton = $DockRow/DockContainer/HBox/PlantCol/PlantBtn
@onready var water_btn: TextureButton = $DockRow/DockContainer/HBox/WaterCol/WaterBtn
@onready var prune_btn: TextureButton = $DockRow/DockContainer/HBox/PruneCol/PruneBtn
@onready var harvest_btn: TextureButton = $DockRow/DockContainer/HBox/HarvestCol/HarvestBtn
@onready var lily_btn: TextureButton = $DockRow/LilyCol/LilyBtn
@onready var active_glow: TextureRect = $DockRow/DockContainer/ActiveGlowRing

var current_tool: String = "plant"
var _buttons_map: Dictionary = {}


func _ready() -> void:
	_buttons_map = {
		"plant": plant_btn,
		"water": water_btn,
		"prune": prune_btn,
		"harvest": harvest_btn
	}

	if plant_btn:
		plant_btn.pressed.connect(func(): select_tool("plant"))
	if water_btn:
		water_btn.pressed.connect(func(): select_tool("water"))
	if prune_btn:
		prune_btn.pressed.connect(func(): select_tool("prune"))
	if harvest_btn:
		harvest_btn.pressed.connect(func(): select_tool("harvest"))
	if lily_btn:
		lily_btn.pressed.connect(func():
			lily_hub_toggle_requested.emit()
			_play_click()
		)

	call_deferred("_update_active_glow_position")


func select_tool(tool_name: String) -> void:
	current_tool = tool_name
	_update_active_glow_position()
	tool_changed.emit(current_tool)
	_play_click()


func _update_active_glow_position() -> void:
	if active_glow == null:
		return
	if not _buttons_map.has(current_tool):
		active_glow.visible = false
		return

	var target_btn: TextureButton = _buttons_map[current_tool]
	if not is_instance_valid(target_btn):
		active_glow.visible = false
		return

	active_glow.visible = true
	# Center active_glow over target_btn
	var btn_global_center := target_btn.global_position + (target_btn.size * 0.5)
	active_glow.global_position = btn_global_center - (active_glow.size * 0.5)

	# Pulse tween effect
	var tw := create_tween()
	active_glow.scale = Vector2(0.92, 0.92)
	active_glow.pivot_offset = active_glow.size * 0.5
	tw.tween_property(active_glow, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(active_glow, "scale", Vector2(1.0, 1.0), 0.1)


func _play_click() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		var am = get_tree().root.get_node("AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.play_sfx("click")
