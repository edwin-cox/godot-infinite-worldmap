@tool
extends ProceduralWorldDatasource

const BConsts=preload("biome_constants.gd")

var cached_map:PackedByteArray
var cached_color_map:PackedByteArray

var detail:=1.0 : set = set_detail

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


var noise_config:Array[NoiseObject]

var noise_generators:Array[FastNoiseLite]
const noise_idx_main_elevation=0
const noise_idx_elevation=1
const noise_idx_heat=2
const noise_idx_moisture=3

### CONSTRUCTORS #################

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

func set_offset(value:Vector2):
	offset=value
	for i in noise_generators.size():
		var noise=noise_generators[i]
		noise.offset=Vector3(offset.x,offset.y,0)

func set_zoom(value:float):
	zoom=value
	for i in noise_generators.size():
		var noise=noise_generators[i]
		noise.frequency=noise_config[i].period/zoom


func set_detail(value:float):
	detail=value
	noise_generators[noise_idx_elevation].fractal_lacunarity=noise_config[noise_idx_elevation].lacunarity*value

func set_seed(value:int):
	seed=value
	for i in noise_generators.size():
		var noise=noise_generators[i]
		noise.seed=value+noise_config[i].seed_offset

### METHODS ########

func get_noise_image(noise_idx:int,w:int,h:int)->PackedByteArray:
	return noise_generators[noise_idx].get_image(w,h,false,false,false).get_data()


func regenerate_map(camera_zoomed_size:Vector2i):
	var elev_buffer:=get_noise_image(noise_idx_elevation,camera_zoomed_size.x,camera_zoomed_size.y)
	var main_elev_buffer:=get_noise_image(noise_idx_main_elevation,camera_zoomed_size.x,camera_zoomed_size.y)
	var heat_buffer:=get_noise_image(noise_idx_heat,camera_zoomed_size.x,camera_zoomed_size.y)
	var moist_buffer:=get_noise_image(noise_idx_moisture,camera_zoomed_size.x,camera_zoomed_size.y)

	var biome_result=get_biome_buffer(camera_zoomed_size,elev_buffer,main_elev_buffer,heat_buffer,moist_buffer)
	cached_color_map=biome_result[0]
	current_area_info=biome_result[1]
	cached_map=biome_result[2]


func get_biome_image(camera_zoomed_size:Vector2i):
	regenerate_map(camera_zoomed_size)
	return cached_color_map


static func get_biome_buffer(camera_size:Vector2,height_buffer:PackedByteArray,main_height_buffer:PackedByteArray,heat_buffer:PackedByteArray,moisture_buffer:PackedByteArray):
	var buffer:=PackedByteArray()
	var color_buffer:=PackedByteArray()
	var middle_pos:=floori(camera_size.y/2.0*camera_size.x+camera_size.x/2.0)
	var current_biome_name:AreaInfoObject=null
	for i in range(height_buffer.size()):
		var main_height := main_height_buffer[i]
		var height := height_buffer[i]
		var elevation:int=( min(height*height+height,255) + 2 * main_height*main_height ) / 3
	#
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
				current_biome_name=AreaInfoObject.new(biome_idx,heat,moisture,height-BConsts.altShallowWater,BConsts.COLOR_TABLE[biome_idx])
			buffer.append(biome_idx)
			color_buffer.append_array(BConsts.COLOR_TABLE[biome_idx])
		else:
			buffer.append(BConsts.cSnow)
			color_buffer.append_array(BConsts.COLOR_TABLE[BConsts.cSnow])
	
	return [color_buffer,current_biome_name,buffer]
