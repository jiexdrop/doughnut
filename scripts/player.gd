class_name Player
extends CharacterBody2D

@onready var tile_map: TileMapLayer = $"../TileMapLayer" 
var grid_size = 8 # Note: This variable isn't used in logic because TileMap handles the grid size automatically

func _physics_process(_delta):
	var direction = Vector2.ZERO
	
	if Input.is_action_just_pressed("right"): direction.x = 1
	if Input.is_action_just_pressed("left"):  direction.x = -1
	if Input.is_action_just_pressed("down"):  direction.y = 1
	if Input.is_action_just_pressed("up"):    direction.y = -1

	if direction != Vector2.ZERO:
		move_on_grid(direction)

func move_on_grid(dir):
	# 1. Save where we are starting (This will be the magnet's target)
	var old_tile = tile_map.local_to_map(position)
	var old_position = position
	
	# 2. Calculate where we want to go
	var target_tile = old_tile + Vector2i(dir.x, dir.y)
	var target_position = tile_map.map_to_local(target_tile)
	
	# 3. Collision Check (Same as your original code)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = target_position
	query.exclude = [self] 
	var collision = space_state.intersect_point(query)

	var moved_successfully = false

	if collision:
		var collider = collision[0].collider
		if collider.has_method("try_push"):
			if collider.try_push(dir):
				position = target_position
				moved_successfully = true
	else:
		var tile_data = tile_map.get_cell_tile_data(target_tile)
		if tile_data and tile_data.get_custom_data("walkable") == false:
			return # Blocked by wall
			
		position = target_position
		moved_successfully = true

	if moved_successfully:
		# Check the tile BEHIND our old spot (where a magnet would be trailing us)
		var magnet_tile = old_tile - Vector2i(dir.x, dir.y) 
		var magnet_behind = get_magnet_at(magnet_tile)
		
		if magnet_behind:
			magnet_behind.pull_to(old_position, dir)

func get_magnet_at(tile_coords: Vector2i):
	if not is_inside_tree():
		return null
		
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# Use a small circle to detect the magnet collision box
	var circle = CircleShape2D.new()
	circle.radius = 2.0
	query.shape = circle
	
	# Position the query in the center of the tile
	var target_pos = tile_map.map_to_local(tile_coords)
	query.transform = Transform2D(0, target_pos)
	
	query.exclude = [self]
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var collider = result.collider
		# This checks if the object is our 'Magnet' class
		if collider is Magnet:
			return collider
			
	return null
