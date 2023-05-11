@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("ProceduralWorldMap", "ColorRectso", preload("worldmap.gd"),null)

func _exit_tree():
	remove_custom_type("ProceduralWorldMap")
