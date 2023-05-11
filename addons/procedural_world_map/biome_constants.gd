@tool
extends Node

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

const BIOME_NAME_TABLE={
	cDeepWater:"Deep Water",
	cShallowWater:"Shallow Water",
	cSand:"Sand",
	cDesert:"Desert",
	cGrass:"Grass",
	cSavanna:"Savanna",
	cForest:"Forest",
	cSeasonalForest:"Seasonal Forest",
	cBorealForest:"Boreal Forest",
	cRainForest:"Rain Forest",
	cRock:"Rock",
	cTundra:"Tundra",
	cSnow:"Ice"
}
