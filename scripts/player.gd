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
	# 1. Calculate Target Position
	var current_tile = tile_map.local_to_map(position)
	var target_tile = current_tile + Vector2i(dir.x, dir.y)
	var target_position = tile_map.map_to_local(target_tile)
	
	# 2. Check for a Box (or other physics body) at the target location
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = target_position
	# We exclude the player so we don't detect ourselves
	query.exclude = [self] 
	
	var collision = space_state.intersect_point(query)

	# 3. Logic: Wall vs Box vs Walk
	if collision:
		# We hit something. Let's check if it is a box.
		var collider = collision[0].collider
		
		if collider.has_method("try_push"):
			# It is a pushable box! Try to push it.
			if collider.try_push(dir):
				# Box moved successfully, now player moves into the box's old spot
				position = target_position
		else:
			# We hit a static object that isn't a box (like a wall)
			return
	else:
		# No object detected. Check if the tile itself is walkable.
		var tile_data = tile_map.get_cell_tile_data(target_tile)
		if tile_data and tile_data.get_custom_data("walkable") == false:
			return # Blocked by tilemap wall
			
		# Path is clear, move normally
		position = target_position
