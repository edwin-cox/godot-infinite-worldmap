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

    private BiomeConstants.BiomeType[] cachedMap;
    private byte[] cachedColorMap;
    private int _lastMiddleIndex = -1;
    private Dictionary<NoiseIndex, byte> _lastMiddleBufferValues;

    public static string GetBiomeName(int biome) => BiomeConstants.BIOME_NAME_TABLE[(BiomeConstants.BiomeType)biome];
    public byte GetCurrentBiome() => (byte)cachedMap[_lastMiddleIndex];
    public byte GetCurrentHeat() => _lastMiddleBufferValues[NoiseIndex.Heat];
    public byte GetCurrentMoisture() => _lastMiddleBufferValues[NoiseIndex.Moisture];
    public byte GetCurrentElevation() => (byte)CalcElevation(_lastMiddleBufferValues[NoiseIndex.TerrainElevation], _lastMiddleBufferValues[NoiseIndex.ContinentElevation], _lastMiddleBufferValues[NoiseIndex.LandmassElevation]);

    public ImageTexture GetBiomeImage(Vector2I cameraZoomedSize)
    {
      V2I size = new(cameraZoomedSize.X, cameraZoomedSize.Y);
      RegenerateMap(size);
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

    private byte[] GetNoiseImage(NoiseIndex noiseIdx, int w, int h) => _noises[(int)noiseIdx].GetImage(w, h, false, false, false).GetData();

    private Dictionary<NoiseIndex, byte[]> GenerateNoiseBuffers(V2I cameraZoomedSize)
    {
      return Enum.GetValues(typeof(NoiseIndex))
               .Cast<NoiseIndex>()
               .AsParallel()
               .ToDictionary(idx => idx, idx => GetNoiseImage(idx, cameraZoomedSize.X, cameraZoomedSize.Y));
    }

    private void RegenerateMap(V2I cameraZoomedSize)
    {
      Dictionary<NoiseIndex, byte[]> buffers = GenerateNoiseBuffers(cameraZoomedSize);

      _lastMiddleIndex = GetBufferMiddleIndex(cameraZoomedSize);
      _lastMiddleBufferValues = buffers.ToDictionary(e => e.Key, e => e.Value[_lastMiddleIndex]);

      GetBiomeBuffer(cameraZoomedSize, buffers);

    }

    private void GetBiomeBuffer(V2I cameraZoomedSize, Dictionary<NoiseIndex, byte[]> buffers)
    {
      BiomeConstants.BiomeType[] biomeBuffer = new BiomeConstants.BiomeType[cameraZoomedSize.X * cameraZoomedSize.Y];
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

    private static BiomeConstants.BiomeType CalculateSingleBiome(int i, Dictionary<NoiseIndex, byte[]> buffers)
    {
      byte continentHeight = buffers[NoiseIndex.ContinentElevation][i];
      byte terrainHeight = buffers[NoiseIndex.TerrainElevation][i];
      byte heat = buffers[NoiseIndex.Heat][i];
      byte moist = buffers[NoiseIndex.Moisture][i];
      byte landmassHeight = buffers[NoiseIndex.LandmassElevation][i];

      int elevation = CalcElevation(terrainHeight, continentHeight, landmassHeight);

      return (elevation) switch
      {
        < (int)BiomeConstants.Altitude.Sand => CalcOceanBiome(elevation, heat, moist),
        < (int)BiomeConstants.Altitude.Forest => CalcLandBiome(heat, moist),
        < (int)BiomeConstants.Altitude.Rock => BiomeConstants.BiomeType.Rock,
        _ => BiomeConstants.BiomeType.Snow,
      };
    }

    private static int CalcElevation(byte terrainHeight, byte continentHeight, byte landmassHeight)
    {
      int elevation = (int)((6 * 0.85 * continentHeight + 3 * 1.8 * landmassHeight + terrainHeight) / 10);
      if (elevation >= (int)BiomeConstants.Altitude.ShallowWater)
      {
        elevation = (3 * continentHeight + terrainHeight * terrainHeight / 140) / 4 - 5;
      }

      return elevation;
    }

    private static BiomeConstants.BiomeType CalcLandBiome(byte heat, byte moist)
    {
      return heat switch
      {
        < (int)BiomeConstants.Temperature.Coldest => BiomeConstants.BiomeType.Snow,
        < (int)BiomeConstants.Temperature.Colder => BiomeConstants.BiomeType.Tundra,
        < (int)BiomeConstants.Temperature.Cold => CalcBorealBiome(moist),
        < (int)BiomeConstants.Temperature.Warmer => CalcTemperateBiome(moist),
        _ => CalcTropicalBiome(moist)
      };
    }

    private static BiomeConstants.BiomeType CalcTropicalBiome(byte moist)
    {
      return moist switch
      {
        < (int)BiomeConstants.Humidity.Dryer => BiomeConstants.BiomeType.Desert,
        < (int)BiomeConstants.Humidity.Wet => BiomeConstants.BiomeType.Savanna,
        _ => BiomeConstants.BiomeType.RainForest
      };
    }

    private static BiomeConstants.BiomeType CalcTemperateBiome(byte moist)
    {
      return moist switch
      {
        < (int)BiomeConstants.Humidity.Dryer => BiomeConstants.BiomeType.Grass,
        < (int)BiomeConstants.Humidity.Wet => BiomeConstants.BiomeType.Forest,
        < (int)BiomeConstants.Humidity.Wetter => BiomeConstants.BiomeType.SeasonalForest,
        _ => BiomeConstants.BiomeType.RainForest
      };
    }

    private static BiomeConstants.BiomeType CalcBorealBiome(byte moist)
    {
      return moist switch
      {
        < (int)BiomeConstants.Humidity.Dryer => BiomeConstants.BiomeType.Grass,
        < (int)BiomeConstants.Humidity.Dry => BiomeConstants.BiomeType.Forest,
        _ => BiomeConstants.BiomeType.BorealForest
      };
    }

    private static BiomeConstants.BiomeType CalcOceanBiome(int elevation, byte heat, byte moist)
    {
      return elevation switch
      {
        < (int)BiomeConstants.Altitude.DeepWater => BiomeConstants.BiomeType.DeepWater,
        < (int)BiomeConstants.Altitude.ShallowWater => BiomeConstants.BiomeType.ShallowWater,
        _ => CalcShoreBiome(heat, moist)
      };
    }

    private static BiomeConstants.BiomeType CalcShoreBiome(byte heat, byte moist)
    {
      return heat switch
      {
        < (int)BiomeConstants.Temperature.Colder => BiomeConstants.BiomeType.Tundra,
        < (int)BiomeConstants.Temperature.Warmer => BiomeConstants.BiomeType.Grass,
        _ => moist switch
        {
          < (int)BiomeConstants.Humidity.Dryer => BiomeConstants.BiomeType.Desert,
          < (int)BiomeConstants.Humidity.Wet => BiomeConstants.BiomeType.Savanna,
          _ => BiomeConstants.BiomeType.Grass
        }
      };
    }
  }
}