file(GLOB_RECURSE luazmq_src
	"*.cpp"
	"*.h"
)

set(luazmq_sources
	${luazmq_src}
)

include_directories(./)

set(luazmq_version_script luazmq.version)

IF(UNIX)
    IF(CMAKE_COMPILER_IS_GNUCC)
         SET(CMAKE_SHARED_LINKER_FLAGS  "${CMAKE_SHARED_LINKER_FLAGS} ${CMAKE_CXX_COMPILE_OPTIONS_VISIBILITY}hidden -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/${luazmq_version_script}")
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
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_SYSTEM_PROCESSOR}/lib"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_SYSTEM_PROCESSOR}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_SYSTEM_PROCESSOR}/bin"
)

configure_file(zmq.lua ${CMAKE_BINARY_DIR}/${CMAKE_SYSTEM_PROCESSOR}/lib/zmq.lua COPYONLY)

target_link_libraries (luazmq
	libzmq
	${LUA_LIBRARY}
)

install(
    TARGETS luazmq
    DESTINATION ${luazmq_SOURCE_DIR}/bin   
)

install(
    FILES zmq.lua
    DESTINATION ${luazmq_SOURCE_DIR}/bin   
)