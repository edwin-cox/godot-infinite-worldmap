extends Node

class_name MapGenerator

var session:MapSession
var biome_gen:BiomeGenerator

var current_map_array:Array
var worker_cancel_task:bool

func create_texture_from_buffer(buffer: PackedByteArray, width: int, height: int) -> ImageTexture:
	# Create an image from the buffer with the given size
	var image := Image.create_from_data(width, height, false, Image.FORMAT_RGB8, buffer)
	
	# Create an ImageTexture from the image
	var texture := ImageTexture.create_from_image(image)
	
	# Return the texture
	return texture



func get_biome_color(idx:float)->Array[int]:
	match idx:
		0.0:
			return [0,0,128]
		0.1:
			return [25,25,150]
		0.2:
			return [240,240,64]
		0.25:
			return [238,218,130]
		0.3:
			return [50,220,20]
		0.35:
			return [177,209,110]
		0.4:
			return [16,160, 0]
		0.45:
			return [73,100, 35]
		0.5:
			return [95,115, 62]
		0.55:
			return [29,73, 40]
		0.6:
			return [128,128,128]
		0.65:
			return [96,131,112]
		_:
			return [255,255,255]

func get_biome_color_float(idx:float)->Array[float]:
	match idx:
		0:
			return [0,0,0.5]
		0.1:
			return [25/255.0,25/255.0,150/255.0]
		0.2:
			return [240/255.0,240/255.0,64/255.0]
		0.25:
			return [238/255.0,218/255.0,130/255.0]
		0.3:
			return [50/255.0,220/255.0,20/255.0]
		0.35:
			return [177/255.0,209/255.0,110/255.0]
		0.4:
			return [16/255.0,160/255.0, 0]
		0.45:
			return [73/255.0,100/255.0, 35/255.0]
		0.5:
			return [95/255.0,115/255.0, 62/255.0]
		0.55:
			return [29/255.0,73/255.0, 40/255.0]
		0.6:
			return [0.5,0.5,0.5]
		0.65:
			return [96/255.0,131/255.0,112/255.0]
		_:
			return [1.0,1.0,1.0]

func get_biome_name(idx:float)->String:
	match idx:
		0:
			return "Deep Water"
		0.1:
			return "Shallow Water"
		0.2:
			return "Sand"
		0.25:
			return "Desert"
		0.3:
			return "Grass"
		0.35:
			return "Savanna"
		0.4:
			return "Forest"
		0.45:
			return "Seasonal Forest"
		0.5:
			return "Boreal Forest"
		0.55:
			return "Rain Forest"
		0.6:
			return "Rock"
		0.65:
			return "Tundra"
		_:
			return "Ice"

func get_noise_value(n:FastNoiseLite,x:int,y:int)->float:
	return (1.0+n.get_noise_2d(x, y))/2.0

func get_elevation_image_line(is_cancellable:bool,y:int,noise_y:int,line_size:int,camera_zoomed_size:Vector2):
	var mainElevationTex=session.noise_generators[session.noise_idx_main_elevation]
	var elevationTex=session.noise_generators[session.noise_idx_elevation]
	var heatTex=session.noise_generators[session.noise_idx_heat]
	var moistureTex=session.noise_generators[session.noise_idx_moisture]
	
	var line_data:Array[int]=[]
	
	for x in range(line_size):
		if worker_cancel_task and is_cancellable:
			print("cancelled")
			return
		
		var noise_x=x+session.get_noise_offset().x
		
		var main_height :float= get_noise_value(mainElevationTex,noise_x,noise_y)
		var height :float= get_noise_value(elevationTex,noise_x,noise_y)
		var elevation:float=( min(pow(height,2)+height,1) + 2.0 * main_height*main_height ) / 3.0
		
		var heat:float=get_noise_value(heatTex,noise_x,noise_y)
		var moisture:float=get_noise_value(moistureTex,noise_x,noise_y)
		
		var biome_idx:float=biome_gen.get_biome(elevation,heat,moisture)
		
		var biome_color:Array[int]=get_biome_color(biome_idx)
		
		line_data.append_array(biome_color)
		
		if(x==camera_zoomed_size.x/2 and y==camera_zoomed_size.y/2):
			session.current_area_info=AreaInfoObject.new(biome_idx,heat,moisture,elevation,biome_color)
		
	
	current_map_array[y]=line_data

func generate_image(is_cancellable:bool)->ImageTexture:

	var start_time = Time.get_unix_time_from_system() * 1000

	var camera_zoomed_size:Vector2=session.get_camera_zoomed_size()

	current_map_array=[]
	current_map_array.resize(camera_zoomed_size.y)

	const max_thread_count=6
	
	var threads:Array[Thread]=[]

	for y in range(camera_zoomed_size.y):
		if is_cancellable and worker_cancel_task:
			return
		
		var noise_y=y+session.get_noise_offset().y
		var t=Thread.new()
		threads.append(t)
		t.start(get_elevation_image_line.bind(is_cancellable,y,noise_y,camera_zoomed_size.x,camera_zoomed_size))
#		get_elevation_image_line(is_cancellable,y,noise_y,camera_zoomed_size.x,camera_zoomed_size)
		
		if threads.size()>=max_thread_count:
			for thread in threads:
				thread.wait_to_finish()
			threads=[]
	
	if threads.size()>0:
		for t in threads:
			t.wait_to_finish()
		threads=[]
	
	var end_time = Time.get_unix_time_from_system() * 1000
	var elapsed_time = end_time - start_time
	print("The threads took ", elapsed_time, " milliseconds to execute.")
	start_time=Time.get_unix_time_from_system() * 1000

	var buffer:=PackedByteArray()
	for y in range(camera_zoomed_size.y):
		buffer.append_array(current_map_array[y])
	
	end_time = Time.get_unix_time_from_system() * 1000
	elapsed_time = end_time - start_time
	print("The buffering took ", elapsed_time, " milliseconds to execute.")
	start_time=Time.get_unix_time_from_system() * 1000
	
	var out:=create_texture_from_buffer(buffer,camera_zoomed_size.x, camera_zoomed_size.y)
	
	end_time = Time.get_unix_time_from_system() * 1000
	elapsed_time = end_time - start_time
	print("The texturing took ", elapsed_time, " milliseconds to execute.")
	
	return out

