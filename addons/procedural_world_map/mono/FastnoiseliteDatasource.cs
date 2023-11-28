using Godot;
using System;
using System.Threading.Tasks;
using System.Linq;
using System.Collections.Generic;

namespace ProceduralWorldMap
{
  [Tool]
  public partial class FastnoiseliteDatasource : Node
  {
    private sealed record V2I(int X, int Y);

    public enum NoiseIndex
    {
      ContinentElevation,
      TerrainElevation,
      Heat,
      Moisture,
      LandmassElevation
    }
    private FastNoiseLite[] _noises = new FastNoiseLite[5];

    private byte[] cachedMap;
    private byte[] cachedColorMap;
    private int _lastMiddleIndex = -1;
    private Dictionary<NoiseIndex, byte> _lastMiddleBufferValues;

    public static string GetBiomeName(int biome) => BiomeConstants.BIOME_NAME_TABLE[biome];
    public byte GetCurrentBiome() => cachedMap[_lastMiddleIndex];
    public byte GetCurrentHeat() => _lastMiddleBufferValues[NoiseIndex.Heat];
    public byte GetCurrentMoisture() => _lastMiddleBufferValues[NoiseIndex.Moisture];
    public byte GetCurrentElevation() => (byte)CalcElevation(_lastMiddleBufferValues[NoiseIndex.TerrainElevation], _lastMiddleBufferValues[NoiseIndex.ContinentElevation], _lastMiddleBufferValues[NoiseIndex.LandmassElevation]);

    public ImageTexture GetBiomeImage(Vector2I cameraZoomedSize)
    {
      V2I size = new(cameraZoomedSize.X, cameraZoomedSize.Y);
      RegenerateMapAsync(size);
      return CreateTextureFromBuffer(cachedColorMap, size);
    }

    public void SetNoise(int noiseIdx, FastNoiseLite noise)
    {
      _noises[noiseIdx] = noise;
    }

    private static ImageTexture CreateTextureFromBuffer(byte[] buffer, V2I size)
    {
      var image = Image.CreateFromData(size.X, size.Y, false, Image.Format.Rgb8, buffer);
      return ImageTexture.CreateFromImage(image);
    }

    private byte[] GetNoiseImage(int noiseIdx, int w, int h) => _noises[noiseIdx].GetImage(w, h, false, false, false).GetData();

    private Dictionary<NoiseIndex, byte[]> GenerateNoiseBuffers(V2I cameraZoomedSize)
    {
      return Enum.GetValues(typeof(NoiseIndex))
               .Cast<NoiseIndex>()
               .AsParallel()
               .ToDictionary(idx => idx, idx => GetNoiseImage((int)idx, cameraZoomedSize.X, cameraZoomedSize.Y));
    }

    private void RegenerateMapAsync(V2I cameraZoomedSize)
    {
      Dictionary<NoiseIndex, byte[]> buffers = GenerateNoiseBuffers(cameraZoomedSize);

      _lastMiddleIndex = GetBufferMiddleIndex(cameraZoomedSize);
      _lastMiddleBufferValues = buffers.ToDictionary(e => e.Key, e => e.Value[_lastMiddleIndex]);

      GetBiomeBuffer(cameraZoomedSize, buffers);

    }

    private void GetBiomeBuffer(V2I cameraZoomedSize, Dictionary<NoiseIndex, byte[]> buffers)
    {
      byte[] biomeBuffer = new byte[cameraZoomedSize.X * cameraZoomedSize.Y];
      byte[] colorBuffer = new byte[cameraZoomedSize.X * cameraZoomedSize.Y * 3];

      var activeColorMap = BiomeConstants.COLOR_TABLE;

      void fillBuffers(int i)
      {
        biomeBuffer[i] = CalculateSingleBiome(i, buffers);
        byte[] biomeColor = activeColorMap[biomeBuffer[i]];
        colorBuffer[i * 3] = biomeColor[0];
        colorBuffer[i * 3 + 1] = biomeColor[1];
        colorBuffer[i * 3 + 2] = biomeColor[2];
      }

      int bufferSize = buffers[NoiseIndex.TerrainElevation].Length;
      Parallel.For(0, bufferSize, fillBuffers);

      cachedMap = biomeBuffer;
      cachedColorMap = colorBuffer;

    }

