extends ProceduralWorldDatasource

const NoiseClass=preload("res://addons/procedural_world_map/src/FastnoiseliteDatasource.cs")
const BConsts=preload("biome_constants.gd")

var datasource

var area_info_cache=[]
var noise_config:Array[NoiseObject]
var noise_generators:Array[FastNoiseLite]

var detail:=1.0 : set = set_detail

# Define constants to store the indices of the noise generators.
const noise_idx_main_elevation=0
const noise_idx_elevation=1
const noise_idx_heat=2
const noise_idx_moisture=3

# Define a class to store the noise configuration.
class NoiseObject:
	var seed_nr:int
	var seed_offset:int
	var octaves:int
	var period:float
	var initial_period:float
	var persistence:float
	var lacunarity:float
	
	func _init(seed_nr:int,seed_offset:int,octaves:int,period:float,persistence:float,lacunarity:float):
		self.seed_nr=seed_nr
		self.seed_offset=seed_offset
		self.octaves=octaves
		self.period=period
		self.initial_period=period
		self.persistence=persistence
		self.lacunarity=lacunarity

### CONSTRUCTORS #################
func _init():
	datasource=NoiseClass.new()

# Define a static method to create a new noise generator based on the given configuration.
static func create_noise_generator(config:NoiseObject)->FastNoiseLite:
	var noise:=FastNoiseLite.new()
	
	noise.noise_type=FastNoiseLite.TYPE_SIMPLEX
	noise.seed=config.seed_nr+config.seed_offset
	noise.fractal_octaves=config.octaves
	noise.frequency=config.period
	noise.fractal_gain=config.persistence
	noise.fractal_lacunarity=config.lacunarity

	return noise

func init_noises():
	for i in range(4):
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
		noise.frequency=noise_config[i].period/zoom

# Define a method to set the detail level and update the noise generator for elevation.
func set_detail(value:float):
	detail=value
	noise_generators[noise_idx_elevation].fractal_lacunarity=noise_config[noise_idx_elevation].lacunarity*value

# Define a method to set the seed and update the noise generators.
func set_seed(value:int):
	seed=value
	for i in noise_generators.size():
		var noise=noise_generators[i]
		noise.seed=value+noise_config[i].seed_offset


func get_biome_image(size:Vector2i):
	while(area_info_cache.size()>0):
		var ai=area_info_cache.pop_front()
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

	return ProceduralWorldAreaInfo.new(biome_idx,heat,moisture,elevation,color)
