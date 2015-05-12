#ifdef _WIN32

extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
}

#else
#include <lua5.1/lua.hpp>
#endif
