#!/usr/bin/env python
import os
import sys

env = SConscript("godot-cpp/SConstruct")

# For reference:
# - CCFLAGS are compilation flags shared between C and C++
# - CFLAGS are for C-specific compilation flags
# - CXXFLAGS are for C++-specific compilation flags
# - CPPFLAGS are for pre-processor flags
# - CPPDEFINES are for pre-processor defines
# - LINKFLAGS are for linking flags

# tweak this if you want to use different folders, or more folders, to store your source code in.
src_path="addons/procedural_world_map/cpp/src/"
bin_path="addons/procedural_world_map/cpp/bin/"
extension_name="cpp_datasource"
env.Append(CPPPATH=[src_path])
sources = Glob(src_path+"*.cpp")

if env["platform"] == "macos":
    library = env.SharedLibrary(
        "{}{}.{}.{}.framework/{}.{}.{}".format(
            bin_path, extension_name, env["platform"], env["target"], extension_name, env["platform"], env["target"]
        ),
        source=sources,
    )
else:
    library = env.SharedLibrary(
        "{}{}{}{}".format(bin_path,extension_name, env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
    )

Default(library)
