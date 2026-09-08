class_name TutorialOverlay
extends Control

## First-Time User Experience (FTUE) Interactive Tutorial for Finest Garden.
## Guides player through Planting, Watering, Pruning (Hero Bloom), and Harvesting.

signal tutorial_step_completed(step_index: int)
signal tutorial_finished()

@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var desc_label: Label = $Panel/Margin/VBox/DescLabel
@onready var next_btn: Button = $Panel/Margin/VBox/NextBtn

var current_step: int = 0

const STEPS: Array[Dictionary] = [
	{
		"title": "🌱 Step 1: Plant Your First Flower",
		"desc": "Select the 'Red Rose' from the seed bar at the bottom, then click on any empty soil plot to plant it!"
	},
	{
		"title": "💧 Step 2: Water for Rapid Growth",
		"desc": "Switch to the 'Water Tool' and click your plot. Watering keeps the soil moist and doubles the growth speed!"
	},
	{
		"title": "✂️ Step 3: Prune for Hero Blooms (★★★)",
		"desc": "When your plant reaches the young sprout stage, use the 'Prune Tool ✂️' to trim side shoots and produce a magnificent Hero Bloom!"
	},
	{
		"title": "🧺 Step 4: Harvest & Cross-Breed",
		"desc": "Once fully mature, harvest your bloom to fulfill customer orders, or preserve it in the Breeding Lab 🧬 to create rare hybrids!"
	}
]


func _ready() -> void:
	if next_btn:
		next_btn.pressed.connect(_on_next_pressed)
	hide()


func show_step(step_idx: int) -> void:
	current_step = step_idx
	if current_step >= STEPS.size():
		hide()
		tutorial_finished.emit()
		return

	show()
	var info: Dictionary = STEPS[current_step]
	if title_label:
		title_label.text = info["title"]
	if desc_label:
		desc_label.text = info["desc"]
	if next_btn:
		next_btn.text = "Next ➔" if current_step < STEPS.size() - 1 else "Start Gardening! 🌿"


func _on_next_pressed() -> void:
	tutorial_step_completed.emit(current_step)
	show_step(current_step + 1)
