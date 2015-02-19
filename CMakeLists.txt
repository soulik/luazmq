cmake_minimum_required (VERSION 2.6)
project (luazmq)

# Include Lua 5.1

include(FindLua51)
include_directories(SYSTEM ${LUA_INCLUDE_DIR})
include_directories(dependencies/lua/include)

add_subdirectory(dependencies/)
# include_directories(dependencies/Box2D/Box2D)

include_directories(dependencies/lutok2/include)

add_subdirectory(src)

set_target_properties(luazmq PROPERTIES PREFIX "")
