@tool
extends Node

class_name ProceduralWorldAreaInfo

# This script defines the ProceduralWorldAreaInfo class, which is used to store information about a specific area on the world map.
# The class provides fields to store the biome, heat, moisture, altitude, and color of the area.
# The _init() method is used to initialize the fields with the given values.

# The biome value of the area.
var biome:int

# The heat value of the area.
var heat:int

# The moisture value of the area.
var moisture:int

# The altitude value of the area.
var altitude:int

# The color of the area.
var color:Color

# Initializes the fields with the given values.
func _init(biome:int,heat:int,moisture:int,altitude:int,color:Array):
	self.biome=biome 
	self.heat=heat
	self.moisture=moisture
	self.altitude=altitude
	self.color=Color(color[0],color[1],color[2])
