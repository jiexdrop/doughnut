class_name Magnet
extends StaticBody2D

@onready var tile_map: TileMapLayer = $"../TileMapLayer"
@export var tether_range: int = 6

func get_tile() -> Vector2i:
	return tile_map.local_to_map(position)

# Call this from the Player when they walk onto the magnet's tile
func activate(player: CharacterBody2D) -> void:
	var facing_dir = _get_facing_dir()
	var magnet_tile = get_tile()
	var player_tile = tile_map.local_to_map(player.position)
	
	var expected_player_tile = magnet_tile - Vector2i(facing_dir)
	if player_tile != expected_player_tile:
		print("Wrong side — no pull")
		return

	# Find closest box in facing direction (no range cap)
	var boxes = get_tree().get_nodes_in_group("boxes")
	var found_box = null
	var found_dist = INF

	for box in boxes:
		var box_tile = tile_map.local_to_map(box.position)
		var delta = box_tile - magnet_tile
		# Must be on the same axis as facing direction
		if facing_dir.x != 0 and delta.y == 0:
			var dist = delta.x * facing_dir.x  # positive = in front
			if dist > 0 and dist < found_dist:
				found_dist = dist
				found_box = box
		elif facing_dir.y != 0 and delta.x == 0:
			var dist = delta.y * facing_dir.y
			if dist > 0 and dist < found_dist:
				found_dist = dist
				found_box = box

	if found_box == null:
		print("No box found in facing direction")
		return

	# Pull box (found_dist - 1) steps so it lands adjacent to magnet
	var pull_dir = Vector2(-facing_dir.x, -facing_dir.y)
	print("Pulling box ", found_dist - 1, " steps")
	for step in range(found_dist - 1):
		if not found_box.try_push(pull_dir):
			print("Blocked at step ", step)
			break
			
# Convert rotation to the nearest cardinal tile direction.
# Godot's default 0° points DOWN (+Y in 2D), matching your magnet's initial rotation.
func _get_facing_dir() -> Vector2i:
	var angle = rotation  # radians
	# Snap to nearest 90° increment
	var snapped = round(angle / (PI / 2)) * (PI / 2)
	var dir = Vector2.DOWN.rotated(snapped).normalized()
	return Vector2i(round(dir.x), round(dir.y))
