extends ProceduralWorldDatasource

const NoiseClass=preload("res://addons/procedural_world_map/mono/FastnoiseliteDatasource.cs")
const BConsts=preload("../biome_constants.gd")

var datasource

var area_info_cache=[]
var noise_config:Array[Dictionary]
var noise_generators:Array[FastNoiseLite]

var detail:=1.0 : set = set_detail

# Define constants to store the indices of the noise generators.
const noise_idx_continent_elevation=0
const noise_idx_terrain_elevation=1
const noise_idx_heat=2
const noise_idx_moisture=3
const noise_idx_landmass_elevation=4

### CONSTRUCTORS #################
func _init():
	datasource=NoiseClass.new()

func init_noises():
	for i in range(5):
		datasource.SetNoise(i,noise_generators[i])

### GETTERS SETTERS #######

# Define a method to get the name of a biome based on its ID.
func get_biome_name(biome_id):
	return BConsts.BIOME_NAME_TABLE[biome_id]

# Define a method to set the noise offset and update the noise generators.
func set_offset(value:Vector2):
	offset=value
	for i in noise_generators.size():
		var noise=noise_generators[i]
		noise.offset=Vector3(offset.x,offset.y,0)

# Define a method to set the zoom level and update the noise generators.
func set_zoom(value:float):
	zoom=value
	for i in noise_generators.size():
		var noise=noise_generators[i]
		noise.frequency=noise_config[i].frequency/zoom

# Define a method to set the detail level and update the noise generator for elevation.
func set_detail(value:float):
	detail=value
	noise_generators[noise_idx_terrain_elevation].fractal_lacunarity=noise_config[noise_idx_terrain_elevation].fractal_lacunarity*value

# Define a method to set the seed and update the noise generators.
func set_seed(value:int):
	seed=value
	for i in noise_generators.size():
		var noise=noise_generators[i]
		noise.seed=value+noise_config[i].seed_offset


func get_biome_image(size:Vector2i):
	while(area_info_cache.size()>0):
		var ai=area_info_cache.pop_front()
		if is_instance_valid(ai):
			ai.queue_free()
		
	var data = datasource.GetBiomeImage(size)
	current_area_info=fill_area_info_cache()
	area_info_cache.append(current_area_info)
	return data

func fill_area_info_cache():
	var biome_idx=datasource.GetCurrentBiome()
	var heat=datasource.GetCurrentHeat()
	var moisture=datasource.GetCurrentMoisture()
	var elevation=datasource.GetCurrentElevation() 
	var color=BConsts.COLOR_TABLE[BConsts.cSnow]
	if biome_idx!=null:
		color=BConsts.COLOR_TABLE[biome_idx]
	else:
		biome_idx=BConsts.cSnow

	return ProceduralWorldAreaInfo.new(biome_idx,heat,moisture,elevation- BConsts.altShallowWater,color)
