#include "worldmap.h"
#include <godot_cpp/core/class_db.hpp>
#include <future>
#include <chrono>

using namespace godot;

using byte = unsigned char;

Worldmap::Worldmap()
{
  // Initialize any variables here.
}

Worldmap::~Worldmap()
{
  // Add your cleanup here.
}

PackedByteArray Worldmap::get_noise_image(int i, int w, int h)
{
  Ref<FastNoiseLite> noise = noises[i];
  if (noise == NULL)
    return PackedByteArray();

  return noise->get_image(w, h, false, false, false)
      ->get_data();
}

void Worldmap::regenerate_map(Vector2i p_camera_size)
{
  std::map<byte, PackedByteArray> data = generate_noise_buffers(p_camera_size);

  _lastMiddleIndex = get_buffer_middle_index(p_camera_size);
  for (const auto &e : data)
  {
    _lastMiddleBufferValues[e.first] = e.second[_lastMiddleIndex];
  }

  get_biome_buffer(p_camera_size, data);
}

Ref<ImageTexture> Worldmap::create_texture_from_buffer(PackedByteArray buffer, Vector2i size)
{
  Ref<Image> img = Image::create_from_data(size.x, size.y, false, Image::Format::FORMAT_RGB8, buffer);
  return ImageTexture::create_from_image(img);
}

Ref<ImageTexture> Worldmap::get_biome_image(Vector2i p_camera_size)
{
  regenerate_map(p_camera_size);

  return create_texture_from_buffer(cachedColorMap, p_camera_size);
}

void Worldmap::set_noise(int index, Ref<FastNoiseLite> p_noise)
{
  noises[index] = p_noise;
}

std::map<byte, PackedByteArray> Worldmap::generate_noise_buffers(Vector2i p_camera_size)
{
  std::map<byte, PackedByteArray> buffers;
  std::vector<std::future<void>> futures;
  std::mutex mtx;

  for (int i = 0; i < noises.size(); i++)
  {
    futures.push_back(std::async(std::launch::async, [this, &buffers, &mtx, i, p_camera_size]()
                                 {
      PackedByteArray noiseData = get_noise_image(i, p_camera_size.x, p_camera_size.y);
      std::lock_guard<std::mutex> lock(mtx);
      buffers.insert(std::pair<byte, PackedByteArray>(i, noiseData)); }));
  }

  for (auto &e : futures)
  {
    e.get();
  }

  return buffers;
}

int Worldmap::get_buffer_middle_index(Vector2i cameraZoomedSize)
{
  return (int)(cameraZoomedSize.y / 2.0 * cameraZoomedSize.x + cameraZoomedSize.x / 2.0);
}

byte Worldmap::get_current_biome()
{
  return cachedMap[_lastMiddleIndex];
};

byte Worldmap::get_current_heat()
{
  return _lastMiddleBufferValues[static_cast<byte>(NoiseIndex::Heat)];
};
byte Worldmap::get_current_moisture()
{
  return _lastMiddleBufferValues[static_cast<byte>(NoiseIndex::Moisture)];
};
byte Worldmap::get_current_elevation()
{
  return (byte)calc_elevation(_lastMiddleBufferValues[static_cast<byte>(NoiseIndex::TerrainElevation)], _lastMiddleBufferValues[static_cast<byte>(NoiseIndex::ContinentElevation)], _lastMiddleBufferValues[static_cast<byte>(NoiseIndex::LandmassElevation)]);
};

void Worldmap::get_biome_buffer(Vector2i p_camera_size, std::map<byte, PackedByteArray> &p_buffers)
{
  int size = p_camera_size.x * p_camera_size.y;

  PackedByteArray biome_buffer = PackedByteArray();
  biome_buffer.resize(size);

  PackedByteArray color_buffer = PackedByteArray();
  color_buffer.resize(size * 3);

  PackedByteArray input = p_buffers[0];
  for (int i = 0; i < input.size(); i++)
  {
    byte biome = calculate_single_biome(i, p_buffers);
    biome_buffer[i] = biome;
    std::array<uint8_t, 3> color = COLOR_TABLE.at(static_cast<BiomeType>(biome));
    color_buffer[i * 3] = color[0];
    color_buffer[i * 3 + 1] = color[1];
    color_buffer[i * 3 + 2] = color[2];
  }

  cachedMap = biome_buffer;
  cachedColorMap = color_buffer;
}

int Worldmap::calc_elevation(byte terrainHeight, byte continentHeight, byte landmassHeight)
{
  int elevation = static_cast<int>((6 * 0.85 * continentHeight + 3 * 1.8 * landmassHeight + terrainHeight) / 10);
  if (elevation >= static_cast<int>(Altitude::ShallowWater))
  {
    elevation = (3 * continentHeight + terrainHeight * terrainHeight / 140) / 4 - 5;
  }

  return elevation;
}

