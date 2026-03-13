extends Control

# Emitted signals — connect these in your game manager / level controller
signal next_level_pressed
signal main_menu_pressed

@onready var next_level_button: Button = %NextLevelButton
@onready var main_menu_button: Button = %MainMenuButton

func _ready() -> void:
	next_level_button.pressed.connect(_on_next_level_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)


func _on_next_level_pressed() -> void:
	emit_signal("next_level_pressed")


func _on_main_menu_pressed() -> void:
	emit_signal("main_menu_pressed")
