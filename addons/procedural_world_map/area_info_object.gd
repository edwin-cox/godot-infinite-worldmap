@tool
extends Node

class_name ProceduralWorldAreaInfo

const BConsts=preload("biome_constants.gd")

var biome:int
var heat:int
var moisture:int
var altitude:int
var color:Color

var biome_name:String :
	get:
		return BConsts.BIOME_NAME_TABLE[biome]

func _init(biome:int,heat:int,moisture:int,altitude:int,color:Array):
	self.biome=biome 
	self.heat=heat
	self.moisture=moisture
	self.altitude=altitude
	self.color=Color(color[0],color[1],color[2])
