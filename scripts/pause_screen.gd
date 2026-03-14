extends Control

# Emitted signals — connect these in your game manager / level controller
signal continue_pressed
signal main_menu_pressed

@onready var continue_button: Button = %ContinueButton
@onready var main_menu_button: Button = %MainMenuButton

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)


func _on_continue_pressed() -> void:
	emit_signal("continue_pressed")


func _on_main_menu_pressed() -> void:
	emit_signal("main_menu_pressed")
