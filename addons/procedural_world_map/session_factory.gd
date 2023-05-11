@tool
extends Node

const MapSession=preload("map_session.gd")
const FastNoiseLiteDatasource=preload("fastnoiselite_datasource.gd")


static func create_session() -> MapSession:
	var session:=MapSession.new()
	
	session.world_offset=Vector2(0,0)
	session.camera_size=Vector2(1024,1024)
	
	return session

static func create_Fastnoiselite_datasource(seed:int) -> ProceduralWorldDatasource:
	var datasource:=FastNoiseLiteDatasource.new()
	datasource.noise_config=[]
	datasource.noise_config.resize(4)
	datasource.seed=seed
	
	datasource.noise_config[datasource.noise_idx_elevation]=FastNoiseLiteDatasource.NoiseObject.new(seed,0,6,0.0011,0.5,4.0)
	datasource.noise_config[datasource.noise_idx_main_elevation]=FastNoiseLiteDatasource.NoiseObject.new(seed,0,9,0.0001,1,1)
	datasource.noise_config[datasource.noise_idx_moisture]=FastNoiseLiteDatasource.NoiseObject.new(seed,1,4,0.05,3,0.4)
	datasource.noise_config[datasource.noise_idx_heat]=FastNoiseLiteDatasource.NoiseObject.new(seed,2,4,0.05,3,0.4)
	
	datasource.noise_generators=[]
	datasource.noise_generators.resize(datasource.noise_config.size())
	for i in datasource.noise_config.size():
		datasource.noise_generators[i]=FastNoiseLiteDatasource.create_noise_generator(datasource.noise_config[i])
	
	return datasource
