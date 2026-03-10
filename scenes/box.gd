extends StaticBody2D

# Reference the TileMap just like in your player script
@onready var tile_map: TileMapLayer = $"../TileMapLayer" 
@onready var sprite_2d: Sprite2D = $Sprite2D

const NORMAL_TEXTURE = preload("res://assets/original_box.png") 
const GOAL_TEXTURE = preload("res://assets/active_box.png")

signal on_move

# This function is called by the player when they try to push
func try_push(dir: Vector2) -> bool:
	var current_tile = tile_map.local_to_map(position)
	var target_tile = current_tile + Vector2i(dir.x, dir.y)
	
	# 1. Check if the target tile is blocked by the TileMap (walls)
	var tile_data = tile_map.get_cell_tile_data(target_tile)
	if tile_data and tile_data.get_custom_data("walkable") == false:
		return false # Blocked by a wall tile
		
	# 2. Check if there is another object (like another box) in the way
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	
	# Check the center of the target tile
	query.position = tile_map.map_to_local(target_tile)
	# Make sure we don't detect the box itself
	query.exclude = [self]
	
	var collision = space_state.intersect_point(query)
	
	if not collision.is_empty():
		# There is something else here (another box or obstacle)
		# Optional: If that object is also a box, you could try pushing it recursively here.
		# For now, we simply block movement.
		return false
	
	# 3. If we get here, the path is clear. Move the box.
	position = tile_map.map_to_local(target_tile)
	on_move.emit()
	return true
	
func set_on_goal(is_on_goal: bool) -> void:
	if is_on_goal:
		# Greenish color to indicate success
		sprite_2d.texture = GOAL_TEXTURE
	else:
		# Reset to white (original texture colors)
		sprite_2d.texture = NORMAL_TEXTURE
	
	print("Box color updated. On goal: ", is_on_goal)
