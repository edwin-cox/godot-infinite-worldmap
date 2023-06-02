@tool
extends Node

# This script defines the MapSession class, which is used to manage the world map display and interaction.
# The class provides fields to store the world offset, zoom level, camera size, resolutions, datasource, and current area information.
# The set_zoom() method is used to set the zoom level and update the datasource zoom level accordingly.
# The get_noise_offset() method is used to calculate the noise offset for a given resolution index.
# The get_camera_zoomed_size() method is used to calculate the camera size for a given resolution index.
# The update_noises() method is used to update the datasource offset and zoom level for a given resolution index.

# The world offset used to generate the world map.
var world_offset:Vector2

# The zoom level used to generate the world map.
var zoom:= 10.0 : set = set_zoom, get = get_zoom  

# The size of the camera used to display the world map.
var camera_size:Vector2

# The list of resolutions used to generate the world map.
var resolutions:Array[int]=[1,2,4,8,16]

# The datasource used to generate the world map.
var datasource:ProceduralWorldDatasource

# The current area information being displayed on the world map.
var current_area_info:ProceduralWorldAreaInfo: get = get_current_area_info

# Sets the zoom level and updates the datasource zoom level accordingly.
func set_zoom(value):
	zoom = clamp(value, 0.01, 1000)
	if datasource:
		datasource.zoom=zoom

# Gets the zoom level used to generate the world map.
func get_zoom():
	return zoom

# Calculates the noise offset for a given resolution index.
func get_noise_offset(resolution_idx:int)->Vector2:
	return (world_offset*zoom-camera_size/2)/resolutions[resolution_idx]

# Calculates the camera size for a given resolution index.
func get_camera_zoomed_size(resolution_idx:int)->Vector2:
	return camera_size/resolutions[resolution_idx]

# Updates the datasource offset and zoom level for a given resolution index.
func update_noises(resolution_idx:int):
	datasource.offset=get_noise_offset(resolution_idx)
	datasource.zoom=zoom/resolutions[resolution_idx]

# Gets the current area information being displayed on the world map.
func get_current_area_info():
	if datasource:
		return datasource.current_area_info
	else:
		return null
