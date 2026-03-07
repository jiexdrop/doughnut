extends Node2D

# Grid dimensions in tiles
const GRID_WIDTH := 32
const GRID_HEIGHT := 18
const TILE_SIZE := 8  # pixels per tile

func _ready() -> void:
	_fill_default_tilemap()

func _fill_default_tilemap() -> void:
	# Fills the tilemap area so the grid bounds are visible in the editor.
	# Replace or extend this with your own tile-painting logic.
	var tilemap: TileMapLayer = $TileMapLayer

	# Nothing to paint until a TileSet with actual tiles is assigned.
	# This loop is intentionally left as a stub so it compiles and runs
	# without errors on a fresh project (no source_id exists yet).
	if tilemap.tile_set == null:
		return

	# Example: paint tile (source_id=0, atlas_coords=(0,0)) across the grid.
	# Uncomment and adjust once you have tiles in your TileSet.
	#
	# for x in GRID_WIDTH:
	#     for y in GRID_HEIGHT:
	#         tilemap.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	pass
