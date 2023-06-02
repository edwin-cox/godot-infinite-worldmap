extends ProceduralWorldDatasource

# Example of implementation of a custom procedure datasource for a checkerboard world.
# It makes an infinite procedural checkerboard with black and white squares

const SQUARE_SIZE=256.0

func get_biome_image(size:Vector2i):
	var bytes := PackedByteArray()
	
	for y in range(size.y):
		for x in range(size.x):
			var px=(x+offset.x)/zoom
			var py=(y+offset.y)/zoom
			if (floori(px / SQUARE_SIZE) + floori(py / SQUARE_SIZE)) % 2 == 0:
				bytes.append_array([255,255,255])
			else:
				bytes.append_array([0,0,0])

	return create_texture_from_buffer(bytes, size)
