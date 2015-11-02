cmake_minimum_required (VERSION 3.1.0)
project (luazmq)

list(APPEND CMAKE_MODULE_PATH "${luazmq_SOURCE_DIR}/cmake")

set(LUAZMQ_USE_LIBSODIUM ON CACHE BOOL "Build and use internal copy of libsodium")

if (LUAZMQ_USE_LIBSODIUM)

	# Include libsodium

	add_subdirectory(dependencies/libsodium)
	include_directories(dependencies/libsodium/src/libsodium/include)
	include_directories(dependencies/libsodium/src/libsodium/include/sodium)
	include_directories("${CMAKE_BINARY_DIR}/dependencies/libsodium/src/libsodium/include")
	add_definitions(-DSODIUM_DLL_EXPORT)

	set_target_properties(libsodium
	    PROPERTIES
	    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_SYSTEM_PROCESSOR}/lib"
	    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_SYSTEM_PROCESSOR}/lib"
	    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_SYSTEM_PROCESSOR}/bin"
	)
	
	set(SODIUM_FOUND 1)
	set(SODIUM_LIBRARY $<TARGET_LINKER_FILE:libsodium>)
	set(SODIUM_LIBRARIES $<TARGET_LINKER_FILE:libsodium>)
endif()

# Include libzmq

set(ZMQ_BUILD_TESTS OFF CACHE BOOL "Build the tests for ZeroMQ")
add_subdirectory(dependencies/libzmq)
include_directories(dependencies/libzmq/include)

set_target_properties(libzmq
    PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_SYSTEM_PROCESSOR}/lib"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_SYSTEM_PROCESSOR}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_SYSTEM_PROCESSOR}/bin"
)

if (LUAZMQ_USE_LIBSODIUM)
	add_dependencies(libzmq libsodium)
	target_compile_definitions(libzmq PRIVATE -DHAVE_LIBSODIUM)
endif()

# Include Lua 5.1

include(FindLua51)
include_directories(SYSTEM
	${LUA_INCLUDE_DIR}
	${LUA_INCLUDE_DIR}/lua5.1
)

include_directories(dependencies/lutok2/include)

add_subdirectory(src)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY build)
set_target_properties(luazmq PROPERTIES PREFIX "")
