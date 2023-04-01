extends Node

class_name MapSession


class NoiseObject:
	var seed_nr:int
	var octaves:int
	var period:float
	var initial_period:float
	var persistence:float
	var lacunarity:float
	
	func _init(seed_nr:int,octaves:int,period:float,persistence:float,lacunarity:float):
		self.seed_nr=seed_nr
		self.octaves=octaves
		self.period=period
		self.initial_period=period
		self.persistence=persistence
		self.lacunarity=lacunarity


var world_offset:Vector2
var zoom:float=10
var camera_size:Vector2
var resolutions:Array[int]=[1,2,4,8,16]

var noise_config:Array[NoiseObject]

var noise_generators:Array[FastNoiseLite]
const noise_idx_main_elevation=0
const noise_idx_elevation=1
const noise_idx_heat=2
const noise_idx_moisture=3
var current_area_info:AreaInfoObject

func get_noise_offset(resolution_idx:int)->Vector2:
	return (world_offset*zoom-camera_size/2)/resolutions[resolution_idx]

func get_camera_zoomed_size(resolution_idx:int)->Vector2:
	return camera_size/resolutions[resolution_idx]

func get_lacunarity_factor()->float:
	if zoom>5:
		return 1.1
	elif zoom>1:
		return 1.0
	elif zoom>0.5:
		return 0.9
	else:
		return 0.8

func update_noises(resolution_idx:int):
	var offset=get_noise_offset(resolution_idx)
	for i in noise_generators.size():
		var noise=noise_generators[i]
		noise.offset=Vector3(offset.x,offset.y,0)
		noise.frequency=noise_config[i].period*resolutions[resolution_idx]/zoom
#		if i==noise_idx_elevation or i==noise_idx_main_elevation:
#			noise.fractal_lacunarity=noise_config[i].lacunarity*2
