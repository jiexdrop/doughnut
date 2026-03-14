class_name Player
extends CharacterBody2D

@onready var tile_map: TileMapLayer = $"../TileMapLayer"

func _physics_process(_delta):
	var direction = Vector2.ZERO
	if Input.is_action_just_pressed("right"): direction.x = 1
	if Input.is_action_just_pressed("left"):  direction.x = -1
	if Input.is_action_just_pressed("down"):  direction.y = 1
	if Input.is_action_just_pressed("up"):    direction.y = -1
	if direction != Vector2.ZERO:
		move_on_grid(direction)

func move_on_grid(dir: Vector2):
	var target_tile = tile_map.local_to_map(position) + Vector2i(dir)
	var target_pos  = tile_map.map_to_local(target_tile)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = target_pos
	query.exclude  = [self]
	var hits = space_state.intersect_point(query)

	var moved = false
	if hits:
		var collider = hits[0].collider
		if collider.has_method("try_push"):
			if collider.try_push(dir):
				position = target_pos
				moved = true
		# ← NEW: pick up the magnet
		elif collider.has_method("activate"):
			collider.activate(self)
			moved = true
	else:
		var tile_data = tile_map.get_cell_tile_data(target_tile)
		if tile_data and tile_data.get_custom_data("walkable") == false:
			return
		position = target_pos
		moved = true


func _tile_occupied(tile: Vector2i, exclude_box) -> bool:
	var world_pos = tile_map.map_to_local(tile)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.exclude  = [self, exclude_box]
	return not space_state.intersect_point(query).is_empty()
