extends Node

class_name MapGenerator

var session:MapSession


func create_texture_from_buffer(buffer: PackedByteArray, width: int, height: int) -> ImageTexture:
	# Create an image from the buffer with the given size
	var image := Image.create_from_data(width, height, false, Image.FORMAT_RGB8, buffer)
	
	# Create an ImageTexture from the image
	var texture := ImageTexture.create_from_image(image)
	
	# Return the texture
	return texture


func get_noise_image(idx:int,w:int,h:int)->PackedByteArray:
	return session.noise_generators[idx].get_image(w,h,false,false,false).get_data()

func get_noise_texture(idx:int,size:Vector2)->Image:
	return session.noise_generators[idx].get_image(size.x,size.y,false,false,false)


func generate_image(is_cancellable:bool,resolution_idx:int)->ImageTexture:

	var camera_zoomed_size:Vector2=session.get_camera_zoomed_size(resolution_idx)
	
	session.update_noises(resolution_idx)
	
	var elev_buffer:=get_noise_image(session.noise_idx_elevation,camera_zoomed_size.x,camera_zoomed_size.y)
	var main_elev_buffer:=get_noise_image(session.noise_idx_main_elevation,camera_zoomed_size.x,camera_zoomed_size.y)
	var heat_buffer:=get_noise_image(session.noise_idx_heat,camera_zoomed_size.x,camera_zoomed_size.y)
	var moist_buffer:=get_noise_image(session.noise_idx_moisture,camera_zoomed_size.x,camera_zoomed_size.y)

	var biome_result=BiomeGenerator.get_biome_buffer(camera_zoomed_size,elev_buffer,main_elev_buffer,heat_buffer,moist_buffer)
	var buffer:PackedByteArray=biome_result[0]
	session.current_area_info=biome_result[1]

	var out:=create_texture_from_buffer(buffer,camera_zoomed_size.x, camera_zoomed_size.y)
#	var out:=ImageTexture.create_from_image(get_noise_texture(session.noise_idx_main_elevation,camera_zoomed_size))
	
	
	return out

