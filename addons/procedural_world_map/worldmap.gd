@tool
extends ColorRect

class_name ProceduralWorldMap

var SessionFactory=preload("session_factory.gd")
const MapSession=preload("map_session.gd")

var session:MapSession
var current_task_id:int
var thread_cancel={}
var image_changed:bool=true

@onready var incremental_timer:Timer=Timer.new()

# ---- EXPORTS -------------------------
@export var incremental_quality:=false
@export var coordinates:=Vector2.ZERO : set = set_coords
@export var camera_size:=Vector2i(1024,1024) : set = set_cam_size
@export var zoom:=10.0 : set = set_zoom
@export var resolutions:Array[int]=[1,2,4,8,16] : set = set_resolutions
@export var fast_resolution_index:=3
@export var detail:=1.0 : set = set_detail, get = get_detail
@export var refresh_timeout:=0.5 : set = set_refresh_timeout

@export var datasource:ProceduralWorldDatasource : set = set_datasource, get = get_datasource

# ----- SIGNAL ---------------------------------------
signal update

# ----- COMPUTED ---------------------------------------

var timeout_running:bool : 
	get:
		return not incremental_timer.is_stopped()

var relative_zoom_factor:float :
	get:
		return 1/zoom

var current_area_info:ProceduralWorldAreaInfo :
	get:
		return session.current_area_info

# ----- GETTERS & SETTERS -------------------------------
func set_zoom(value:float):
	zoom = clamp(value, 0.01, 1000)
	session.zoom=zoom
	refresh()

func set_coords(value:Vector2):
	coordinates=value
	session.world_offset=value
	refresh()

func set_cam_size(value:Vector2i):
	camera_size=value
	session.camera_size=value
	refresh()

func set_refresh_timeout(value:float):
	refresh_timeout=value
	incremental_timer.wait_time=refresh_timeout

func set_resolutions(value:Array):
	resolutions=value
	session.resolutions=value
	fast_resolution_index=clamp(fast_resolution_index,0,value.size()-1)
	refresh()

func set_detail(value:float):
	pass

func get_detail():
	return 1.0

func set_datasource(ds:ProceduralWorldDatasource):
	session.datasource=ds
	refresh()

func get_datasource()->ProceduralWorldDatasource:
	return session.datasource

# ---- METHODS -------------------------------------------------

func _init():
	session=SessionFactory.create_session()
	if not datasource:
		datasource=SessionFactory.create_Fastnoiselite_datasource(0)
#	session.datasource=datasource
	
	var shader=Shader.new()
	shader.code="""
shader_type canvas_item;
uniform sampler2D DATA;

void fragment() {
	COLOR = texture(DATA, UV); 
}
"""
	
	var material=ShaderMaterial.new()
	material.shader=shader
	
	self.material=material

# Called when the node enters the scene tree for the first time.
func _ready():
	incremental_timer.wait_time=refresh_timeout
	incremental_timer.one_shot=true
	incremental_timer.connect("timeout",start_update.bind(true))
	add_child(incremental_timer)

	start_update(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if incremental_quality and image_changed and incremental_timer.is_stopped():
		image_changed=false
		incremental_timer.start()

func start_update(is_recursive:bool):
	if is_recursive:
		update_map_recursive(fast_resolution_index-1)
	else:
		update_map_texture(fast_resolution_index,{"task_id":0})

func update_map_texture(res_idx:int,params,is_incremental:bool=false):
	# cancel the whole rendering is no datasource is initialized
	if not datasource:
		image_changed=false
		return
	
	var tex:=generate_image(datasource,res_idx)
	
	var task_id:int=params["task_id"]
	if thread_cancel.has(task_id):
		thread_cancel.erase(task_id)
		return
	else:
		var mat:ShaderMaterial=self.material
		mat.set_shader_parameter("DATA",tex)
	
	if is_incremental and res_idx>0:
		call_deferred("update_map_recursive",res_idx-1)
	elif res_idx<=0:
		image_changed=false
	
	emit_signal("update")

func update_map_recursive(res_idx):
	var params={}
	current_task_id=WorkerThreadPool.add_task(update_map_texture.bind(res_idx,params,true),false,"map thread")
	params["task_id"]=current_task_id

func refresh():
	if not datasource:
		return
	
	image_changed=true
	if incremental_timer:
		incremental_timer.stop()
	
	if current_task_id != 0:
		thread_cancel[current_task_id]=true
	start_update(false)


func start_delayed_refresh():
	if not datasource or not incremental_timer or not incremental_quality:
		return
	
	if incremental_timer.is_stopped():
		image_changed=false
		incremental_timer.start()


func create_texture_from_buffer(buffer: PackedByteArray, width: int, height: int) -> ImageTexture:
	# Create an image from the buffer with the given size
	var image := Image.create_from_data(width, height, false, Image.FORMAT_RGB8, buffer)
	
	# Create an ImageTexture from the image
	var texture := ImageTexture.create_from_image(image)
	
	# Return the texture
	return texture


func generate_image(datasource:ProceduralWorldDatasource,resolution_idx:int)->ImageTexture:
	var camera_zoomed_size:Vector2=session.get_camera_zoomed_size(resolution_idx)
	session.update_noises(resolution_idx)
	var buffer:PackedByteArray=datasource.get_biome_image(camera_zoomed_size)
	return create_texture_from_buffer(buffer,camera_zoomed_size.x, camera_zoomed_size.y)
