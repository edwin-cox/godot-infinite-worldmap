@tool
extends Node

class_name ProceduralWorldDatasource

const AreaInfoObject=preload("area_info_object.gd")

@export var seed:int: set=set_seed
@export var offset:Vector2: set=set_offset, get=get_offset
@export var zoom:float : set = set_zoom, get = get_zoom

@export var current_area_info:AreaInfoObject

func get_biome_image(camera_zoomed_size:Vector2i):
	pass

func set_seed(value:int):
	seed=value

func set_offset(value:Vector2):
	offset=value

func get_offset():
	return offset

func set_zoom(value:float):
	zoom=value

func get_zoom():
	return zoom
