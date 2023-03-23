extends Node

class_name MapSession

var world_offset:Vector2
var zoom:float=1
var camera_size:Vector2
var resolutions:Array[float]=[16.0,12.0,8.0,6.0,4.0,2.0,1.0]
var resolution_idx:int=0

var noise_generators:Array[FastNoiseLite]
const noise_idx_main_elevation=0
const noise_idx_elevation=1
const noise_idx_heat=2
const noise_idx_moisture=3
var current_area_info:AreaInfoObject

func get_noise_offset()->Vector2:
	return (world_offset*zoom-camera_size/2)*resolutions[resolution_idx]

func get_camera_zoomed_size()->Vector2:
	return camera_size*resolutions[resolution_idx]
