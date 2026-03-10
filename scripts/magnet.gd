class_name Magnet
extends StaticBody2D

@onready var tile_map: TileMapLayer = $"../TileMapLayer"
@onready var sprite_2d: Sprite2D = $Sprite2D

# Optional: Add different textures for the magnet if you like
const MAGNET_TEXTURE = preload("res://assets/original_box.png") 

signal on_move

# --- PUSH LOGIC (Called by Player) ---
func try_push(dir: Vector2) -> bool:
	var current_tile = tile_map.local_to_map(position)
	var target_tile = current_tile + Vector2i(dir.x, dir.y)
	
	# 1. Check if the target tile is blocked by walls
	var tile_data = tile_map.get_cell_tile_data(target_tile)
	if tile_data and tile_data.get_custom_data("walkable") == false:
		return false
		
	# 2. Check if there is another object (like a box) in the way
	if is_occupied(target_tile):
		return false
	
	# 3. Before moving, identify if a box is behind us to pull it along
	var pull_dir = -dir
	var behind_tile = current_tile + Vector2i(pull_dir.x, pull_dir.y)
	var box_to_pull = get_box_at_tile(behind_tile)
	
	# Store old position for the box to move into
	var old_position = position
	
	# Move the Magnet
	position = tile_map.map_to_local(target_tile)
	
	# If a box was behind us, pull it into our old spot
	if box_to_pull:
		box_to_pull.position = old_position
	
	on_move.emit()
	return true

# --- PULL LOGIC (Called by Player when they walk AWAY from the magnet) ---
func pull_to(new_position: Vector2, dir: Vector2):
	var old_pos = position
	var old_tile = tile_map.local_to_map(old_pos)
	
	# Determine direction of the pull to find boxes behind the magnet
	var behind_tile = old_tile + Vector2i(dir.x, dir.y)
	
	var box_to_pull = get_box_at_tile(behind_tile)
	
	# Move the magnet to the player's old spot
	position = new_position
	
	# If a box was attached/behind, it moves into the magnet's old spot
	if box_to_pull:
		box_to_pull.position = old_pos
		
	on_move.emit()

# --- HELPERS ---

func is_occupied(tile_coords: Vector2i) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = tile_map.map_to_local(tile_coords)
	query.exclude = [self]
	var result = space_state.intersect_point(query)
	return not result.is_empty()

func get_box_at_tile(tile_coords: Vector2i):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = tile_map.map_to_local(tile_coords)
	query.exclude = [self]
	var result = space_state.intersect_point(query)
	
	if result:
		var collider = result[0].collider
		# We check for try_push to ensure it's a Box (or another Magnet!)
		if collider.has_method("try_push") and collider != self:
			return collider
	return null
