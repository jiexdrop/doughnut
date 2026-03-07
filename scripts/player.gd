extends CharacterBody2D

@onready var tile_map: TileMapLayer = $"../TileMapLayer" # Adjust path to your TileMap
var grid_size = 8

func _physics_process(_delta):
	var direction = Vector2.ZERO
	
	if Input.is_action_just_pressed("right"): direction.x = 1
	if Input.is_action_just_pressed("left"):  direction.x = -1
	if Input.is_action_just_pressed("down"):  direction.y = 1
	if Input.is_action_just_pressed("up"):    direction.y = -1

	if direction != Vector2.ZERO:
		move_on_grid(direction)

func move_on_grid(dir):
	# 1. Calculate where we want to go in "Grid terms"
	var current_tile = tile_map.local_to_map(position)
	var target_tile = current_tile + Vector2i(dir.x, dir.y)
	
	# 2. Check if the tile is walkable (Optional: requires Data Layer on TileSet)
	var tile_data = tile_map.get_cell_tile_data(target_tile)
	if tile_data and tile_data.get_custom_data("walkable") == false:
		return # Block movement
		
	# 3. Move to the center of the new tile
	position = tile_map.map_to_local(target_tile)
