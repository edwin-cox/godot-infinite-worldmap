extends Control

var session:MapSession
var map_gen:MapGenerator
@onready var map:=$HBoxContainer/MapContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	session=SessionFactory.create_session()
	map_gen=MapGenerator.new()
	map_gen.session=session
	map_gen.biome_gen=BiomeGenerator.new()
	
	update_map()

func hello(text:Array):
	print(text[0])

func update_map():
	var tex:=map_gen.generate_image(false)
	
	
	var mat:ShaderMaterial=map.material
	mat.set_shader_parameter("BIOME_MAP",tex)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
