@tool
extends Node

class_name ProceduralWorldDatasource

# Abstract class for the datasource used to generate the world map.
# The get_biome_image() method is not implemented and should be overridden in a subclass to generate the biome image for the current area.
# The current_area_info variable is used to store information about the current area being displayed on center of the world map.
# This script is intended to be used as a base class for other datasource classes that implement specific world generation algorithms.


# The seed value used to generate the world map.
@export var seed:int: set=set_seed

# The offset value used to generate the world map.
@export var offset:Vector2: set=set_offset, get=get_offset

# The zoom level used to generate the world map.
@export var zoom:float : set = set_zoom, get = get_zoom

# Information about the current area being displayed on the world map.
@export var current_area_info:ProceduralWorldAreaInfo

# Abstract method to generate the biome image for the current area.
# This method should be overridden in a subclass to generate the biome image.
func get_biome_image(camera_zoomed_size:Vector2i):
	pass

# Sets the seed value used to generate the world map.
func set_seed(value:int):
	seed=value

# Sets the offset value used to generate the world map.
func set_offset(value:Vector2):
	offset=value

# Gets the offset value used to generate the world map.
func get_offset():
	return offset

# Sets the zoom level used to generate the world map.
func set_zoom(value:float):
	zoom=value

# Gets the zoom level used to generate the world map.
func get_zoom():
	return zoom

# Creates an ImageTexture from a PackedByteArray buffer with the given size.
func create_texture_from_buffer(buffer: PackedByteArray, camera_size:Vector2i) -> ImageTexture:
	# Create an image from the buffer with the given size
	var image := Image.create_from_data(camera_size.x, camera_size.y, false, Image.FORMAT_RGB8, buffer)
	
	# Create an ImageTexture from the image
	return ImageTexture.create_from_image(image)
