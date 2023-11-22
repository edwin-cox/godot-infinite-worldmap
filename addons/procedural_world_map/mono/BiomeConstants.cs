using System.Collections.Generic;

namespace ProceduralWorldMap
{
  static class BiomeConstants
  {
    public const int COLDEST = 12;
    public const int COLDER = 46;
    public const int COLD = 102;
    public const int WARM = 127;
    public const int WARMER = 178;

    public const int DRYEST = 69;
    public const int DRYER = 102;
    public const int DRY = 153;
    public const int WET = 204;
    public const int WETTER = 230;
    public const int WETTEST = 255;

    public const int cDeepWater = 0;
    public const int cShallowWater = 1;
    public const int cSand = 2;
    public const int cDesert = 3;
    public const int cGrass = 4;
    public const int cSavanna = 5;
    public const int cForest = 6;
    public const int cSeasonalForest = 7;
    public const int cBorealForest = 8;
    public const int cRainForest = 9;
    public const int cRock = 10;
    public const int cTundra = 11;
    public const int cSnow = 12;


    public const int altDeepWater = 115;
    public const int altShallowWater = 123;
    public const int altSand = 127;
    public const int altGrass = 160;
    public const int altForest = 192;
    public const int altRock = 225;
    public const int altSnow = 255;

    public static readonly Dictionary<int, byte[]> COLOR_TABLE = new()
    {
      [cDeepWater] = new byte[] { 0, 0, 128 },
      [cShallowWater] = new byte[] { 25, 25, 150 },
      [cSand] = new byte[] { 240, 240, 64 },
      [cDesert] = new byte[] { 238, 218, 130 },
      [cGrass] = new byte[] { 50, 220, 20 },
      [cSavanna] = new byte[] { 177, 209, 110 },
      [cForest] = new byte[] { 16, 160, 0 },
      [cSeasonalForest] = new byte[] { 73, 100, 35 },
      [cBorealForest] = new byte[] { 95, 115, 62 },
      [cRainForest] = new byte[] { 29, 73, 40 },
      [cRock] = new byte[] { 128, 128, 128 },
      [cTundra] = new byte[] { 96, 131, 112 },
      [cSnow] = new byte[] { 255, 255, 255 }
    };

    public static readonly Dictionary<int, string> BIOME_NAME_TABLE = new()
    {
      [cDeepWater] = "Deep Water",
      [cShallowWater] = "Shallow Water",
      [cSand] = "Sand",
      [cDesert] = "Desert",
      [cGrass] = "Grass",
      [cSavanna] = "Savanna",
      [cForest] = "Forest",
      [cSeasonalForest] = "Seasonal Forest",
      [cBorealForest] = "Boreal Forest",
      [cRainForest] = "Rain Forest",
      [cRock] = "Rock",
      [cTundra] = "Tundra",
      [cSnow] = "Ice"
    };

  }
}


