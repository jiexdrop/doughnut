extends Camera2D

## Pixel-perfect camera for pixel art games.
##
## Strategy:
##   - The viewport is fixed at the native pixel resolution (256x144 for 32x18 tiles @ 8px).
##   - Godot's stretch mode="viewport" + aspect="keep" handles upscaling the entire
##     viewport to fill the OS window — no per-sprite scaling needed.
##   - This script additionally snaps the camera position to whole pixels so sprites
##     never land on sub-pixel coordinates (eliminates shimmer during movement).
##
## To move the camera, set `target_position` from any other script, or simply
## reparent it under your player node and set `position = Vector2.ZERO`.

## Native resolution — must match project.godot display/window/size values.
const NATIVE_WIDTH  := 256
const NATIVE_HEIGHT := 144

## Optional: lock camera to integer zoom multiples so manual zoom stays crisp.
## Set to false if you want free zoom (e.g. for a map overview).
@export var integer_zoom_only := true

## The zoom level expressed as a plain integer multiplier (1 = native, 2 = 2×, …).
@export var zoom_level: int = 1 :
	set(value):
		zoom_level = clampi(value, 1, 8)
		_apply_zoom()

func _ready() -> void:
	_apply_zoom()

func _process(_delta: float) -> void:
	# Snap camera position to whole pixels to prevent sub-pixel jitter.
	position = position.round()

## Call this from your game logic to zoom in/out by one step.
func zoom_in()  -> void: zoom_level += 1
func zoom_out() -> void: zoom_level -= 1

func _apply_zoom() -> void:
	if integer_zoom_only:
		zoom = Vector2(zoom_level, zoom_level)
	# When stretch mode="viewport" is active the engine scales the whole
	# framebuffer, so Camera2D.zoom just controls *which portion* of the
	# world is visible — perfect for zooming into a region of the map.
