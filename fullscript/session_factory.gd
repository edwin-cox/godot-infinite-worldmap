extends Node

class_name SessionFactory



static func create_session() -> MapSession:
	var session:=MapSession.new()
	
	session.world_offset=Vector2(0,0)
	session.camera_size=Vector2(1024,1024)
	
	session.noise_config=[]
	session.noise_config.resize(4)
	
	session.noise_config[session.noise_idx_elevation]=MapSession.NoiseObject.new(0,6,0.0011,0.5,3.1)
	session.noise_config[session.noise_idx_main_elevation]=MapSession.NoiseObject.new(0,9,0.0001,1,1)
	session.noise_config[session.noise_idx_moisture]=MapSession.NoiseObject.new(1,4,0.05,3,0.4)
	session.noise_config[session.noise_idx_heat]=MapSession.NoiseObject.new(2,4,0.05,3,0.4)
	
	session.noise_generators=[]
	session.noise_generators.resize(session.noise_config.size())
	for i in session.noise_config.size():
		session.noise_generators[i]=create_noise_generator(session.noise_config[i])
	
	return session

static func create_noise_generator(config:MapSession.NoiseObject)->FastNoiseLite:
	var noise:=FastNoiseLite.new()
	
	noise.noise_type=FastNoiseLite.TYPE_SIMPLEX
	noise.seed=config.seed_nr
	noise.fractal_octaves=config.octaves
	noise.frequency=config.period
	noise.fractal_gain=config.persistence
	noise.fractal_lacunarity=config.lacunarity

	return noise
