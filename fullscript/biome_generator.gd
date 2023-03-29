extends Node

class_name BiomeGenerator

const COLDEST = 12;
const COLDER = 46;
const COLD = 102;
const WARM = 127;
const WARMER = 178;

const DRYEST = 69;
const DRYER = 102;
const DRY = 153;
const WET = 204;
const WETTER = 230;
const WETTEST = 255;

const cDeepWater=0;
const cShallowWater=1;
const cSand=2;
const cDesert=3;
const cGrass=4;
const cSavanna=5;
const cForest=6;
const cSeasonalForest=7;
const cBorealForest=8;
const cRainForest=9;
const cRock=10;
const cTundra=11;
const cSnow=12;


const altDeepWater=115;
const altShallowWater=123;
const altSand=127;
const altGrass=160;
const altForest=192;
const altRock=225;
const altSnow=255;

const COLOR_TABLE={
	cDeepWater:[0,0,128],
	cShallowWater:[25,25,150],
	cSand:[240,240,64],
	cDesert:[238,218,130],
	cGrass:[50,220,20],
	cSavanna:[177,209,110],
	cForest:[16,160, 0],
	cSeasonalForest:[73,100, 35],
	cBorealForest:[95,115, 62],
	cRainForest:[29,73, 40],
	cRock:[128,128,128],
	cTundra:[96,131,112],
	cSnow:[255,255,255]
}

static func get_biome_buffer1(height_buffer:PackedByteArray,main_height_buffer:PackedByteArray,heat_buffer:PackedByteArray,moisture_buffer:PackedByteArray)->PackedByteArray:
	var buffer:=PackedByteArray()
	for i in range(height_buffer.size()):
		var main_height := main_height_buffer[i]
		var height := height_buffer[i]
		var elevation:int=( min(height*height+height,255) + 2 * main_height*main_height ) / 3
	#
		var heat:=heat_buffer[i]
		var moisture:=moisture_buffer[i]
		
		var biome_idx=get_biome(height,heat,moisture)
		
		if COLOR_TABLE.has(biome_idx):
			buffer.append_array(COLOR_TABLE[biome_idx])
		else:
			buffer.append_array(COLOR_TABLE[cSnow])
	
	return buffer

static func get_biome(height:int,heat:int,moisture:int):
	if(height<altSand):
		return getWaterBiotop(height,moisture,heat);
	elif(height<altForest):
		return getMainlandBiotop(moisture,heat);
	elif(height<altRock):
		return cRock;
	else:
		return cSnow;

static func getColdBiotop(moisture:int)->int:
	if(moisture<DRYER):
		return cGrass
	elif moisture<DRY:
		return cForest;
	else:
		return cBorealForest;

static func getWarmBiotop(moisture:int)->int:
	if(moisture<DRYER):
		return cGrass;
	elif(moisture<WET):
		return cForest;
	elif(moisture<WETTER):
		return cSeasonalForest;
	else:
		return cRainForest;

static func getHotBiotop(moisture:int)->int:
	if(moisture<DRYER):
		return cDesert;
	elif(moisture<WET):
		return cSavanna;
	else:
		return cRainForest;

static func getMainlandBiotop(moisture:int, heat:int)->int:
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

static func getBeachBiotop(moisture:int, heat:int)->int:
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

static func getWaterBiotop(height:int,moisture:int, heat:int)->int:
	if(height<altDeepWater):
		return cDeepWater;
	elif(height<altShallowWater):
		return cShallowWater;
	else:
		return getBeachBiotop(moisture,heat);



static func get_biome_buffer(height_buffer:PackedByteArray,main_height_buffer:PackedByteArray,heat_buffer:PackedByteArray,moisture_buffer:PackedByteArray)->PackedByteArray:
	var buffer:=PackedByteArray()
	for i in range(height_buffer.size()):
		var main_height := main_height_buffer[i]
		var height := height_buffer[i]
		var elevation:int=( min(height*height+height,255) + 2 * main_height*main_height ) / 3
	#
		var heat:=heat_buffer[i]
		var moisture:=moisture_buffer[i]
		
		
		
		var biome_idx
		if(height<altSand):
			if(height<altDeepWater):
				biome_idx= cDeepWater;
			elif(height<altShallowWater):
				biome_idx= cShallowWater;
			else:
				if heat<COLDER:
					biome_idx= cTundra
				elif heat<WARMER:
					biome_idx= cGrass;
				else:
					if(moisture<DRYER):
						biome_idx= cDesert;
					elif(moisture<WET):
						biome_idx= cSavanna;
					else:
						biome_idx= cGrass
		elif(height<altForest):
			if (heat<COLDEST):
				biome_idx= cSnow;
			elif(heat<COLDER):
				biome_idx= cTundra;
			elif(heat<COLD):
				if(moisture<DRYER):
					biome_idx= cGrass
				elif moisture<DRY:
					biome_idx= cForest;
				else:
					biome_idx= cBorealForest;
			elif(heat<WARMER):
				if(moisture<DRYER):
					biome_idx= cGrass;
				elif(moisture<WET):
					biome_idx= cForest;
				elif(moisture<WETTER):
					biome_idx= cSeasonalForest;
				else:
					biome_idx= cRainForest;
			else:
				if(moisture<DRYER):
					biome_idx= cDesert;
				elif(moisture<WET):
					biome_idx= cSavanna;
				else:
					biome_idx= cRainForest;
			
		elif(height<altRock):
			biome_idx= cRock;
		else:
			biome_idx= cSnow;
		
		
		
		if COLOR_TABLE.has(biome_idx):
			buffer.append_array(COLOR_TABLE[biome_idx])
		else:
			buffer.append_array(COLOR_TABLE[cSnow])
	
	return buffer
