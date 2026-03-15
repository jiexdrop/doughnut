extends Node2D

const GRID_WIDTH := 32
const GRID_HEIGHT := 18

@export var next_level: PackedScene
@onready var tilemap: TileMapLayer = $TileMapLayer
var goal_positions: Array[Vector2i] = []

const GOAL_SOURCE_ID = 0
const GOAL_ATLAS_COORDS = Vector2i(1, 2)
const GOAL_ATLAS_COORDS_2 = Vector2i(1, 3)

const VICTORY_SCREEN = preload("res://scenes/ui/victory_screen.tscn")
const PAUSE_SCREEN = preload("res://scenes/ui/pause_screen.tscn")

func _ready() -> void:
	_connect_signals()
	_locate_goals()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("pause"):
		_open_pause_ui()

func _connect_signals() -> void:
	for box in get_tree().get_nodes_in_group("boxes"):
		if not box.is_connected("on_move", check_win_condition):
			box.on_move.connect(check_win_condition)
			
func _locate_goals() -> void:
	goal_positions.clear()
	for x in GRID_WIDTH:
		for y in GRID_HEIGHT:
			var coords = Vector2i(x, y)
			if tilemap.get_cell_source_id(coords) == GOAL_SOURCE_ID:
				if tilemap.get_cell_atlas_coords(coords) == GOAL_ATLAS_COORDS:
					goal_positions.append(coords)
				elif tilemap.get_cell_atlas_coords(coords) == GOAL_ATLAS_COORDS_2:
					goal_positions.append(coords)

func check_win_condition() -> void:
	var boxes = get_tree().get_nodes_in_group("boxes")
	var boxes_on_goals = 0

	for box in boxes:
		var current_grid_pos = tilemap.local_to_map(box.position)
		if current_grid_pos in goal_positions:
			box.set_on_goal(true)
			boxes_on_goals += 1
		else:
			box.set_on_goal(false)

	if boxes_on_goals >= goal_positions.size() and goal_positions.size() > 0:
		print("Level Complete!")
		_open_victory_ui()

func is_box_at(grid_pos: Vector2i) -> bool:
	var world_pos = tilemap.map_to_local(grid_pos)
	for box in get_tree().get_nodes_in_group("boxes"):
		if tilemap.local_to_map(box.position) == grid_pos:
			box.color()
			return true
	return false

func _open_victory_ui() -> void:
	# Avoid opening twice if already present
	if get_node_or_null("VictoryScreen"):
		return

	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "VictoryScreen"
	add_child(canvas_layer)

	var victory := VICTORY_SCREEN.instantiate()
	canvas_layer.add_child(victory)

	victory.next_level_pressed.connect(_load_next_level)
	victory.main_menu_pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)

func _open_pause_ui():
	# Avoid opening twice if already present
	if get_node_or_null("PauseScreen"):
		return

	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "PauseScreen"
	add_child(canvas_layer)

	var pause := PAUSE_SCREEN.instantiate()
	canvas_layer.add_child(pause)

	pause.continue_pressed.connect(func():
		remove_child(canvas_layer)
		pause.queue_free()
	)
	pause.main_menu_pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)

func _load_next_level() -> void:
	get_tree().change_scene_to_packed(next_level)
