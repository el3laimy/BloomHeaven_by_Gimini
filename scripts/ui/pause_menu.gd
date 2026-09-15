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
	process_mode = Node.PROCESS_MODE_ALWAYS
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


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		hide()
		resume_requested.emit()
		get_viewport().set_input_as_handled()