    private static int GetBufferMiddleIndex(V2I cameraZoomedSize) => (int)(cameraZoomedSize.Y / 2.0 * cameraZoomedSize.X + cameraZoomedSize.X / 2.0);

    private static byte CalculateSingleBiome(int i, Dictionary<NoiseIndex, byte[]> buffers)
    {
      byte continentHeight = buffers[NoiseIndex.ContinentElevation][i];
      byte terrainHeight = buffers[NoiseIndex.TerrainElevation][i];
      byte heat = buffers[NoiseIndex.Heat][i];
      byte moist = buffers[NoiseIndex.Moisture][i];
      byte landmassHeight = buffers[NoiseIndex.LandmassElevation][i];

      int elevation = CalcElevation(terrainHeight, continentHeight, landmassHeight);

      return (elevation) switch
      {
        < BiomeConstants.altSand => CalcOceanBiome(elevation, heat, moist),
        < BiomeConstants.altForest => CalcLandBiome(heat, moist),
        < BiomeConstants.altRock => BiomeConstants.cRock,
        _ => BiomeConstants.cSnow,
      };
    }

    private static int CalcElevation(byte terrainHeight, byte continentHeight, byte landmassHeight)
    {
      int elevation = (int)((6 * 0.85 * continentHeight + 3 * 1.8 * landmassHeight + terrainHeight) / 10);
      if (elevation >= BiomeConstants.altShallowWater)
      {
        elevation = (3 * continentHeight + terrainHeight * terrainHeight / 140) / 4 - 5;
      }

      return elevation;
    }

    private static byte CalcLandBiome(byte heat, byte moist)
    {
      return heat switch
      {
        < BiomeConstants.COLDEST => BiomeConstants.cSnow,
        < BiomeConstants.COLDER => BiomeConstants.cTundra,
        < BiomeConstants.COLD => CalcBorealBiome(moist),
        < BiomeConstants.WARMER => CalcTemperateBiome(moist),
        _ => CalcTropicalBiome(moist)
      };
    }

    private static byte CalcTropicalBiome(byte moist)
    {
      return moist switch
      {
        < BiomeConstants.DRYER => BiomeConstants.cDesert,
        < BiomeConstants.WET => BiomeConstants.cSavanna,
        _ => BiomeConstants.cRainForest
      };
    }

    private static byte CalcTemperateBiome(byte moist)
    {
      return moist switch
      {
        < BiomeConstants.DRYER => BiomeConstants.cGrass,
        < BiomeConstants.WET => BiomeConstants.cForest,
        < BiomeConstants.WETTER => BiomeConstants.cSeasonalForest,
        _ => BiomeConstants.cRainForest
      };
    }

    private static byte CalcBorealBiome(byte moist)
    {
      return moist switch
      {
        < BiomeConstants.DRYER => BiomeConstants.cGrass,
        < BiomeConstants.DRY => BiomeConstants.cForest,
        _ => BiomeConstants.cBorealForest
      };
    }

    private static byte CalcOceanBiome(int elevation, byte heat, byte moist)
    {
      return elevation switch
      {
        < BiomeConstants.altDeepWater => BiomeConstants.cDeepWater,
        < BiomeConstants.altShallowWater => BiomeConstants.cShallowWater,
        _ => CalcShoreBiome(heat, moist)
      };
    }

    private static byte CalcShoreBiome(byte heat, byte moist)
    {
      return heat switch
      {
        < BiomeConstants.COLDER => BiomeConstants.cTundra,
        < BiomeConstants.WARMER => BiomeConstants.cGrass,
        _ => moist switch
        {
          < BiomeConstants.DRYER => BiomeConstants.cDesert,
          < BiomeConstants.WET => BiomeConstants.cSavanna,
          _ => BiomeConstants.cGrass
        }
      };
    }
  }
}