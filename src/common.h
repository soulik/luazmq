#include <zmq.h>
#include <zmq_utils.h>

#include <Lua/lua.hpp>

#include <lutok2/lutok2.hpp>
using namespace lutok2;

#if (BUILDING_LIBLUAZMQ || luazmq_EXPORTS) && HAVE_VISIBILITY
#define LIBLUAZMQ_DLL_EXPORTED __attribute__((visibility("default")))
#elif (BUILDING_LIBLUAZMQ || luazmq_EXPORTS) && defined _MSC_VER
#define LIBLUAZMQ_DLL_EXPORTED __declspec(dllexport)
#elif defined _MSC_VER
#define LIBLUAZMQ_DLL_EXPORTED __declspec(dllimport)
#else
#define LIBLUAZMQ_DLL_EXPORTED
#endif
