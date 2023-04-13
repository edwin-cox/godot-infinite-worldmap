extends Control

var session:MapSession
var map_gen:MapGenerator
@onready var map:=$HBoxContainer/MapContainer
var current_task_id:int
var thread_cancel={}
var image_changed:bool=true

const FAST_RESOLUTION=3

# Called when the node enters the scene tree for the first time.
func _ready():
	session=SessionFactory.create_session()
	map_gen=MapGenerator.new()
	map_gen.session=session

	start_update(false)
	refresh_infobox()

func start_update(is_recursive:bool):
	if is_recursive:
		update_map_recursive(FAST_RESOLUTION-1)
	else:
		update_map_texture(FAST_RESOLUTION,{"task_id":0})

func update_map_texture(res_idx:int,params,is_incremental:bool=false):
	var tex:=map_gen.generate_image(false,res_idx)

	var task_id:int=params["task_id"]
	if thread_cancel.has(task_id):
		thread_cancel.erase(task_id)
		return
	else:
		var mat:ShaderMaterial=map.material
		mat.set_shader_parameter("BIOME_MAP",tex)

	if is_incremental and res_idx>0:
		call_deferred("update_map_recursive",res_idx-1)
	elif res_idx<=0:
		image_changed=false


func update_map_recursive(res_idx):
	var params={}
	current_task_id=WorkerThreadPool.add_task(update_map_texture.bind(res_idx,params,true),false,"map thread")
	params["task_id"]=current_task_id


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var map_changed=false
	var offset_change:=Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		offset_change.y=-1
	elif Input.is_action_pressed("ui_down"):
		offset_change.y=1
	if Input.is_action_pressed("ui_left"):
		offset_change.x=-1
	elif Input.is_action_pressed("ui_right"):
		offset_change.x=1
	if Input.is_action_pressed("zoom_out"):
		session.zoom*=0.9
		map_changed=true
	elif Input.is_action_pressed("zoom_in"):
		session.zoom*=1.1
		map_changed=true
	
	map_changed=map_changed or offset_change != Vector2.ZERO
	
	if map_changed:
		refresh_infobox()
		image_changed=true
		$fast_rendering_timer.stop()
		
		if current_task_id != 0:
			thread_cancel[current_task_id]=true
		session.world_offset += offset_change*10/session.zoom
		start_update(false)
	else:
		if image_changed and $fast_rendering_timer.is_stopped():
			image_changed=false
			$fast_rendering_timer.start()

func refresh_infobox():
	var infobox:ItemList=$HBoxContainer/Panel/infobox
	
	
	infobox.clear()
	
	infobox.add_item("Zoom: "+str(roundf(session.zoom*100)/100.0))
	infobox.add_item("World:")

	infobox.add_item("    X: "+str(roundf(session.world_offset.x)))
	infobox.add_item("   Y: "+str(roundf(session.world_offset.y)))
	infobox.add_item("   D: "+str(roundf(session.world_offset.length())))
	
	infobox.add_item("Screen:")
	var screen_offset=session.get_noise_offset(0)
	infobox.add_item("   X: "+str(roundf(screen_offset.x)))
	infobox.add_item("   Y: "+str(roundf(screen_offset.y)))
	infobox.add_item("   D: "+str(roundf(screen_offset.length())))
	
	var current_info:=session.current_area_info
	infobox.add_item("Current place:")
	infobox.add_item("   Biome: "+BiomeGenerator.BIOME_NAME_TABLE[current_info.biome])
	infobox.add_item("   Altitude: "+str(current_info.altitude))
	infobox.add_item("   Moisture: "+str(current_info.moisture))
	infobox.add_item("   Heat: "+str(current_info.heat))
