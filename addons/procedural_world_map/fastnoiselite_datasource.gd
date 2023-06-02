@tool
extends ProceduralWorldDatasource

# This script defines the FastNoiseLiteDatasource class, which is used to generate the world map data using the FastNoiseLite library.
# The class extends the ProceduralWorldDatasource class and provides fields to store the noise configuration, generators, and cached map data.
# The class provides methods to create a new noise generator, update the noise offset and zoom level, and generate the world map data.
# The class also provides a custom color map and an area info cache to store information about each area on the world map.

# Import the constants for the biomes.
const BConsts=preload("biome_constants.gd")

# Define variables to store the custom color map, cached map data, cached color map, and area info cache.
var custom_color_map=null
var cached_map:PackedByteArray
var cached_color_map:PackedByteArray
var area_info_cache=[]

var detail:=1.0 : set = set_detail

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

# Define variables to store the noise configuration and generators.
var noise_config:Array[NoiseObject]
var noise_generators:Array[FastNoiseLite]

# Define constants to store the indices of the noise generators.
const noise_idx_main_elevation=0
const noise_idx_elevation=1
const noise_idx_heat=2
const noise_idx_moisture=3

### CONSTRUCTORS #################

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

### METHODS ########
# Define a method to get the noise image for a given noise generator, width, and height.
func get_noise_image(noise_idx:int,w:int,h:int)->PackedByteArray:
	return noise_generators[noise_idx].get_image(w,h,false,false,false).get_data()

# Define a method to regenerate the world map data based on the current noise configuration and generators.
func regenerate_map(camera_zoomed_size:Vector2i):
	var elev_buffer:=get_noise_image(noise_idx_elevation,camera_zoomed_size.x,camera_zoomed_size.y)
	var main_elev_buffer:=get_noise_image(noise_idx_main_elevation,camera_zoomed_size.x,camera_zoomed_size.y)
	var heat_buffer:=get_noise_image(noise_idx_heat,camera_zoomed_size.x,camera_zoomed_size.y)
	var moist_buffer:=get_noise_image(noise_idx_moisture,camera_zoomed_size.x,camera_zoomed_size.y)

	# Clear the area info cache.
	while(area_info_cache.size()>0):
		var ai=area_info_cache.pop_front()
		ai.queue_free()

	# Get the biome buffer and store the color map, area info, and map data in the appropriate variables.
	var biome_result=get_biome_buffer(camera_zoomed_size,elev_buffer,main_elev_buffer,heat_buffer,moist_buffer)
	cached_color_map=biome_result[0]
	current_area_info=biome_result[1]
	area_info_cache.append(biome_result[1])
	cached_map=biome_result[2]

# Define a method to get the world map image based on the current noise configuration and generators.
func get_biome_image(camera_zoomed_size:Vector2i):
	regenerate_map(camera_zoomed_size)
	return create_texture_from_buffer(cached_color_map, camera_zoomed_size)

# Define a method to get the biome buffer based on the current noise configuration and generators.
func get_biome_buffer(camera_size:Vector2,height_buffer:PackedByteArray,main_height_buffer:PackedByteArray,heat_buffer:PackedByteArray,moisture_buffer:PackedByteArray):
	var active_color_map=BConsts.COLOR_TABLE
	if self.custom_color_map!=null:
		active_color_map=self.custom_color_map
	
	var buffer:=PackedByteArray()
	var color_buffer:=PackedByteArray()
	var middle_pos:=floori(camera_size.y/2.0*camera_size.x+camera_size.x/2.0)
	var current_biome_info:ProceduralWorldAreaInfo=null
	for i in range(height_buffer.size()):
		var main_height := main_height_buffer[i]
		var height := height_buffer[i]
		var elevation:int=( min(height*height+height,255) + 2 * main_height*main_height ) / 3
		var heat:=heat_buffer[i]
		var moisture:=moisture_buffer[i]

		var biome_idx
		if(height<BConsts.altSand):
			if(height<BConsts.altDeepWater):
				biome_idx= BConsts.cDeepWater;
			elif(height<BConsts.altShallowWater):
				biome_idx= BConsts.cShallowWater;
			else:
				if heat<BConsts.COLDER:
					biome_idx= BConsts.cTundra
				elif heat<BConsts.WARMER:
					biome_idx= BConsts.cGrass;
				else:
					if(moisture<BConsts.DRYER):
						biome_idx= BConsts.cDesert;
					elif(moisture<BConsts.WET):
						biome_idx= BConsts.cSavanna;
					else:
						biome_idx= BConsts.cGrass
		elif(height<BConsts.altForest):
			if (heat<BConsts.COLDEST):
				biome_idx= BConsts.cSnow;
			elif(heat<BConsts.COLDER):
				biome_idx= BConsts.cTundra;
			elif(heat<BConsts.COLD):
				if(moisture<BConsts.DRYER):
					biome_idx= BConsts.cGrass
				elif moisture<BConsts.DRY:
					biome_idx= BConsts.cForest;
				else:
					biome_idx= BConsts.cBorealForest;
			elif(heat<BConsts.WARMER):
				if(moisture<BConsts.DRYER):
					biome_idx= BConsts.cGrass;
				elif(moisture<BConsts.WET):
					biome_idx= BConsts.cForest;
				elif(moisture<BConsts.WETTER):
					biome_idx= BConsts.cSeasonalForest;
				else:
					biome_idx= BConsts.cRainForest;
			else:
				if(moisture<BConsts.DRYER):
					biome_idx= BConsts.cDesert;
				elif(moisture<BConsts.WET):
					biome_idx= BConsts.cSavanna;
				else:
					biome_idx= BConsts.cRainForest;

		elif(height<BConsts.altRock):
			biome_idx= BConsts.cRock;
		else:
			biome_idx= BConsts.cSnow;

		if BConsts.COLOR_TABLE.has(biome_idx):
			if i==middle_pos:
				current_biome_info=ProceduralWorldAreaInfo.new(biome_idx,heat,moisture,height-BConsts.altShallowWater,BConsts.COLOR_TABLE[biome_idx])
			buffer.append(biome_idx)
			color_buffer.append_array(active_color_map[biome_idx])
		else:
			buffer.append(BConsts.cSnow)
			color_buffer.append_array(active_color_map[BConsts.cSnow])
	
	return [color_buffer,current_biome_info,buffer]
