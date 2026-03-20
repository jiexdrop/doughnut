extends Control

# Stores the current bindings: { action_name: [InputEvent, ...] }
var current_bindings: Dictionary = {}
# Tracks which button is currently listening for input
var listening_button: Button = null
var listening_action: String = ""

const SAVE_PATH := "user://input_bindings.cfg"

# Only these actions will appear in the options menu
const ALLOWED_ACTIONS := [
	"left", "right", "up", "down",
	"restart", "pause", "activate",
]

@onready var content_vbox: VBoxContainer = %ContentVBox
@onready var back_button: Button = %BackButton

# Overlay panel shown when listening for input
var overlay: Panel
var overlay_label: Label


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_build_overlay()
	_load_bindings()
	_populate_ui()


# ── Overlay (waiting for key press) ──────────────────────────────────────────

func _build_overlay() -> void:
	overlay = Panel.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	# Semi-transparent dark background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.72)
	overlay.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	overlay_label = Label.new()
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.add_theme_font_size_override("font_size", 20)
	overlay_label.add_theme_color_override("font_color", Color(1, 0.878, 0.125))
	vbox.add_child(overlay_label)

	var hint := Label.new()
	hint.text = "Press Escape to cancel"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(hint)

	overlay.add_child(vbox)
	add_child(overlay)


# ── Load / Save ───────────────────────────────────────────────────────────────

func _load_bindings() -> void:
	# Only load the actions we care about
	for action in ALLOWED_ACTIONS:
		if not InputMap.has_action(action):
			push_warning("InputMap: action '%s' not found in project settings." % action)
			continue
		current_bindings[action] = InputMap.action_get_events(action).duplicate()

	# Then overlay any saved user customisations
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return

	for action in cfg.get_sections():
		if action not in ALLOWED_ACTIONS:
			continue
		if not InputMap.has_action(action):
			continue
		var events: Array[InputEvent] = []
		for i in cfg.get_section_keys(action).size():
			var raw = cfg.get_value(action, str(i), null)
			if raw is InputEvent:
				events.append(raw)
		if not events.is_empty():
			current_bindings[action] = events
			InputMap.action_erase_events(action)
			for ev in events:
				InputMap.action_add_event(action, ev)


func _save_bindings() -> void:
	var cfg := ConfigFile.new()
	for action in current_bindings:
		var events: Array = current_bindings[action]
		for i in events.size():
			cfg.set_value(action, str(i), events[i])
	cfg.save(SAVE_PATH)


func _reset_to_defaults() -> void:
	InputMap.load_from_project_settings()
	for action in ALLOWED_ACTIONS:
		if not InputMap.has_action(action):
			continue
		current_bindings[action] = InputMap.action_get_events(action).duplicate()
	# Remove saved file so defaults persist
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_refresh_ui()


# ── UI Construction ───────────────────────────────────────────────────────────

func _populate_ui() -> void:
	# Clear old content
	for child in content_vbox.get_children():
		child.queue_free()

	# Section header
	var header := _make_section_header("KEY BINDINGS")
	content_vbox.add_child(header)

	# One row per action
	for action in current_bindings:
		var row := _make_action_row(action)
		content_vbox.add_child(row)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	content_vbox.add_child(spacer)

	# Reset button
	var reset_btn := Button.new()
	reset_btn.text = "RESET TO DEFAULTS"
	reset_btn.add_theme_font_size_override("font_size", 14)
	reset_btn.custom_minimum_size = Vector2(220, 36)
	reset_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reset_btn.pressed.connect(_reset_to_defaults)
	content_vbox.add_child(reset_btn)


func _make_section_header(title: String) -> Control:
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1, 0.878, 0.125))
	lbl.custom_minimum_size = Vector2(0, 32)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl


func _make_action_row(action: String) -> Control:
	# MarginContainer adds side padding so content never touches screen edges
	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 16)
	outer.add_theme_constant_override("margin_right", 16)
	outer.add_theme_constant_override("margin_top", 0)
	outer.add_theme_constant_override("margin_bottom", 0)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# VBox holds the row + a thin separator line
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	outer.add_child(vbox)

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 48)
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)

	var sep := HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.08)
	vbox.add_child(sep)

	# Action name label — takes all leftover space
	var name_lbl := Label.new()
	name_lbl.text = _format_action_name(action)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 1.0))
	row.add_child(name_lbl)

	# Binding button — single slot, fixed width so it never overflows
	var events: Array = current_bindings.get(action, [])
	var first_event: InputEvent = events[0] if events.size() > 0 else null
	var bind_btn := _make_binding_button(action, 0, first_event)
	row.add_child(bind_btn)

	# Clear button — compact, muted red tint to signal "destructive"
	var clear_btn := Button.new()
	clear_btn.text = "✕"
	clear_btn.add_theme_font_size_override("font_size", 13)
	clear_btn.custom_minimum_size = Vector2(34, 34)
	clear_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	clear_btn.tooltip_text = "Clear binding"
	_style_clear_button(clear_btn)
	clear_btn.pressed.connect(_on_clear_pressed.bind(action))
	row.add_child(clear_btn)

	return outer


