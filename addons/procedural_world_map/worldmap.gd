@tool
extends ColorRect

class_name ProceduralWorldMap

# ProceduralWorldMap node for Godot game engine.
# Renders a world map using a procedural generation algorithm.
# The map is generated using a ProceduralWorldDatasource which can be set by the user.
# The generated map is displayed as a texture on a ColorRect node.
# Includes methods for refreshing the map and updating it incrementally using a progressive rendering technique.
# 
# Author: Edwin Cox
# Version: 0.0.1
# License: MIT

# ---- IMPORTS -------------------------
var SessionFactory=preload("session_factory.gd")
const MapSession=preload("map_session.gd")

# ---- VARIABLES -------------------------

# The current MapSession instance.
# This object represents the current state of the map and is used to generate and render the map.
var session:MapSession

# The ID of the current task being executed.
var current_task_id:int

# A dictionary of thread cancellation flags.
# This dictionary is used to mark which running rendering threads must not be displayed, since they were cancelled. 
# The key is the task ID and the value is a boolean indicating whether the thread was cancelled.
var thread_cancel={}

# A boolean value indicating whether the image requires updating. If a parameter of the map is changed, this value will be true until it reaches the highest resolution.
var image_changed:bool=true

# Parameter to tint in real time the rendered map. It is a color multiplication.
# Note: use tint instead of color from ColorRect during the game, because tint takes immediate effect and not color.
# Color can still be used as an initial tint set in the editor.
var tint:Color : set = set_tint, get = get_tint

# The Timer object used to start the incremental rendering process.
# This timer is used to start the incremental rendering process after an idle period. It is not used to schedule the multiple rendering passes.
@onready var incremental_timer:Timer=Timer.new()

# ---- EXPORTS -------------------------

# If true, the map will be rendered with incremental quality, meaning it will start with a low quality version and gradually improve until it reaches the desired quality level.
@export var incremental_quality:=false

# The coordinates of the center of the map.
@export var coordinates:=Vector2.ZERO : set = set_coords

# The size of the camera used to render the map. It will be the size of the resulting texture at the highest resolution. Ratio is kept with lower resolutions.
@export var camera_size:=Vector2i(1024,1024) : set = set_cam_size

# The zoom level of the map.
@export var zoom:=10.0 : set = set_zoom

# The available resolutions for the map. The map will be rendered at the highest resolution that fits within the camera size.
@export var resolutions:Array[int]=[1,2,4,8,16] : set = set_resolutions

# The index of the resolution to use when rendering the map with incremental quality. This resolution will be used for the first pass, and then progressively higher resolutions will be used until the desired quality level is reached.
# This value represents the index in the resolutions array for the initial rendering resolution. The incremental rendering will start from this index and progressively increase the resolution by decreasing the index until it reaches the highest resolution (index 0).
# Must be a positive or zero integer.
@export var fast_resolution_index:=3

# The level of detail to use when rendering the map. Higher values will result in more detailed maps, but may also be slower to render.
@export var detail:=1.0 : set = set_detail, get = get_detail

# The amount of time to wait before refreshing the map after a change in the settings.
@export var refresh_timeout:=0.5 : set = set_refresh_timeout

# The datasource used to generate the map. This can be set to any object that implements the ProceduralWorldDatasource interface.
@export var datasource:ProceduralWorldDatasource : set = set_datasource, get = get_datasource

# ----- SIGNAL ---------------------------------------

# called when the map is done rendering. It is called multiple times when rendering with incremental quality.
signal update

# ----- COMPUTED ---------------------------------------

# A boolean value indicating whether the incremental rendering timer is running.
# Returns true if the timer is running, false otherwise.
var timeout_running:bool : 
	get:
		return not incremental_timer.is_stopped()

# The relative zoom factor of the map.
# This value represents the factor of multiplication to use when calculating a distance relative to the current viewport. 
# Returns the inverse of the zoom level.
var relative_zoom_factor:float :
	get:
		return 1/zoom

# The current area information for the map.
# Returns the ProceduralWorldAreaInfo object for the current area.
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

func set_tint(value:Color):
	self.color=value
	material.set_shader_parameter("tint",self.color)

func get_tint()->Color:
	return self.color
# ---- METHODS -------------------------------------------------

func get_shader_material()->ShaderMaterial:
	var shader=Shader.new()
	shader.code="""
shader_type canvas_item;
uniform sampler2D DATA;
uniform vec4 tint;

void fragment() {
	COLOR = texture(DATA, UV) * tint; 
}
"""
	
	var material=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("tint",self.color)

	return material

func _init():
	session=SessionFactory.create_session()
	if not datasource:
		datasource=SessionFactory.create_Fastnoiselite_datasource(0)
	
	self.material=get_shader_material()

func _ready():
	incremental_timer.wait_time=refresh_timeout
	incremental_timer.one_shot=true
	incremental_timer.connect("timeout",_start_map_update.bind(true))
	add_child(incremental_timer)

	_start_map_update(false)

func _process(delta):
	# start the idling timeout when the map has been fast rendered
	if incremental_quality and image_changed and incremental_timer.is_stopped():
		image_changed=false
		incremental_timer.start()

# Internal entry point to refresh the map
func _start_map_update(is_recursive:bool):
	if is_recursive:
		_start_incremental_update_map_task(fast_resolution_index-1)
	else:
		image_changed=true
		_update_map_task(self.material,fast_resolution_index,{"task_id":0}) # because it's not rendered through a thread, the task has no id and cannot be cancelled.

# Main task to update the map. Can be called directly for immediate rendering, or through a thread pool for incremental rendering.
func _update_map_task(mat:ShaderMaterial,res_idx:int,params,is_incremental:bool=false):
	if not datasource:
		image_changed=false
		return
	
	var tex:=_generate_image(res_idx)

	# abort rendering if task was cancelled
	var task_id:int=params["task_id"]
	if thread_cancel.has(task_id):
		print("has thread_cancel")
		thread_cancel.erase(task_id)
		return
	else:
		mat.set_shader_parameter("DATA",tex)
	
	if is_incremental and res_idx>0:
		# schedule the next resolution to render
		call_deferred("_start_incremental_update_map_task",res_idx-1)
	elif res_idx<=0:
		# stop all incremental rendering when the highest resolution is reached
		image_changed=false
	emit_signal("update")

func _start_incremental_update_map_task(res_idx):
	var params={}
	current_task_id=WorkerThreadPool.add_task(_update_map_task.bind(self.material,res_idx,params,true),false,"map thread")
	# params was given by reference. Since the task has to know its own id but has no method to get it from itself,
	# the trick is to get the task id returned by the worker thread pool and provide it to the params object, which the task can also access.
	params["task_id"]=current_task_id

# method to get the image from the datasource. The zoom and located must first be provided to the datasource through the session, before actually 
# generating the image.
func _generate_image(resolution_idx:int)->ImageTexture:
	var camera_zoomed_size:Vector2=session.get_camera_zoomed_size(resolution_idx)
	session.update_noises(resolution_idx)
	return datasource.get_biome_image(camera_zoomed_size)
	
# Cancels all ongoing rendering tasks and starts a new fast rendering at the lowest resolution. 
# If the incremental rendering is enabled, it will be stopped.
# This method is useful when the user is moving the map and the map needs to be updated quickly.
func refresh():
	if not datasource:
		return
	
	image_changed=true
	if incremental_timer:
		incremental_timer.stop()
	
	if current_task_id != 0:
		thread_cancel[current_task_id]=true
	_start_map_update(false)
