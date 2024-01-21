#include "register_types.h"

#include "worldmap.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_cpp_worldmap_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
  		return;
  	}

  	ClassDB::register_class<Worldmap>();
}

void uninitialize_cpp_worldmap_module(ModuleInitializationLevel p_level) {
  	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
  		return;
  	}
}

extern "C" {
    // Initialization.
	GDExtensionBool GDE_EXPORT cpp_worldmap_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
		GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

    init_obj.register_initializer(initialize_cpp_worldmap_module);
	  init_obj.register_terminator(uninitialize_cpp_worldmap_module);

		init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

		return init_obj.init();
	}
}