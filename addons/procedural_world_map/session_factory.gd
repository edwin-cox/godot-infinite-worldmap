@tool
extends Node

# This script defines the SessionFactory class, which is used to create new instances of the MapSession and ProceduralWorldDatasource classes.
# The class provides static methods to create a new MapSession object with default values, and to create a new FastNoiseLiteDatasource object with the given seed value.
# The create_Fastnoiselite_datasource() method initializes the noise configuration and generators for the FastNoiseLiteDatasource object.

const MapSession=preload("map_session.gd")
const FastNoiseLiteDatasource=preload("fastnoiselite_datasource.gd")
const SharpNoiseLiteDatasource=preload("sharpnoiselite_datasource.gd")

# Creates a new MapSession object with default values.
static func create_session() -> MapSession:
	var session:=MapSession.new()
	
	session.world_offset=Vector2(0,0)
	session.camera_size=Vector2(1024,1024)
	
	return session

static func create_simplex_noise_config(seed_nr:int,seed_offset:int,octaves:int,period:float,persistence:float,lacunarity:float)->Dictionary:
	var noise_config:={}
	
	noise_config.noise_type=FastNoiseLite.TYPE_SIMPLEX
	noise_config.seed_nr=seed_nr
	noise_config.seed_offset=seed_offset
	noise_config.fractal_octaves=octaves
	noise_config.frequency=period
	noise_config.fractal_gain=persistence
	noise_config.fractal_lacunarity=lacunarity
	
	return noise_config

static func create_continent_noise(seed_nr:int,seed_offset:int) -> Dictionary:
	var noise_config:={}
	
	noise_config.noise_type=FastNoiseLite.TYPE_CELLULAR
	noise_config.seed_nr=seed_nr
	noise_config.seed_offset=seed_offset
	noise_config.fractal_octaves=3
	noise_config.frequency=0.001
	noise_config.fractal_gain=0.5
	noise_config.fractal_lacunarity=2.0
	noise_config.fractal_type=FastNoiseLite.FRACTAL_NONE
	noise_config.cellular_distance_function=FastNoiseLite.DISTANCE_HYBRID
	noise_config.cellular_jitter=2.0
	noise_config.cellular_return_type=FastNoiseLite.RETURN_CELL_VALUE

	return noise_config

# Define a static method to create a new noise generator based on the given configuration.
static func create_noise_generator(config:Dictionary)->FastNoiseLite:
	var noise:=FastNoiseLite.new()
	
	noise.noise_type=config.noise_type
	noise.seed=config.seed_nr+config.seed_offset
	noise.fractal_octaves=config.fractal_octaves
	noise.frequency=config.frequency
	noise.fractal_gain=config.fractal_gain
	noise.fractal_lacunarity=config.fractal_lacunarity

	return noise


# Creates a new FastNoiseLiteDatasource object with the given seed value.
# Initializes the noise configuration and generators for the FastNoiseLiteDatasource object.
static func create_Fastnoiselite_datasource(seed:int) -> ProceduralWorldDatasource:
	var datasource:=FastNoiseLiteDatasource.new()
	datasource.noise_config=[]
	datasource.noise_config.resize(5)
	datasource.seed=seed
	
	var simplex:=FastNoiseLite.TYPE_SIMPLEX
	datasource.noise_config[datasource.noise_idx_elevation]=create_simplex_noise_config(seed,0,6,0.0011,0.5,4.0)
	datasource.noise_config[datasource.noise_idx_main_elevation]=create_simplex_noise_config(seed,0,9,0.0001,1,1)
	datasource.noise_config[datasource.noise_idx_moisture]=create_simplex_noise_config(seed,1,4,0.05,3,0.4)
	datasource.noise_config[datasource.noise_idx_heat]=create_simplex_noise_config(seed,2,4,0.05,3,0.4)
	datasource.noise_config[datasource.noise_idx_continent]=create_continent_noise(seed,0)
	
	datasource.noise_generators=[]
	datasource.noise_generators.resize(datasource.noise_config.size())
	for i in datasource.noise_config.size():
		datasource.noise_generators[i]=create_noise_generator(datasource.noise_config[i])
	
	return datasource

static func create_Sharpnoiselite_datasource(seed:int) -> ProceduralWorldDatasource:
	var datasource:=SharpNoiseLiteDatasource.new()
	datasource.noise_config=[]
	datasource.noise_config.resize(5)
	datasource.seed=seed
	
	var simplex:=FastNoiseLite.TYPE_SIMPLEX
	datasource.noise_config[datasource.noise_idx_elevation]=create_simplex_noise_config(seed,0,6,0.0011,0.5,4.0)
	datasource.noise_config[datasource.noise_idx_main_elevation]=create_simplex_noise_config(seed,0,9,0.0001,1,1)
	datasource.noise_config[datasource.noise_idx_moisture]=create_simplex_noise_config(seed,1,4,0.05,3,0.4)
	datasource.noise_config[datasource.noise_idx_heat]=create_simplex_noise_config(seed,2,4,0.05,3,0.4)
	datasource.noise_config[datasource.noise_idx_continent]=create_continent_noise(seed,0)
	
	datasource.noise_generators=[]
	datasource.noise_generators.resize(datasource.noise_config.size())
	for i in datasource.noise_config.size():
		datasource.noise_generators[i]=create_noise_generator(datasource.noise_config[i])
	
	datasource.init_noises()
	
	return datasource
