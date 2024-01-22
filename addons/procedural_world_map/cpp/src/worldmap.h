// © Copyright 2014-2022, Juan Linietsky, Ariel Manzur and the Godot community (CC-BY 3.0)
#ifndef WORLDMAP_CLASS_H
#define WORLDMAP_CLASS_H

// We don't need windows.h in this plugin but many others do and it throws up on itself all the time
// So best to include it and make sure CI warns us when we use something Microsoft took for their own goals....
#ifdef WIN32
#include <windows.h>
#endif

#include <map>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/fast_noise_lite.hpp>
#include <biomeConstants.h>

using namespace godot;
using byte = unsigned char;

enum class NoiseIndex : byte
{
  ContinentElevation = 0,
  TerrainElevation = 1,
  Heat = 2,
  Moisture = 3,
  LandmassElevation = 4
};

class Worldmap : public RefCounted
{
  GDCLASS(Worldmap, RefCounted);

private:
  std::array<Ref<FastNoiseLite>, 5> noises;
  PackedByteArray cachedColorMap;
  PackedByteArray cachedMap;

  int _lastMiddleIndex = -1;
  std::map<byte, byte> _lastMiddleBufferValues;

  void regenerate_map(Vector2i p_camera_size);
  Ref<ImageTexture> create_texture_from_buffer(PackedByteArray buffer, Vector2i size);
  PackedByteArray get_noise_image(int i, int w, int h);
  std::map<byte, PackedByteArray> generate_noise_buffers(Vector2i p_camera_size);
  void get_biome_buffer(Vector2i p_camera_size, std::map<byte, PackedByteArray> &p_buffers);
  byte calculate_single_biome(int i, std::map<byte, PackedByteArray> &p_buffers);
  byte calc_land_biome(byte heat, byte moist);
  byte calc_tropical_biome(byte moist);
  byte calc_temperate_biome(byte moist);
  byte calc_boreal_biome(byte moist);
  byte calc_ocean_biome(int elevation, byte heat, byte moist);
  byte calc_shore_biome(byte heat, byte moist);
  byte get_current_biome();
  byte get_current_heat();
  byte get_current_moisture();
  byte get_current_elevation();
  int get_buffer_middle_index(Vector2i cameraZoomedSize);
  int calc_elevation(byte terrainHeight, byte continentHeight, byte landmassHeight);

protected:
  static void _bind_methods();

public:
  Worldmap();
  ~Worldmap();

  Ref<ImageTexture> get_biome_image(Vector2i p_camera_size);

  void set_noise(int index, Ref<FastNoiseLite> p_noise);
  int64_t get_noise_benchmark(int w, int h);
};

#endif // WORLDMAP_CLASS_H
