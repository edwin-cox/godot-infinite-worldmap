using Godot;
using System;
using System.Threading.Tasks;
using System.Linq;

namespace ProceduralWorldMap
{
  [Tool]
  public partial class FastnoiseliteDatasource : Node
  {
    private sealed record V2I(int X, int Y);

    const int _noiseIdxContinentElevation = 0;
    const int _noiseIdxTerrainElevation = 1;
    const int _noiseIdxHeat = 2;
    const int _noiseIdxMoisture = 3;
    const int _noiseIdxLandmassElevation = 4;

    private FastNoiseLite[] _noises = new FastNoiseLite[5];

    private byte[] cachedMap;
    private byte[] cachedColorMap;
    private int _lastMiddleIndex = -1;
    private byte[] _lastMiddleBufferValues;

    public static string GetBiomeName(int biome) => BiomeConstants.BIOME_NAME_TABLE[biome];
    public byte GetCurrentBiome() => cachedMap[_lastMiddleIndex];
    public byte GetCurrentHeat() => _lastMiddleBufferValues[_noiseIdxHeat];
    public byte GetCurrentMoisture() => _lastMiddleBufferValues[_noiseIdxMoisture];
    public byte GetCurrentElevation() => (byte)(CalcElevation(_lastMiddleBufferValues[_noiseIdxTerrainElevation], _lastMiddleBufferValues[_noiseIdxContinentElevation], _lastMiddleBufferValues[_noiseIdxLandmassElevation]));

    public ImageTexture GetBiomeImage(Vector2I cameraZoomedSize)
    {
      V2I size = new(cameraZoomedSize.X, cameraZoomedSize.Y);
      Task.Run(() => RegenerateMapAsync(size)).Wait();
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

    private async Task RegenerateMapAsync(V2I cameraZoomedSize)
    {
      var tasks = Enumerable.Range(0, 5).Select(idx => Task.Run(() => GetNoiseImage(idx, cameraZoomedSize.X, cameraZoomedSize.Y)));
      var buffers = await Task.WhenAll(tasks);

      byte[] continentElevationBuffer = buffers[_noiseIdxContinentElevation];
      byte[] terrainElevationBuffer = buffers[_noiseIdxTerrainElevation];
      byte[] heatBuffer = buffers[_noiseIdxHeat];
      byte[] moistureBuffer = buffers[_noiseIdxMoisture];
      byte[] landmassElevationBuffer = buffers[_noiseIdxLandmassElevation];

      _lastMiddleIndex = GetBufferMiddleIndex(cameraZoomedSize);
      _lastMiddleBufferValues = new byte[] { terrainElevationBuffer[_lastMiddleIndex], continentElevationBuffer[_lastMiddleIndex], heatBuffer[_lastMiddleIndex], moistureBuffer[_lastMiddleIndex], landmassElevationBuffer[_lastMiddleIndex] };

      GetBiomeBuffer(cameraZoomedSize, terrainElevationBuffer, continentElevationBuffer, heatBuffer, moistureBuffer, landmassElevationBuffer);
    }

    private void GetBiomeBuffer(V2I cameraZoomedSize, byte[] terrainElevationBuffer, byte[] continentElevationBuffer, byte[] heatBuffer, byte[] moistureBuffer, byte[] landmassBuffer)
    {
      byte[] buffer = new byte[cameraZoomedSize.X * cameraZoomedSize.Y];
      byte[] colorBuffer = new byte[cameraZoomedSize.X * cameraZoomedSize.Y * 3];

      var activeColorMap = BiomeConstants.COLOR_TABLE;

      void fillBuffers(int i, byte biome)
      {
        buffer[i] = biome;
        byte[] biomeColor = activeColorMap[biome];
        colorBuffer[i * 3] = biomeColor[0];
        colorBuffer[i * 3 + 1] = biomeColor[1];
        colorBuffer[i * 3 + 2] = biomeColor[2];
      }

      Parallel.For(0, terrainElevationBuffer.Length, i => fillBuffers(i, CalculateSingleBiome(terrainElevationBuffer[i], continentElevationBuffer[i], landmassBuffer[i], heatBuffer[i], moistureBuffer[i])));

      cachedMap = buffer;
      cachedColorMap = colorBuffer;

    }

    private static int GetBufferMiddleIndex(V2I cameraZoomedSize) => (int)(cameraZoomedSize.Y / 2.0 * cameraZoomedSize.X + cameraZoomedSize.X / 2.0);

    private static byte CalculateSingleBiome(byte terrainHeight, byte continentHeight, byte landmassHeight, byte heat, byte moist)
    {
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