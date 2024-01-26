using System.Collections.Generic;

namespace ProceduralWorldMap
{
  static class BiomeConstants
  {
    public enum Temperature
    {
      Coldest = 12,
      Colder = 46,
      Cold = 102,
      Warm = 127,
      Warmer = 178
    }

    public enum Humidity
    {
      Dryest = 69,
      Dryer = 102,
      Dry = 153,
      Wet = 204,
      Wetter = 230,
      Wettest = 255
    }

    public enum BiomeType
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
      RainForest = 9,
      Rock = 10,
      Tundra = 11,
      Snow = 12
    }


    public enum Altitude
    {
      DeepWater = 115,
      ShallowWater = 123,
      Sand = 127,
      Grass = 160,
      Forest = 192,
      Rock = 225,
      Snow = 255
    }

    public static readonly Dictionary<BiomeType, byte[]> COLOR_TABLE = new()
    {
      [BiomeType.DeepWater] = new byte[] { 0, 0, 128 },
      [BiomeType.ShallowWater] = new byte[] { 25, 25, 150 },
      [BiomeType.Sand] = new byte[] { 240, 240, 64 },
      [BiomeType.Desert] = new byte[] { 238, 218, 130 },
      [BiomeType.Grass] = new byte[] { 50, 220, 20 },
      [BiomeType.Savanna] = new byte[] { 177, 209, 110 },
      [BiomeType.Forest] = new byte[] { 16, 160, 0 },
      [BiomeType.SeasonalForest] = new byte[] { 73, 100, 35 },
      [BiomeType.BorealForest] = new byte[] { 95, 115, 62 },
      [BiomeType.RainForest] = new byte[] { 29, 73, 40 },
      [BiomeType.Rock] = new byte[] { 128, 128, 128 },
      [BiomeType.Tundra] = new byte[] { 96, 131, 112 },
      [BiomeType.Snow] = new byte[] { 255, 255, 255 }
    };
    public static readonly Dictionary<BiomeType, string> BIOME_NAME_TABLE = new()
    {
      [BiomeType.DeepWater] = "Deep Water",
      [BiomeType.ShallowWater] = "Shallow Water",
      [BiomeType.Sand] = "Sand",
      [BiomeType.Desert] = "Desert",
      [BiomeType.Grass] = "Grass",
      [BiomeType.Savanna] = "Savanna",
      [BiomeType.Forest] = "Forest",
      [BiomeType.SeasonalForest] = "Seasonal Forest",
      [BiomeType.BorealForest] = "Boreal Forest",
      [BiomeType.RainForest] = "Rain Forest",
      [BiomeType.Rock] = "Rock",
      [BiomeType.Tundra] = "Tundra",
      [BiomeType.Snow] = "Ice"
    };

  }
}


