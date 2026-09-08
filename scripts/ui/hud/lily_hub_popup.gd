class_name LilyHubPopup
extends Control

## Lily's Cozy Hub Menu.
## Consolidates Lily's personal botanical journal, shed upgrades shop,
## breeding laboratory, and bouquet workshop into a single warm character hub.

signal open_journal_requested()
signal open_upgrades_requested()
signal open_breeding_requested()
signal open_bouquets_requested()

@onready var panel: PanelContainer = $Panel
@onready var journal_btn: Button = $Panel/Margin/VBox/Buttons/JournalBtn
@onready var upgrades_btn: Button = $Panel/Margin/VBox/Buttons/UpgradesBtn
@onready var breeding_btn: Button = $Panel/Margin/VBox/Buttons/BreedingBtn
@onready var bouquets_btn: Button = $Panel/Margin/VBox/Buttons/BouquetsBtn
@onready var close_btn: Button = $Panel/Margin/VBox/HeaderHBox/CloseBtn


func _ready() -> void:
	hide()
	if journal_btn:
		journal_btn.pressed.connect(func():
			hide()
			open_journal_requested.emit()
			_play_click()
		)
	if upgrades_btn:
		upgrades_btn.pressed.connect(func():
			hide()
			open_upgrades_requested.emit()
			_play_click()
		)
	if breeding_btn:
		breeding_btn.pressed.connect(func():
			hide()
			open_breeding_requested.emit()
			_play_click()
		)
	if bouquets_btn:
		bouquets_btn.pressed.connect(func():
			hide()
			open_bouquets_requested.emit()
			_play_click()
		)
	if close_btn:
		close_btn.pressed.connect(func():
			hide()
			_play_click()
		)


func toggle() -> void:
	if visible:
		hide()
	else:
		show()
		_play_click()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide()


func _play_click() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		var am = get_tree().root.get_node("AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.play_sfx("click")
