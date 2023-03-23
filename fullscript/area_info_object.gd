extends Node

class_name AreaInfoObject

var biome:float
var heat:float
var moisture:float
var altitude:float
var color:Color

func _init(biome:float,heat:float,moisture:float,altitude:float,color:Array):
	self.biome=biome 
	self.heat=heat
	self.moisture=moisture
	self.altitude=altitude
	self.color=Color(color[0],color[1],color[2])
