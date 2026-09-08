class_name PauseMenu
extends PanelContainer

## Pause Menu for Finest Garden.
## Provides options to Resume, open Settings, Save Game, or Quit to Main Menu.

signal resume_requested()
signal settings_requested()
signal save_requested()
signal main_menu_requested()

@onready var resume_btn: Button = $Margin/VBox/ResumeBtn
@onready var settings_btn: Button = $Margin/VBox/SettingsBtn
@onready var save_btn: Button = $Margin/VBox/SaveBtn
@onready var main_menu_btn: Button = $Margin/VBox/MainMenuBtn


func _ready() -> void:
	if resume_btn:
		resume_btn.pressed.connect(func():
			hide()
			resume_requested.emit()
		)
	if settings_btn:
		settings_btn.pressed.connect(func():
			settings_requested.emit()
		)
	if save_btn:
		save_btn.pressed.connect(func():
			save_requested.emit()
		)
	if main_menu_btn:
		main_menu_btn.pressed.connect(func():
			main_menu_requested.emit()
		)
