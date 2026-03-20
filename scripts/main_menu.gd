extends Control

# ─────────────────────────────────────────────
#  Main Menu
#  Pixel art styled main menu for Godot 4
# ─────────────────────────────────────────────

const LEVEL_SELECT_SCENE := "res://scenes/ui/level_select.tscn"
const FIRST_LEVEL_SCENE  := "res://scenes/levels_1/level_1.tscn"
const OPTIONS_SCENE  := "res://scenes/ui/options.tscn"

# Starfield pixel art effect
var _stars: Array[Dictionary] = []
const STAR_COUNT := 80

@onready var _play_btn         : Button    = $CenterContainer/PlayButton
@onready var _level_select_btn : Button    = $CenterContainer/LevelSelectButton
@onready var _options_btn      : Button    = $CenterContainer/OptionsButton
@onready var _quit_btn         : Button    = $CenterContainer/QuitButton
@onready var _title_label      : Label     = $CenterContainer/TitleLabel
@onready var _starfield        : Node2D    = $StarField


func _ready() -> void:
	_setup_theme()
	_build_starfield()
	_animate_title()

	_play_btn.pressed.connect(_on_play_pressed)
	_level_select_btn.pressed.connect(_on_level_select_pressed)
	_options_btn.pressed.connect(_on_options_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)

	# Hover sfx placeholder – replace with your AudioStreamPlayer node
	for btn in [_play_btn, _level_select_btn, _options_btn, _quit_btn]:
		btn.mouse_entered.connect(_on_button_hover.bind(btn))


# ── Navigation ────────────────────────────────

func _on_play_pressed() -> void:
	_change_scene(FIRST_LEVEL_SCENE)

func _on_level_select_pressed() -> void:
	_change_scene(LEVEL_SELECT_SCENE)

func _on_options_pressed() -> void:
	_change_scene(OPTIONS_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


# ── Visual polish ─────────────────────────────

func _setup_theme() -> void:
	# Pixel-art button style applied at runtime so no external theme file is required.
	var sb := StyleBoxFlat.new()
	sb.bg_color        = Color(0.10, 0.10, 0.20)
	sb.border_color    = Color(1.00, 0.88, 0.12)
	sb.border_width_left   = 2
	sb.border_width_right  = 2
	sb.border_width_top    = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left     = 0
	sb.corner_radius_top_right    = 0
	sb.corner_radius_bottom_left  = 0
	sb.corner_radius_bottom_right = 0

	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color     = Color(0.20, 0.20, 0.40)
	sb_hover.border_color = Color(1.00, 1.00, 0.50)

	var sb_pressed := sb.duplicate() as StyleBoxFlat
	sb_pressed.bg_color     = Color(0.30, 0.30, 0.10)
	sb_pressed.border_color = Color(0.80, 0.70, 0.10)

	for btn in [_play_btn, _level_select_btn, _options_btn, _quit_btn]:
		btn.add_theme_stylebox_override("normal",  sb)
		btn.add_theme_stylebox_override("hover",   sb_hover)
		btn.add_theme_stylebox_override("pressed", sb_pressed)
		btn.add_theme_color_override("font_color",          Color(0.90, 0.90, 0.90))
		btn.add_theme_color_override("font_hover_color",    Color(1.00, 1.00, 0.50))
		btn.add_theme_color_override("font_pressed_color",  Color(0.80, 0.70, 0.10))

	_quit_btn.add_theme_color_override("font_color", Color(0.85, 0.35, 0.35))


func _animate_title() -> void:
	# Simple blink / scale pulse on the title using a Tween
	var tween := create_tween().set_loops()
	tween.tween_property(_title_label, "scale", Vector2(1.04, 1.04), 0.6)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_title_label, "scale", Vector2(1.00, 1.00), 0.6)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_title_label.pivot_offset = _title_label.size / 2.0


func _build_starfield() -> void:
	var vp := get_viewport().get_visible_rect()
	randomize()
	for i in STAR_COUNT:
		_stars.append({
			"pos":    Vector2(randf() * vp.size.x, randf() * vp.size.y),
			"speed":  randf_range(10.0, 40.0),
			"size":   randi_range(1, 3),
			"bright": randf_range(0.4, 1.0),
		})


func _process(delta: float) -> void:
	var vp_h := get_viewport().get_visible_rect().size.y
	for star in _stars:
		star["pos"].y += star["speed"] * delta
		if star["pos"].y > vp_h:
			star["pos"].y = 0.0
	queue_redraw()   # triggers _draw on this Control via the StarField child


func _draw() -> void:
	# Draw pixel stars directly onto the Control canvas
	for star in _stars:
		var c := Color(star["bright"], star["bright"], star["bright"], 1.0)
		draw_rect(Rect2(star["pos"], Vector2(star["size"], star["size"])), c)


func _on_button_hover(btn: Button) -> void:
	# Pixel-nudge animation on hover
	var tween := create_tween()
	tween.tween_property(btn, "position:x", btn.position.x + 6, 0.05)
	tween.tween_property(btn, "position:x", btn.position.x,     0.05)
