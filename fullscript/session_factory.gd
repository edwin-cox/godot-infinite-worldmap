extends Node

class_name SessionFactory

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

static func create_session() -> MapSession:
	var session:=MapSession.new()
	
	session.world_offset=Vector2()
	session.camera_size=Vector2(64,64)
	
	var ELEVATION_NOISE_CONFIG=NoiseObject.new(0,6,0.011,0.5,3.1)
	var MAIN_ELEVATION_NOISE_CONFIG=NoiseObject.new(0,9,0.001,1,1)
	var MOISTURE_NOISE_CONFIG=NoiseObject.new(1,4,0.5,3,0.4)
	var HEAT_NOISE_CONFIG=NoiseObject.new(2,4,0.5,3,0.4)
	session.noise_generators=[]
	session.noise_generators.resize(4)
	session.noise_generators[session.noise_idx_moisture]=create_noise_generator(MOISTURE_NOISE_CONFIG)
	session.noise_generators[session.noise_idx_heat]=create_noise_generator(HEAT_NOISE_CONFIG)
	session.noise_generators[session.noise_idx_elevation]=create_noise_generator(ELEVATION_NOISE_CONFIG)
	session.noise_generators[session.noise_idx_main_elevation]=create_noise_generator(MAIN_ELEVATION_NOISE_CONFIG)
	
	return session

static func create_noise_generator(config:NoiseObject)->FastNoiseLite:
	var noise:=FastNoiseLite.new()
	
	noise.noise_type=FastNoiseLite.TYPE_SIMPLEX
	noise.seed=config.seed_nr
	noise.fractal_octaves=config.octaves
	noise.frequency=config.period
	noise.fractal_gain=config.persistence
	noise.fractal_lacunarity=config.lacunarity

	return noise
