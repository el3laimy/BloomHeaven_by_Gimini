class_name MainMenu
extends Control

## Main Menu Screen for Finest Garden (Bloomhaven).
## Handles New Game, Continue (Save/Load), Settings, and Exit.

const SaveManagerScript := preload("res://scripts/core/save_manager.gd")
const SettingsMenuScript := preload("res://scripts/ui/settings_menu.gd")

@onready var continue_btn: Button = $Center/VBox/ContinueBtn
@onready var new_game_btn: Button = $Center/VBox/NewGameBtn
@onready var settings_btn: Button = $Center/VBox/SettingsBtn
@onready var quit_btn: Button = $Center/VBox/QuitBtn
@onready var settings_menu: PanelContainer = $SettingsMenu


func _ready() -> void:
	if continue_btn:
		var has_save: bool = SaveManagerScript.has_save()
		continue_btn.disabled = not has_save
		continue_btn.pressed.connect(_on_continue_pressed)
	
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game_pressed)
	
	if settings_btn:
		settings_btn.pressed.connect(func():
			if settings_menu:
				settings_menu.show()
		)
	
	if quit_btn:
		quit_btn.pressed.connect(func():
			get_tree().quit()
		)
	
	if settings_menu:
		settings_menu.hide()


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_new_game_pressed() -> void:
	SaveManagerScript.delete_save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
