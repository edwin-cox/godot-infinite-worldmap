@tool
extends Node

class_name ProceduralWorldAreaInfo

var biome:int
var heat:int
var moisture:int
var altitude:int
var color:Color

func _init(biome:int,heat:int,moisture:int,altitude:int,color:Array):
	self.biome=biome 
	self.heat=heat
	self.moisture=moisture
	self.altitude=altitude
	self.color=Color(color[0],color[1],color[2])
