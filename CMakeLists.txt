cmake_minimum_required (VERSION 3.1.0)
project (luazmq)

# Include libzmq

set(ZMQ_BUILD_TESTS OFF CACHE BOOL "Build the tests for ZeroMQ")
add_subdirectory(dependencies/libzmq)
include_directories(dependencies/libzmq/include)

set_target_properties(libzmq
    PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

# Include Lua 5.1

include(FindLua51)
include_directories(SYSTEM ${LUA_INCLUDE_DIR})
include_directories(dependencies/lua/include)

include_directories(dependencies/lutok2/include)

add_subdirectory(src)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY build)
set_target_properties(luazmq PROPERTIES PREFIX "")
