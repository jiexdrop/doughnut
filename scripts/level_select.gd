extends Control

# ─────────────────────────────────────────────
#  Level Select
#  Pixel art styled, data-driven level selector
#  for Godot 4.
#
#  ADD YOUR WORLDS & LEVELS HERE ↓
# ─────────────────────────────────────────────

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

# ── Level Data ────────────────────────────────
# Each world entry:
#   name    : displayed header
#   color   : accent color for this world's cards
#   levels  : array of { label, scene, locked }
#
# "locked" levels show a padlock icon and cannot be entered.
# Set locked = false (or omit) once the player has unlocked them.
# You can persist unlock state via a save file / autoload as needed.

const WORLDS: Array = [
	{
		"name":   "WORLD 1 – GRASSLANDS",
		"color":  Color(0.25, 0.75, 0.30),
		"levels": [
			{ "label": "1-1",  "scene": "res://scenes/levels_1/level_1.tscn", "locked": false },
			{ "label": "1-2",  "scene": "res://scenes/levels_1/level_2.tscn", "locked": false },
			{ "label": "1-3",  "scene": "res://scenes/levels_1/level_3.tscn", "locked": false },
			{ "label": "1-4",  "scene": "res://scenes/levels_1/level_4.tscn", "locked": false },
			{ "label": "1-5",  "scene": "res://scenes/levels_1/level_5.tscn", "locked": false },
		]
	},
	{
		"name":   "WORLD 2 – CAVES",
		"color":  Color(0.65, 0.45, 0.20),
		"levels": [
			{ "label": "2-1",  "scene": "res://scenes/levels_2/level_1.tscn", "locked": false },
			{ "label": "2-2",  "scene": "res://scenes/levels_2/level_2.tscn", "locked": false },
			{ "label": "2-3",  "scene": "res://scenes/levels_2/level_3.tscn", "locked": false },
			{ "label": "2-4",  "scene": "res://scenes/levels_2/level_4.tscn", "locked": false },
		]
	},
	{
		"name":   "WORLD 3 – OVERWORLD",
		"color":  Color(0.65, 0.45, 0.20),
		"levels": [
			{ "label": "3-1",  "scene": "res://scenes/levels_3/level_1.tscn", "locked": true },
			{ "label": "3-2",  "scene": "res://scenes/levels_3/level_2.tscn", "locked": true },
			{ "label": "3-3",  "scene": "res://scenes/levels_3/level_3.tscn", "locked": true },
			{ "label": "3-B",  "scene": "res://scenes/levels_3/level_boss.tscn", "locked": true },
		]
	},
	# Add more worlds here following the same pattern ↑
]

# ── Node refs ─────────────────────────────────
@onready var _content_vbox : VBoxContainer  = $ScrollContainer/ContentVBox
@onready var _back_btn     : Button         = $TopBar/BackButton


func _ready() -> void:
	_apply_top_bar_style()
	_back_btn.pressed.connect(_on_back_pressed)
	_build_level_grid()


# ── Navigation ────────────────────────────────

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _load_level(scene_path: String) -> void:
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_warning("LevelSelect: scene not found – " + scene_path)


# ── UI building ───────────────────────────────

func _build_level_grid() -> void:
	for world_data in WORLDS:
		_content_vbox.add_child(_make_world_section(world_data))


func _make_world_section(world_data: Dictionary) -> MarginContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 10)

	# ── World header label
	var header := Label.new()
	header.text = world_data["name"]
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", world_data["color"])
	_style_header(header, world_data["color"])
	section.add_child(header)

	# ── Divider line
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", world_data["color"])
	section.add_child(sep)

	# ── Level button grid
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)

	for lvl: Dictionary in world_data["levels"]:
		grid.add_child(_make_level_card(lvl, world_data["color"]))

	section.add_child(grid)

	# Outer padding
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   32)
	margin.add_theme_constant_override("margin_right",  32)
	margin.add_theme_constant_override("margin_top",    12)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.add_child(section)
	return margin


func _make_level_card(lvl: Dictionary, accent: Color) -> Button:
	var btn := Button.new()
	var locked: bool = lvl.get("locked", false)

	btn.custom_minimum_size = Vector2(90, 90)
	btn.text = ("🔒\n" if locked else "") + lvl["label"]
	btn.disabled = locked
	btn.add_theme_font_size_override("font_size", 16)

	# Base style
	var normal := _make_card_style(accent, locked)
	var hover  := _make_card_style(accent, locked)
	hover.bg_color = accent * 0.35
	hover.border_color = accent
	var pressed := _make_card_style(accent, locked)
	pressed.bg_color = accent * 0.5

	btn.add_theme_stylebox_override("normal",   normal)
	btn.add_theme_stylebox_override("hover",    hover)
	btn.add_theme_stylebox_override("pressed",  pressed)
	btn.add_theme_stylebox_override("disabled", _make_card_style(Color(0.3, 0.3, 0.3), true))

	if not locked:
		btn.add_theme_color_override("font_color",         Color(0.95, 0.95, 0.95))
		btn.add_theme_color_override("font_hover_color",   Color(1, 1, 0.6))
		btn.add_theme_color_override("font_pressed_color", accent)
		btn.pressed.connect(_load_level.bind(lvl["scene"]))
	else:
		btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))

	return btn


func _make_card_style(accent: Color, locked: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = Color(0.10, 0.10, 0.20) if not locked else Color(0.07, 0.07, 0.12)
	sb.border_color               = accent * (0.4 if locked else 0.7)
	sb.border_width_left          = 2
	sb.border_width_right         = 2
	sb.border_width_top           = 2
	sb.border_width_bottom        = 2
	sb.corner_radius_top_left     = 0
	sb.corner_radius_top_right    = 0
	sb.corner_radius_bottom_left  = 0
	sb.corner_radius_bottom_right = 0
	return sb


func _style_header(label: Label, accent: Color) -> void:
	# Pixel-art pixel-shadow effect on the header text
	label.add_theme_color_override("font_shadow_color", accent * 0.4)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)


func _apply_top_bar_style() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.05, 0.05, 0.12)
	sb.border_color = Color(1.0, 0.88, 0.12)
	sb.border_width_bottom = 2
	$TopBar.add_theme_stylebox_override("panel", sb)

	# Style back button
	var bsb := StyleBoxFlat.new()
	bsb.bg_color     = Color(0.10, 0.10, 0.20)
	bsb.border_color = Color(0.8, 0.7, 0.2)
	bsb.border_width_left   = 2
	bsb.border_width_right  = 2
	bsb.border_width_top    = 2
	bsb.border_width_bottom = 2
	for state in ["normal", "hover", "pressed"]:
		_back_btn.add_theme_stylebox_override(state, bsb)
	_back_btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
