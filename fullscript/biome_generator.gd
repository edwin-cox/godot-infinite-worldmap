extends Node

class_name BiomeGenerator

const COLDEST = 0.05;
const COLDER = 0.18;
const COLD = 0.4;
const WARM = 0.5;
const WARMER = 0.7;

const DRYEST = 0.27;
const DRYER = 0.4;
const DRY = 0.6;
const WET = 0.8;
const WETTER = 0.9;
const WETTEST = 1.0;

const cDeepWater=0.0;
const cShallowWater=0.1;
const cSand=0.2;
const cDesert=0.25;
const cGrass=0.3;
const cSavanna=0.35;
const cForest=0.4;
const cSeasonalForest=0.45;
const cBorealForest=0.5;
const cRainForest=0.55;
const cRock=0.6;
const cTundra=0.65;
const cSnow=0.7;


const altDeepWater=0.45;
const altShallowWater=0.48;
const altSand=0.5;
const altGrass=0.63;
const altForest=0.75;
const altRock=0.88;
const altSnow=1;

func get_biome(height:float,heat:float,moisture:float)->float:
	var result=height
	if(height<altSand):
		return getWaterBiotop(height,moisture,heat);
	elif(height<altForest):
		return getMainlandBiotop(moisture,heat);
	elif(height<altRock):
		return cRock;
	else:
		return cSnow;

func getColdBiotop(moisture:float)->float:
	if(moisture<DRYER):
		return cGrass
	elif moisture<DRY:
		return cForest;
	else:
		return cBorealForest;

func getWarmBiotop(moisture:float)->float:
	if(moisture<DRYER):
		return cGrass;
	elif(moisture<WET):
		return cForest;
	elif(moisture<WETTER):
		return cSeasonalForest;
	else:
		return cRainForest;

func getHotBiotop(moisture:float)->float:
	if(moisture<DRYER):
		return cDesert;
	elif(moisture<WET):
		return cSavanna;
	else:
		return cRainForest;

func getMainlandBiotop(moisture:float, heat:float)->float:
	if (heat<COLDEST):
		return cSnow;
	elif(heat<COLDER):
		return cTundra;
	elif(heat<COLD):
		return getColdBiotop(moisture);
	elif(heat<WARMER):
		return getWarmBiotop(moisture);
	else:
		return getHotBiotop(moisture);

func getBeachBiotop(moisture:float, heat:float)->float:
	if heat<COLDER:
		return cTundra
	elif heat<WARMER:
		return cGrass;
	else:
		if(moisture<DRYER):
			return cDesert;
		elif(moisture<WET):
			return cSavanna;
		else:
			return cGrass

func getWaterBiotop(height:float,moisture:float, heat:float)->float:
	if(height<altDeepWater):
		return cDeepWater;
	elif(height<altShallowWater):
		return cShallowWater;
	else:
		return getBeachBiotop(moisture,heat);
