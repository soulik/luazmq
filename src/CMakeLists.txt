set(luazmq_src
	main.cpp
)

set(luazmq_sources
	${luazmq_src}
)

include_directories(./)

set(luazmq_version_script luazmq.version)

IF(UNIX)
    IF(CMAKE_COMPILER_IS_GNUCC)
         SET(CMAKE_SHARED_LINKER_FLAGS  "${CMAKE_SHARED_LINKER_FLAGS} ${CMAKE_CXX_COMPILE_OPTIONS_VISIBILITY}hidden -Wl,--version-script=${LuaBox2D_version_script}")
    ENDIF(CMAKE_COMPILER_IS_GNUCC)

    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wmissing-declarations")
ENDIF(UNIX)

add_library(luazmq SHARED
	${luazmq_sources}
)

set_property(TARGET luazmq PROPERTY CXX_STANDARD 11)
set_property(TARGET luazmq PROPERTY CXX_STANDARD_REQUIRED ON)

set_target_properties(luazmq
    PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

configure_file(zmq.lua zmq.lua COPYONLY)

target_link_libraries (luazmq
	libzmq
	${LUA_LIBRARY}
)