byte Worldmap::calculate_single_biome(int i, std::map<byte, PackedByteArray> &p_buffers)
{
  byte continentHeight = p_buffers[static_cast<byte>(NoiseIndex::ContinentElevation)][i];
  byte terrainHeight = p_buffers[static_cast<byte>(NoiseIndex::TerrainElevation)][i];
  byte heat = p_buffers[static_cast<byte>(NoiseIndex::Heat)][i];
  byte moist = p_buffers[static_cast<byte>(NoiseIndex::Moisture)][i];
  byte landmassHeight = p_buffers[static_cast<byte>(NoiseIndex::LandmassElevation)][i];

  int elevation = calc_elevation(terrainHeight, continentHeight, landmassHeight);

  if (elevation < static_cast<int>(Altitude::Sand))
  {
    return calc_ocean_biome(elevation, heat, moist);
  }
  else if (elevation < static_cast<int>(Altitude::Forest))
  {
    return calc_land_biome(heat, moist);
  }
  else if (elevation < static_cast<int>(Altitude::Rock))
  {
    return static_cast<byte>(BiomeType::Rock);
  }
  else
  {
    return static_cast<byte>(BiomeType::Snow);
  }
}

byte Worldmap::calc_land_biome(byte heat, byte moist)
{
  if (heat < static_cast<byte>(Temperature::Coldest))
    return static_cast<byte>(BiomeType::Snow);
  else if (heat < static_cast<byte>(Temperature::Colder))
    return static_cast<byte>(BiomeType::Tundra);
  else if (heat < static_cast<byte>(Temperature::Cold))
    return calc_boreal_biome(moist);
  else if (heat < static_cast<byte>(Temperature::Warmer))
    return calc_temperate_biome(moist);
  else
    return calc_tropical_biome(moist);
}

byte Worldmap::calc_tropical_biome(byte moist)
{
  if (moist < static_cast<byte>(Humidity::Dryer))
    return static_cast<byte>(BiomeType::Desert);
  else if (moist < static_cast<byte>(Humidity::Wet))
    return static_cast<byte>(BiomeType::Savanna);
  else
    return static_cast<byte>(BiomeType::Rainforest);
}

byte Worldmap::calc_temperate_biome(byte moist)
{
  if (moist < static_cast<byte>(Humidity::Dryer))
    return static_cast<byte>(BiomeType::Grass);
  else if (moist < static_cast<byte>(Humidity::Wet))
    return static_cast<byte>(BiomeType::Forest);
  else if (moist < static_cast<byte>(Humidity::Wetter))
    return static_cast<byte>(BiomeType::SeasonalForest);
  else
    return static_cast<byte>(BiomeType::Rainforest);
}

byte Worldmap::calc_boreal_biome(byte moist)
{
  if (moist < static_cast<byte>(Humidity::Dryer))
    return static_cast<byte>(BiomeType::Grass);
  else if (moist < static_cast<byte>(Humidity::Dry))
    return static_cast<byte>(BiomeType::Forest);
  else
    return static_cast<byte>(BiomeType::BorealForest);
}

byte Worldmap::calc_ocean_biome(int elevation, byte heat, byte moist)
{
  if (elevation < static_cast<int>(Altitude::DeepWater))
    return static_cast<byte>(BiomeType::DeepWater);
  else if (elevation < static_cast<int>(Altitude::ShallowWater))
    return static_cast<byte>(BiomeType::ShallowWater);
  else
    return calc_shore_biome(heat, moist);
}

byte Worldmap::calc_shore_biome(byte heat, byte moist)
{
  if (heat < static_cast<byte>(Temperature::Colder))
    return static_cast<byte>(BiomeType::Tundra);
  else if (heat < static_cast<byte>(Temperature::Warmer))
    return static_cast<byte>(BiomeType::Grass);
  else if (moist < static_cast<byte>(Humidity::Dryer))
    return static_cast<byte>(BiomeType::Desert);
  else if (moist < static_cast<byte>(Humidity::Wet))
    return static_cast<byte>(BiomeType::Savanna);
  else
    return static_cast<byte>(BiomeType::Grass);
}

int64_t Worldmap::get_noise_benchmark(int w, int h)
{
  auto start = std::chrono::high_resolution_clock::now();
  generate_noise_buffers(Vector2i(w, h));
  auto end = std::chrono::high_resolution_clock::now();
  return std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
}

void Worldmap::_bind_methods()
{
  ClassDB::bind_method(D_METHOD("get_biome_image", "camera_size"), &Worldmap::get_biome_image);
  ClassDB::bind_method(D_METHOD("set_noise", "index", "noise"), &Worldmap::set_noise);
  ClassDB::bind_method(D_METHOD("get_current_biome"), &Worldmap::get_current_biome);
  ClassDB::bind_method(D_METHOD("get_current_heat"), &Worldmap::get_current_heat);
  ClassDB::bind_method(D_METHOD("get_current_moisture"), &Worldmap::get_current_moisture);
  ClassDB::bind_method(D_METHOD("get_current_elevation"), &Worldmap::get_current_elevation);
  ClassDB::bind_method(D_METHOD("get_noise_benchmark", "w", "h"), &Worldmap::get_noise_benchmark);
}