extends Control

enum DS {GDSCRIPT, CSHARP, CPP}

var datasources:Array[ProceduralWorldDatasource]
var time_results:=[-1.0,-1.0, -1.0]
var duration_results:=[-1.0,-1.0, -1.0]
var noise_time_result:=-1.0
var noise_duration_result:=-1.0
@onready var worldmap:ProceduralWorldMap=$HBoxContainer/WorldMap

var precision:int : 
	get:
		return %PrecisionEdit.value
	set(value):
		%PrecisionEdit.value=value
		
var iteration:int :
	get:
		return %IterationEdit.value

# Called when the node enters the scene tree for the first time.
func _ready():
	datasources=[]
	datasources.append(worldmap.SessionFactory.create_Fastnoiselite_datasource(0))
	datasources.append(worldmap.SessionFactory.create_Sharpnoiselite_datasource(0))
	datasources.append(worldmap.SessionFactory.create_cpp_datasource(0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _run_benchmark(datasource_index:int)->void:
	await _toggle_on_load(true)
	var datasource:=datasources[datasource_index]
	worldmap.set_datasource(datasource)
	worldmap.fast_resolution_index=precision
	var t0:=Time.get_ticks_msec()
	for i in range(iteration):
		worldmap.refresh()
	var t1=Time.get_ticks_msec()-t0
	time_results[datasource_index] = t1/iteration/1000.0
	duration_results[datasource_index] = t1/1000.0
	
	refresh_results_label()
	_toggle_on_load(false)


func refresh_results_label():
	var screen_size=worldmap.camera_size/pow(2,precision)
	
	var template="""
	Image:\t%dx%d
	Iterated %dx
	[b]Results[/b]
	Noises:\t\t%.3fs
	GDScript:\t%.3fs
	C#:\t\t\t\t%.3fs
	CPP:\t\t\t%.3fs
	-----------------------------
	[b]Total results[/b]
	Noises:\t\t%.3fs
	GDScript:\t%.3fs
	C#:\t\t\t\t%.3fs	
	CPP:\t\t\t%.3fs
	"""
	%ResultText.text=template % [screen_size.x,screen_size.y, iteration, noise_time_result, time_results[0],time_results[1],time_results[2], noise_duration_result , duration_results[0], duration_results[1], duration_results[2]]


func _on_run_gd_script_pressed():
	await _run_benchmark(DS.GDSCRIPT)


func _on_run_c_sharp_pressed():
	_run_benchmark(DS.CSHARP)


func _toggle_on_load(loading:bool):
	$Loading.visible=loading
	await get_tree().process_frame


func _on_run_all_pressed():
	simulate_noise_generation()
	for ds_idx in range(3):
		_run_benchmark(ds_idx)


func _on_button_pressed():
	_run_benchmark(DS.CPP)


func simulate_noise_generation():
	var resolution=$HBoxContainer/WorldMap.resolutions[precision]
	var w=$HBoxContainer/WorldMap.camera_size.x/resolution
	var h=$HBoxContainer/WorldMap.camera_size.y/resolution

	var worldmap=datasources[DS.CPP].datasource

	var total_duration=0
	for i in range(iteration):
		total_duration=total_duration+worldmap.get_noise_benchmark(w,h)
	
	noise_time_result = total_duration/iteration/1000.0
	noise_duration_result = total_duration/1000.0
	
	refresh_results_label()


func _on_run_noise_generator_pressed():
	simulate_noise_generation()
