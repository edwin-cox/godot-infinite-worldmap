#pragma once
#include <map>
#include <array>
#include <string>

enum class Altitude : uint8_t
{
  DeepWater = 115,
  ShallowWater = 123,
  Sand = 127,
  Grass = 160,
  Forest = 192,
  Rock = 225,
  Snow = 255
};

enum class BiomeType : uint8_t
{
  DeepWater = 0,
  ShallowWater = 1,
  Sand = 2,
  Desert = 3,
  Grass = 4,
  Savanna = 5,
  Forest = 6,
  SeasonalForest = 7,
  BorealForest = 8,
  Rainforest = 9,
  Rock = 10,
  Tundra = 11,
  Snow = 12
};

enum class Temperature : uint8_t
{
  Coldest = 12,
  Colder = 46,
  Cold = 102,
  Warm = 127,
  Warmer = 178
};

enum class Humidity : uint8_t
{
  Dryest = 69,
  Dryer = 102,
  Dry = 153,
  Wet = 204,
  Wetter = 230,
  Wettest = 255
};

const std::map<BiomeType, std::array<uint8_t, 3>> COLOR_TABLE = {
    {BiomeType::DeepWater, {0, 0, 128}},
    {BiomeType::ShallowWater, {25, 25, 150}},
    {BiomeType::Sand, {240, 240, 64}},
    {BiomeType::Desert, {238, 218, 130}},
    {BiomeType::Grass, {50, 220, 20}},
    {BiomeType::Savanna, {177, 209, 110}},
    {BiomeType::Forest, {16, 160, 0}},
    {BiomeType::SeasonalForest, {73, 100, 35}},
    {BiomeType::BorealForest, {95, 115, 62}},
    {BiomeType::Rainforest, {29, 73, 40}},
    {BiomeType::Rock, {128, 128, 128}},
    {BiomeType::Tundra, {96, 131, 112}},
    {BiomeType::Snow, {255, 255, 255}}};

const std::map<BiomeType, std::string> BIOME_NAME_TABLE = {
    {BiomeType::DeepWater, "Deep Water"},
    {BiomeType::ShallowWater, "Shallow Water"},
    {BiomeType::Sand, "Sand"},
    {BiomeType::Desert, "Desert"},
    {BiomeType::Grass, "Grass"},
    {BiomeType::Savanna, "Savanna"},
    {BiomeType::Forest, "Forest"},
    {BiomeType::SeasonalForest, "Seasonal Forest"},
    {BiomeType::BorealForest, "Boreal Forest"},
    {BiomeType::Rainforest, "Rainforest"},
    {BiomeType::Rock, "Rock"},
    {BiomeType::Tundra, "Tundra"},
    {BiomeType::Snow, "Ice"}};