func _style_binding_button(btn: Button) -> void:
	# Normal: dark navy with gold border — clearly distinct from the background
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.12, 0.26)
	normal.border_color = Color(1, 0.878, 0.125, 0.7)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 10
	normal.content_margin_right = 10

	# Hover: brighten border, lighten fill
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.18, 0.18, 0.36)
	hover.border_color = Color(1, 0.878, 0.125, 1.0)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(4)
	hover.content_margin_left = 10
	hover.content_margin_right = 10

	# Pressed: slight inset feel
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.08, 0.08, 0.18)
	pressed.border_color = Color(1, 0.878, 0.125, 1.0)
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(4)
	pressed.content_margin_left = 10
	pressed.content_margin_right = 10

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_color_override("font_color", Color(1, 0.878, 0.125))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.6))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))


func _style_clear_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.22, 0.07, 0.07)
	normal.border_color = Color(0.8, 0.2, 0.2, 0.6)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.38, 0.1, 0.1)
	hover.border_color = Color(1.0, 0.3, 0.3, 1.0)
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(4)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.7, 0.7))


func _make_binding_button(action: String, index: int, event: InputEvent) -> Button:
	var btn := Button.new()
	# Fixed width so it never pushes off-screen regardless of key name length
	btn.custom_minimum_size = Vector2(160, 36)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn.add_theme_font_size_override("font_size", 13)
	btn.clip_text = true
	btn.text = _event_to_string(event)
	_style_binding_button(btn)
	btn.pressed.connect(_on_binding_pressed.bind(action, index, btn))
	return btn


func _refresh_ui() -> void:
	_populate_ui()


# ── Input Handling ────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if listening_button == null:
		return

	# Cancel on Escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_stop_listening()
		get_viewport().set_input_as_handled()
		return

	# Accept keyboard or mouse button presses (ignore releases and mouse motion)
	var valid := false
	if event is InputEventKey and event.pressed and not event.echo:
		valid = true
	elif event is InputEventMouseButton and event.pressed:
		valid = true
	elif event is InputEventJoypadButton and event.pressed:
		valid = true
	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
		valid = true

	if not valid:
		return

	# Apply the new binding
	var action := listening_action
	var events: Array = current_bindings.get(action, [])

	# Replace or add
	if listening_button.get_meta("binding_index", 0) < events.size():
		events[listening_button.get_meta("binding_index", 0)] = event
	else:
		events.append(event)

	current_bindings[action] = events

	# Sync to InputMap
	InputMap.action_erase_events(action)
	for ev in events:
		InputMap.action_add_event(action, ev)

	_save_bindings()
	_stop_listening()
	_refresh_ui()
	get_viewport().set_input_as_handled()


func _on_binding_pressed(action: String, index: int, btn: Button) -> void:
	listening_action = action
	listening_button = btn
	btn.set_meta("binding_index", index)
	overlay_label.text = "Press a key for:\n\"%s\"" % _format_action_name(action)
	overlay.visible = true
	# Grab focus to intercept input reliably
	overlay.grab_focus()


func _stop_listening() -> void:
	listening_button = null
	listening_action = ""
	overlay.visible = false


func _on_clear_pressed(action: String) -> void:
	current_bindings[action] = []
	InputMap.action_erase_events(action)
	_save_bindings()
	_refresh_ui()


func _on_back_pressed() -> void:
	_save_bindings()
	# Adjust to your scene-switching logic:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


# ── Helpers ───────────────────────────────────────────────────────────────────

func _format_action_name(action: String) -> String:
	# "move_left" → "Move Left"
	return action.replace("_", " ").capitalize()


func _event_to_string(event: InputEvent) -> String:
	if event == null:
		return "[ UNBOUND ]"
	if event is InputEventKey:
		return OS.get_keycode_string(event.get_key_label_with_modifiers())
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:   return "Mouse Left"
			MOUSE_BUTTON_RIGHT:  return "Mouse Right"
			MOUSE_BUTTON_MIDDLE: return "Mouse Middle"
			MOUSE_BUTTON_WHEEL_UP:   return "Scroll Up"
			MOUSE_BUTTON_WHEEL_DOWN: return "Scroll Down"
			_: return "Mouse %d" % event.button_index
	if event is InputEventJoypadButton:
		return "Pad Btn %d" % event.button_index
	if event is InputEventJoypadMotion:
		var dir := "+" if event.axis_value > 0 else "-"
		return "Axis %d%s" % [event.axis, dir]
	return event.as_text()
