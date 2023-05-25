@tool
extends Node

var world_offset:Vector2
var zoom:= 10.0 : set = set_zoom, get = get_zoom  

var camera_size:Vector2
var resolutions:Array[int]=[1,2,4,8,16]
var datasource:ProceduralWorldDatasource

var current_area_info:ProceduralWorldAreaInfo: get = get_current_area_info

func get_current_area_info():
	if datasource:
		return datasource.current_area_info
	else:
		return null

func set_zoom(value):
	zoom = clamp(value, 0.01, 1000)
	if datasource:
		datasource.zoom=zoom

func get_zoom():
	return zoom

func get_noise_offset(resolution_idx:int)->Vector2:
	return (world_offset*zoom-camera_size/2)/resolutions[resolution_idx]

func get_camera_zoomed_size(resolution_idx:int)->Vector2:
	return camera_size/resolutions[resolution_idx]

func update_noises(resolution_idx:int):
	datasource.offset=get_noise_offset(resolution_idx)
	datasource.zoom=zoom/resolutions[resolution_idx]
